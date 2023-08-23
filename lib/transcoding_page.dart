import 'dart:io';

import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/log.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/statistics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import 'tool/args/ffmpeg_args.dart';
import 'tool/media_info.dart';
import 'tool/transcoding_args_generator.dart';

class TranscodingPage extends StatefulWidget {
  const TranscodingPage({super.key});

  @override
  State<TranscodingPage> createState() => _TranscodingPageState();
}

class _TranscodingPageState extends State<TranscodingPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final ValueNotifier<String> _logNotifier = ValueNotifier<String>('');
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0);

  bool _isExecuting = false;
  File? _inFile, _outFile;
  FFmpegSession? _session;

  @override
  void initState() {
    super.initState();

    AssetPicker.registerObserve();
  }

  @override
  void dispose() {
    AssetPicker.unregisterObserve();
    _session?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text('Transcoding Page'),
        actions: <Widget>[
          IconButton(
            onPressed: _handleTapPickVideo,
            icon: const Icon(CupertinoIcons.add),
          ),
        ],
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_inFile != null) _buildFileWidget('📁 In File', _inFile!),
          if (_outFile != null) _buildFileWidget('📁 Out File', _outFile!),
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                reverse: true,
                child: ValueListenableBuilder<String>(
                  valueListenable: _logNotifier,
                  builder: (BuildContext context, String value, Widget? child) {
                    return Text(value);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isExecuting ? null : _handleTapProcess,
        tooltip: 'Process',
        child: _isExecuting
            ? ValueListenableBuilder<double>(
                valueListenable: _progressNotifier,
                builder: _buildProgressIndicator,
              )
            : const Icon(CupertinoIcons.command),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    double value,
    Widget? child,
  ) {
    return CircularProgressIndicator(value: value);
  }

  Widget _buildFileWidget(String tag, File file) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<int>(
        future: file.length(),
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          final int fileLength = snapshot.data ?? 0;
          final String lengthText =
              (fileLength / 1024 / 1024).toStringAsFixed(2);

          final StringBuffer buffer = StringBuffer(tag)
            ..writeln()
            ..writeln('path: ${file.path}')
            ..writeln('length: $lengthText MB');
          return Text(buffer.toString());
        },
      ),
    );
  }

  void _handleTapPickVideo() {
    if (_isExecuting) {
      return;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      AssetPicker.pickAssets(
        context,
        pickerConfig: AssetPickerConfig(
          maxAssets: 1,
          requestType: RequestType.video,
          filterOptions: FilterOptionGroup(
            containsLivePhotos: false,
          ),
        ),
      ).then((List<AssetEntity>? value) async {
        if (mounted && value != null) {
          // https://github.com/fluttercandies/flutter_photo_manager/issues/704
          final File? file = await value.first.originFile;
          if (mounted && file != null) {
            setState(() {
              _inFile = file;
            });
          }
        }
      }).catchError((dynamic error, StackTrace stackTrace) {
        debugPrint('$error: $stackTrace');
      });
    } else {
      _imagePicker
          .pickVideo(source: ImageSource.gallery)
          .then((XFile? value) async {
        if (mounted && value != null) {
          final File file = File(value.path);
          if (!mounted) {
            return;
          }
          setState(() {
            _inFile = file;
          });
        }
      });
    }
  }

  Future<void> _handleTapProcess() async {
    if (_inFile == null || _isExecuting) {
      return;
    }

    // Clear log
    _logNotifier.value = '';
    _progressNotifier.value = 0;

    setState(() {
      _isExecuting = true;
      _outFile = null;
    });

    final String inputPath = _inFile!.path;
    final Directory outputDir = Platform.isAndroid
        ? (await getExternalCacheDirectories())!.first
        : await getTemporaryDirectory();
    final String outputPath = p.join(outputDir.path, 'Encoded.MP4');

    final (NvFFmpegArgs, NvInputMediaInfo, NvOutputMediaInfo) args =
        await generateTranscodingArgs(
      inputPath: inputPath,
      outputPath: outputPath,
    );
    debugPrint('Session will start with args: ${args.$1.toCommand()}');

    _session = await FFmpegKit.executeWithArgumentsAsync(
      args.$1.toArguments(),
      _handleSession,
      _handleFFmpegLog,
      // CALLED WHEN SESSION GENERATES STATISTICS
      (Statistics statistics) {
        double progress = 0;
        final int? totalTime = args.$3.duration?.inMilliseconds;
        if (totalTime != null && totalTime > 0) {
          progress = statistics.getTime() / totalTime;
          if (progress < 0) {
            progress = 0;
          }
        }
        _progressNotifier.value = progress;
      },
    );
  }

  // CALLED WHEN SESSION IS EXECUTED
  Future<void> _handleSession(Session session) async {
    if (!mounted) {
      return;
    }

    final ReturnCode? returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      final DateTime? startTime = session.getStartTime();
      final DateTime? endTime = await session.getEndTime();
      String elapsed = '';
      if (startTime != null && endTime != null) {
        elapsed = endTime.difference(startTime).toString();
      }
      debugPrint('✅ Session is executed. Elapsed: $elapsed');
    } else if (ReturnCode.isCancel(returnCode)) {
      debugPrint('🛑 Session is canceled.');
    } else {
      debugPrint('❌ Session is failed.');
    }

    final String outPath = session.getArguments()!.last;
    setState(() {
      _isExecuting = false;
      _outFile = File(outPath);
    });
  }

  // CALLED WHEN SESSION PRINTS LOGS
  void _handleFFmpegLog(Log log) {
    _logNotifier.value = '${_logNotifier.value}${log.getMessage()}';
  }
}
