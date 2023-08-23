import 'package:ffmpeg_example/tool/limit/video_aspect_ratio_limit.dart';
import 'package:ffmpeg_example/tool/limit/video_bitrate_limit.dart';
import 'package:ffmpeg_example/tool/limit/video_size_limit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Cropper size smoke test', () {
    const Size inSize = Size(1080, 2560);
    Size outSize = NvVideoAspectRatioLimit.upload.clampSize(
      inSize.width,
      inSize.height,
    );
    outSize = NvVideoSizeLimit.normal.clamp(
      outSize.width,
      outSize.height,
    );
    debugPrint('inSize: $inSize, outSize: $outSize');
  });

  test('Video bitRate smoke test', () {
    final int bitrate = NvVideoBitrateLimit.normal.calculate(
      pixels: 1920 * 1080,
      fps: 60,
    );
    debugPrint('bitrate: ${(bitrate / 1000).floor()} Kbps');
  });
}
