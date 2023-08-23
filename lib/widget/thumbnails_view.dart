import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

// JPEG is fastest
const ImageFormat _kImageFormat = ImageFormat.JPEG;
// For example, large pictures on website Vkontakte are saved with the quality 87,
// previews in the Google search for pictures – with quality of jpg 74.
const int _kImageQuality = 74;

class ThumbnailsView extends StatefulWidget {
  const ThumbnailsView({
    super.key,
    required this.path,
    required this.duration,
    this.numberOfThumbnails = 10,
  });

  final String path;
  final Duration duration;
  final int numberOfThumbnails;

  double get _interval => duration.inMilliseconds / numberOfThumbnails;

  @override
  State<ThumbnailsView> createState() => _ThumbnailsViewState();
}

class _ThumbnailsViewState extends State<ThumbnailsView> {
  final List<Uint8List?> _thumbnails = <Uint8List?>[];
  Object? _loadKey;

  @override
  void initState() {
    super.initState();

    Future<void>.delayed(Duration.zero, _loadThumbnails);
  }

  @override
  void didUpdateWidget(covariant ThumbnailsView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.path != widget.path ||
        oldWidget.duration != widget.duration ||
        oldWidget.numberOfThumbnails != widget.numberOfThumbnails) {
      _loadThumbnails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: _buildWithConstraints);
  }

  Widget _buildWithConstraints(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return Row(
      children: List<Widget>.generate(widget.numberOfThumbnails, (int index) {
        Uint8List? imageData;
        if (index < _thumbnails.length) {
          imageData = _thumbnails[index];
        }

        Widget? current;

        if (imageData != null) {
          current = Image.memory(imageData, fit: BoxFit.cover);
        }

        current = Expanded(
          child: AspectRatio(
            aspectRatio: 1 / 1.6,
            child: current,
          ),
        );

        return current;
      }),
    );
  }

  Future<void> _loadThumbnails() async {
    if (_thumbnails.isNotEmpty) {
      setState(() {
        _thumbnails.clear();
      });
    }

    final MediaQueryData mediaQuery = MediaQuery.of(context);

    final Object loadKey = _loadKey = Object();
    final String path = widget.path;
    final int length = widget.numberOfThumbnails;

    bool shouldIntercept() {
      return !mounted || loadKey != _loadKey;
    }

    // 限制缩略图的宽高以减小体积
    final int maxWidth =
        (mediaQuery.size.width * mediaQuery.devicePixelRatio / length).ceil();

    for (int i = 0; i < length; i++) {
      final Uint8List? imageData = await VideoThumbnail.thumbnailData(
        video: path,
        imageFormat: _kImageFormat,
        maxWidth: maxWidth,
        timeMs: (widget._interval * i).toInt(),
        quality: _kImageQuality,
      ).catchError((dynamic error, StackTrace stackTrace) {
        debugPrint('$error, $stackTrace');
        return null;
      });

      if (shouldIntercept()) {
        break;
      }

      setState(() {
        _thumbnails.add(imageData);
      });
    }
  }
}
