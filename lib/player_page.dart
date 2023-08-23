import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'widget/fitted_video_box.dart';

const String _kVideoPath = 'videos/8d174cde-b1e5-4f47-af60-68e5d667c9be.MP4';

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final VideoPlayerController _controller;
  late final Future<Uint8List?> _coverFuture;

  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(_kVideoPath)
      ..addListener(_handlePlayerValueChanged)
      ..initialize().then((_) {
        if (!mounted) {
          return;
        }
        assert(() {
          final VideoPlayerValue value = _controller.value;
          debugPrint('${value.size}, Duration: ${value.duration}');
          return true;
        }());
        setState(() {});
      });
    _coverFuture = Future.sync(() async {
      final ByteData data = await rootBundle.load(_kVideoPath);
      final Directory directory = await getTemporaryDirectory();
      final String baseName = p.basename(_kVideoPath);
      final File file = File(p.join(directory.path, baseName));
      // 复制到临时目录
      return file.writeAsBytes(data.buffer.asUint8List());
    }).then((File file) {
      return VideoThumbnail.thumbnailData(
        video: file.path,
        imageFormat: ImageFormat.WEBP,
        quality: 74,
      );
    }).then((Uint8List? value) async {
      if (value != null) {
        debugPrint('Thumbnail size: ${value.length ~/ 1024} KB');
        final Codec codec = await instantiateImageCodec(value);
        final FrameInfo frameInfo = await codec.getNextFrame();
        debugPrint('Frame image: ${frameInfo.image}');
      }
      return value;
    }).catchError((error, stackTrace) {
      debugPrint('$error, $stackTrace');
      return null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player Page'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: <Widget>[
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                FittedVideoBox(
                  fit: BoxFit.cover,
                  player: _controller,
                  child: VideoPlayer(_controller),
                ),
                Visibility(
                  visible: !_isPlaying,
                  child: FutureBuilder<Uint8List?>(
                    future: _coverFuture,
                    builder: _buildCover,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isPlaying ? _controller.pause() : _controller.play();
          });
        },
        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
      ),
    );
  }

  Widget _buildCover(BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
    if (snapshot.data == null) {
      return const SizedBox();
    }

    return Image(
      image: MemoryImage(snapshot.requireData!),
      fit: BoxFit.cover,
    );
  }

  void _handlePlayerValueChanged() {
    final VideoPlayerValue playerValue = _controller.value;

    if (_isPlaying != playerValue.isPlaying) {
      setState(() {
        _isPlaying = playerValue.isPlaying;
      });
    }
  }
}
