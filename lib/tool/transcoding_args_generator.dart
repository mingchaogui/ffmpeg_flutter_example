import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:rational/rational.dart';

import 'args/ffmpeg_args.dart';
import 'args/ffmpeg_video_filter_args.dart';
import 'limit/video_aspect_ratio_limit.dart';
import 'limit/video_bitrate_limit.dart';
import 'limit/video_size_limit.dart';
import 'media_info.dart';

Future<(NvFFmpegArgs, NvInputMediaInfo, NvOutputMediaInfo)>
    generateTranscodingArgs({
  required String inputPath,
  required String outputPath,
  NvVideoAspectRatioLimit videoAspectRatioLimit =
      NvVideoAspectRatioLimit.upload,
  NvVideoSizeLimit videoSizeLimit = NvVideoSizeLimit.normal,
  NvVideoBitrateLimit videoBitrateLimit = NvVideoBitrateLimit.normal,
  Duration? startTime,
  Duration? endTime,
}) async {
  final NvInputMediaInfo inInfo = await NvInputMediaInfo.fromFile(inputPath);
  final NvOutputMediaInfo outInfo = inInfo.toCompressed(
    videoAspectRatioLimit: videoAspectRatioLimit,
    videoSizeLimit: videoSizeLimit,
    videoBitrateLimit: videoBitrateLimit,
    startTime: startTime,
    endTime: endTime,
  );

  final NvFFmpegArgs args = NvFFmpegArgs(
    inputPath: inputPath,
    outputPath: outputPath,
  )
    ..benchmark = kDebugMode
    ..enableData = false
    ..hwaccel = FFmpegHwaccel.auto
    ..startTime = startTime
    ..endTime = endTime;
  if (inInfo.needReEncodeVideo(outInfo)) {
    args.videoEncoder =
        await _getBestVideoEncoder() ?? FFmpegVideoEncoder.libx264;
    if (args.videoEncoder!.isH264) {
      // https://trac.ffmpeg.org/wiki/Encode/H.264#Encodingfordumbplayers
      //
      // You may need to use -vf format=yuv420p (or the alias -pix_fmt yuv420p)
      // for your output to work in QuickTime and most other players.
      // These players only support the YUV planar color space with 4:2:0 chroma subsampling for H.264 video.
      // Otherwise, depending on your source, ffmpeg may output to a pixel format that may be incompatible with these players.
      args.pixFmt = 'yuv420p';
    }
    args
      ..fpsmax = outInfo.vFps.toString()
      ..videoBitrate = outInfo.vBitrate?.toString();

    final NvFFmpegVideoFilterArgs filterArgs = NvFFmpegVideoFilterArgs()
      ..resetSar = inInfo.vSampleAspectRatio != null &&
          inInfo.vSampleAspectRatio != Rational.one
      ..hdrToSdr = inInfo.vIsHdr && inInfo.vIsHdr != outInfo.vIsHdr;
    if (inInfo.vDisplaySize != outInfo.vDisplaySize || filterArgs.resetSar) {
      filterArgs.size = outInfo.vDisplaySize;
    }
    final String filterCmd = filterArgs.toCommand();
    if (filterCmd.isNotEmpty) {
      args.videoFilter = filterCmd;
    }
  } else {
    // 无需重编码
    args.videoEncoder = FFmpegVideoEncoder.copy;
  }
  if (inInfo.needReEncodeAudio(outInfo)) {
    if (inInfo.aBitrate != outInfo.aBitrate) {
      args.audioBitrate = outInfo.aBitrate?.toString();
    }
    if (inInfo.aChannels != outInfo.aChannels) {
      args.audioChannels = outInfo.aChannels;
    }
  } else {
    // 无需重编码
    args.audioEncoder = FFmpegAudioEncoder.copy;
  }

  return (args, inInfo, outInfo);
}

Future<FFmpegVideoEncoder?> _getBestVideoEncoder() async {
  if (Platform.isIOS) {
    // 参考资料
    // https://support.apple.com/zh-cn/HT207022#working
    final IosDeviceInfo osInfo = await DeviceInfoPlugin().iosInfo;
    if (!osInfo.isPhysicalDevice) {
      return null;
    }

    final int? osMajorVersion = int.tryParse(
      osInfo.systemVersion.split('.').firstOrNull ?? '',
    );
    if (osMajorVersion == null || osMajorVersion < 11) {
      return null;
    }

    final IosMachine iosMachine = IosMachine.fromName(osInfo.utsname.machine);
    if (iosMachine.generation == null) {
      return null;
    }

    if (iosMachine.baseName == 'iPhone') {
      if (iosMachine.generation! >= 9) {
        return FFmpegVideoEncoder.hevcVideoToolBox;
      } else if (iosMachine.generation! >= 7) {
        return FFmpegVideoEncoder.h264VideoToolBox;
      }
    } else if (iosMachine.baseName == 'iPad') {
      if (iosMachine.generation! >= 7) {
        return FFmpegVideoEncoder.hevcVideoToolBox;
      } else if (iosMachine.generation! >= 5) {
        return FFmpegVideoEncoder.h264VideoToolBox;
      }
    }
  } else if (Platform.isMacOS) {
    final MacOsDeviceInfo osInfo = await DeviceInfoPlugin().macOsInfo;
    if (osInfo.majorVersion > 10 ||
        (osInfo.majorVersion == 10 && osInfo.minorVersion >= 13)) {
      return FFmpegVideoEncoder.hevcVideoToolBox;
    }
    return FFmpegVideoEncoder.h264VideoToolBox;
  }

  return null;
}

class IosMachine {
  const IosMachine({
    required this.baseName,
    required this.generation,
    required this.version,
  });

  // e.g.
  // iPhone1,2 : iPhone 3G
  // iPhone10,1 : iPhone 8
  factory IosMachine.fromName(String input) {
    final RegExp baseNameRegExp = RegExp(r'[A-Za-z]+');
    final RegExp generationRegExp = RegExp(r'(?<=[A-Za-z]+)\d+');
    final RegExp versionRegExp = RegExp(r'(?<=[A-Za-z]+\d+,)\d+');

    final String? generation = generationRegExp.firstMatch(input)?.group(0);
    final String? version = versionRegExp.firstMatch(input)?.group(0);

    return IosMachine(
      baseName: baseNameRegExp.firstMatch(input)?.group(0),
      generation: generation != null ? int.tryParse(generation) : null,
      version: version != null ? int.tryParse(version) : null,
    );
  }

  final String? baseName;
  final int? generation;
  final int? version;

  @override
  String toString() {
    return '(IosMachine) baseName: $baseName, generation: $generation, version: $version';
  }
}
