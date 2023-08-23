import 'dart:io';

import 'package:ffmpeg_example/widget/thumbnails_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class ThumbnailPage extends StatefulWidget {
  const ThumbnailPage({super.key});

  @override
  State<ThumbnailPage> createState() => _ThumbnailPageState();
}

class _ThumbnailPageState extends State<ThumbnailPage> {
  final ImagePicker _imagePicker = ImagePicker();

  File? _inFile;
  VideoPlayerController? _playerController;

  @override
  void dispose() {
    _playerController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thumbnail Page'),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_inFile != null) _buildFileWidget('📁 In File', _inFile!),
            if (_playerController?.value.isInitialized ?? false) ...<Widget>[
              AspectRatio(
                aspectRatio: _playerController!.value.aspectRatio,
                child: VideoPlayer(_playerController!),
              ),
              ThumbnailsView(
                path: _inFile!.path,
                duration: _playerController!.value.duration,
              ),
            ],
          ],
        ),
      ),
    );
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

  Future<void> _handleTapPickVideo() async {
    try {
      final File? file;

      if (Platform.isAndroid || Platform.isIOS) {
        final List<AssetEntity>? entities = await AssetPicker.pickAssets(
          context,
          pickerConfig: AssetPickerConfig(
            maxAssets: 1,
            requestType: RequestType.video,
            filterOptions: FilterOptionGroup(
              containsLivePhotos: false,
            ),
          ),
        );
        if (!mounted || entities == null) {
          return;
        }

        // https://github.com/fluttercandies/flutter_photo_manager/issues/704
        file = await entities.first.originFile;
      } else {
        final XFile? xFile = await _imagePicker.pickVideo(
          source: ImageSource.gallery,
        );
        if (!mounted || xFile == null) {
          return;
        }

        file = File(xFile.path);
      }

      if (!mounted || file == null) {
        return;
      }

      final VideoPlayerController controller = VideoPlayerController.file(file);
      controller.initialize().then((void value) {
        if (!mounted || controller != _playerController) {
          controller.dispose();
          return;
        }
        setState(() {
          controller.play();
        });
      });

      _playerController?.dispose();
      setState(() {
        _inFile = file;
        _playerController = controller;
      });
    } catch (error, stackTrace) {
      debugPrint('$error: $stackTrace');
    }
  }
}
