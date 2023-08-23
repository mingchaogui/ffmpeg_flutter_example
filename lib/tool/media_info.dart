import 'dart:math' as math;

import 'package:ffmpeg_kit_flutter_full_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information_session.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/stream_information.dart';
import 'package:flutter/material.dart';
import 'package:rational/rational.dart';

import 'extension.dart';
import 'limit/video_aspect_ratio_limit.dart';
import 'limit/video_bitrate_limit.dart';
import 'limit/video_size_limit.dart';

const int _kAudioBitrateLimit = 128 * 1000;
const int _kAudioChannelsLimit = 2;
const bool _kKeepHdr = false;
final Rational _kVideoFpsLimit = Rational(BigInt.from(60), BigInt.one);
const List<String> _kAllowedAudioCodecs = <String>['aac'];
const List<String> _kAllowedVideoCodecs = <String>['h264', 'hevc'];

class _NvMediaInfo {
  const _NvMediaInfo({
    required this.duration,
    required this.aBitrate,
    required this.aChannels,
    required this.vBitrate,
    required this.vDisplaySize,
    required this.vFps,
    required this.vIsHdr,
  });

  final Duration? duration;
  final int? aBitrate;
  final int? aChannels;
  final int? vBitrate;
  final Size? vDisplaySize;
  final Rational? vFps;
  final bool vIsHdr;
}

class NvInputMediaInfo extends _NvMediaInfo {
  const NvInputMediaInfo({
    required super.duration,
    required super.aBitrate,
    required super.aChannels,
    required super.vIsHdr,
    required super.vBitrate,
    required super.vFps,
    required super.vDisplaySize,
    required this.vRotation,
    required this.vSampleAspectRatio,
    required this.forceReEncodeVideo,
    required this.forceReEncodeAudio,
  });

  final int? vRotation;
  final Rational? vSampleAspectRatio;
  final bool forceReEncodeVideo;
  final bool forceReEncodeAudio;

  static Future<NvInputMediaInfo> fromFile(String filePath) async {
    final MediaInformationSession infoSession =
    await FFprobeKit.getMediaInformation(filePath);
    final MediaInformation? mediaInfo = infoSession.getMediaInformation();
    final StreamInformation? videoStream = mediaInfo?.getStreams().videoStream;
    final StreamInformation? audioStream = mediaInfo?.getStreams().audioStream;

    return NvInputMediaInfo(
      duration: mediaInfo?.duration,
      aBitrate: audioStream?.bitrate,
      aChannels: audioStream?.channels,
      vBitrate: videoStream?.bitrate,
      vDisplaySize: videoStream?.displaySize,
      vFps: videoStream?.fps,
      vIsHdr: videoStream?.isHDR ?? false,
      vRotation: videoStream?.rotation,
      vSampleAspectRatio: videoStream?.getSampleAspectRatio()?.tryToRational(),
      forceReEncodeVideo:
      !_kAllowedVideoCodecs.contains(videoStream?.getCodec()),
      forceReEncodeAudio:
      !_kAllowedAudioCodecs.contains(audioStream?.getCodec()),
    );
  }

  NvOutputMediaInfo toCompressed({
    NvVideoAspectRatioLimit videoAspectRatioLimit =
        NvVideoAspectRatioLimit.upload,
    NvVideoSizeLimit videoSizeLimit = NvVideoSizeLimit.normal,
    NvVideoBitrateLimit videoBitrateLimit = NvVideoBitrateLimit.normal,
    Duration? startTime,
    Duration? endTime,
  }) {
    final Duration outDuration =
        (endTime ?? duration ?? Duration.zero) - (startTime ?? Duration.zero);

    // 确保输出fps不超过输入fps
    final Rational? outVFps =
    vFps != null && vFps! < _kVideoFpsLimit ? vFps : _kVideoFpsLimit;

    Size outVDisplaySize;
    if (vDisplaySize != null) {
      outVDisplaySize = vDisplaySize!;

      // 应用rotation
      // 由于输出时去掉了rotation，需要翻转wh以匹配输入
      if (vRotation != null && vRotation! % 180 == 90) {
        outVDisplaySize = vDisplaySize!.flipped;
      }
      // 限制wh比
      outVDisplaySize = videoAspectRatioLimit.clampSize(
        outVDisplaySize.width,
        outVDisplaySize.height,
      );
      // 限制wh
      outVDisplaySize = videoSizeLimit.clamp(
        outVDisplaySize.width,
        outVDisplaySize.height,
      );
      // wh必须是偶数
      outVDisplaySize = outVDisplaySize.ceilToEven();
    } else {
      // 无法获知输入的wh，默认赋为上界值
      outVDisplaySize = videoSizeLimit.size;
    }

    // 估算最优bitrate
    int outVBitrate = videoBitrateLimit.calculate(
      pixels: outVDisplaySize.width * outVDisplaySize.height,
      fps: outVFps?.toDouble(),
    );
    // 确保输出bitrate不超过输入bitrate
    outVBitrate = math.min(
      outVBitrate,
      vBitrate ?? outVBitrate,
    );

    return NvOutputMediaInfo(
      duration: outDuration,
      aBitrate: math.min(
        aBitrate ?? _kAudioBitrateLimit,
        _kAudioBitrateLimit,
      ),
      aChannels: _kAudioChannelsLimit,
      vBitrate: outVBitrate,
      vDisplaySize: outVDisplaySize,
      vFps: outVFps,
      vIsHdr: vIsHdr && _kKeepHdr,
      // 确保SAR是1:1
      resetVSampleAspectRatio:
      vSampleAspectRatio != null && vSampleAspectRatio != Rational.one,
    );
  }

  bool needReEncodeVideo(NvOutputMediaInfo to) {
    return forceReEncodeVideo ||
        vBitrate != to.vBitrate ||
        vFps != to.vFps ||
        vIsHdr != to.vIsHdr ||
        vDisplaySize != to.vDisplaySize;
  }

  bool needReEncodeAudio(NvOutputMediaInfo to) {
    return forceReEncodeAudio ||
        aBitrate != to.aBitrate ||
        aChannels != to.aChannels;
  }
}

class NvOutputMediaInfo extends _NvMediaInfo {
  const NvOutputMediaInfo({
    required super.duration,
    required super.aBitrate,
    required super.aChannels,
    required super.vBitrate,
    required super.vFps,
    required super.vIsHdr,
    required super.vDisplaySize,
    required this.resetVSampleAspectRatio,
  });

  final bool resetVSampleAspectRatio;
}
