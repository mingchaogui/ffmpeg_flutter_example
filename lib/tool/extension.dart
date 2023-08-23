import 'dart:ui';

import 'package:ffmpeg_kit_flutter_full_gpl/media_information.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/stream_information.dart';
import 'package:rational/rational.dart';

extension NvMediaNumExt on num {
  int ceilToEven() {
    if (this % 2 == 0) {
      return toInt();
    }
    return this ~/ 2 * 2 + 2;
  }
}

extension NvMediaStringExt on String {
  Rational? tryToRational() {
    final List<String> parts = split(':');
    if (parts.length != 2) {
      return null;
    }

    final BigInt numerator, denominator;
    try {
      numerator = BigInt.parse(parts.first);
      denominator = BigInt.parse(parts.last);
    } catch (error) {
      return null;
    }

    return Rational(numerator, denominator);
  }
}

extension NvMediaSizeExt on Size {
  Size ceilToEven() {
    return Size(
      width.ceilToEven().ceilToDouble(),
      height.ceilToEven().ceilToDouble(),
    );
  }
}

extension MediaInformationExt on MediaInformation {
  Duration? get duration {
    final String? str = getDuration();
    if (str == null) {
      return null;
    }
    final double? seconds = double.tryParse(str);
    if (seconds == null) {
      return null;
    }
    final int micros = (seconds * 1000 * 1000).toInt();
    return Duration(microseconds: micros);
  }
}

// https://ffmpeg.org/ffmpeg.html#toc-Automatic-stream-selection
extension StreamInformationIterableExt on Iterable<StreamInformation> {
  // For video, it is the stream with the highest resolution
  StreamInformation? get videoStream {
    StreamInformation? stream;
    int? highestPixels;

    for (final StreamInformation element in this) {
      final String? type = element.getType();
      if (type != 'video') {
        continue;
      }

      final int? pixels = element.displayPixels;
      if (highestPixels != null) {
        if (pixels == null || pixels <= highestPixels) {
          continue;
        }
      }

      stream = element;
      highestPixels = pixels;
    }

    return stream;
  }

  // For audio, it is the stream with the most channels
  StreamInformation? get audioStream {
    StreamInformation? stream;
    num? mostChannels;

    for (final StreamInformation element in this) {
      final String? type = element.getType();
      if (type != 'audio') {
        continue;
      }

      final num? channels = element.channels;
      if (mostChannels != null) {
        if (channels == null || channels <= mostChannels) {
          continue;
        }
      }

      stream = element;
      mostChannels = channels;
    }

    return stream;
  }
}

extension StreamInformationExt on StreamInformation {
  static const String keyChannels = 'channels';
  static const String keyColorTransfer = 'color_transfer';
  static const String keySideDataList = 'side_data_list';
  static const String keyRotation = 'rotation';

  int? get bitrate {
    final String? str = getStringProperty(StreamInformation.keyBitRate);
    if (str == null) {
      return null;
    }
    return int.tryParse(str);
  }

  int? get channels => getNumberProperty(keyChannels)?.toInt();

  String? get colorTransfer => getStringProperty(keyColorTransfer);

  Rational? get fps {
    final String? str = getRealFrameRate();
    if (str == null) {
      return null;
    }

    final List<String> frags = str.split('/');
    try {
      return Rational.fromInt(
        int.parse(frags.first),
        int.parse(frags[1]),
      );
    } on Error {
      return null;
    }
  }

  bool get isHDR {
    switch (colorTransfer) {
      case 'arib-std-b67':
      case 'smpte2084':
        return true;
      default:
    }
    return false;
  }

  int? get displayPixels {
    final Size? s = displaySize;
    if (s == null) {
      return null;
    }
    return (s.width * s.height).toInt();
  }

  int? get rotation {
    for (final Map<String, dynamic> sideData in sideDataList) {
      final int? rotation = sideData[keyRotation];
      if (rotation != null) {
        return rotation;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get sideDataList {
    final List<dynamic>? list = getProperty(keySideDataList);
    if (list != null) {
      return List<Map<String, dynamic>>.generate(
        list.length,
            (int index) => (list[index] as Map<dynamic, dynamic>).cast(),
      );
    }
    return const <Map<String, dynamic>>[];
  }

  Size? get displaySize {
    final int? height = getHeight();

    int? width;
    // https://stackoverflow.com/questions/5839475/ffmpeg-reports-different-wrong-video-resolution-compared-to-how-it-actually-pl
    if (height != null) {
      final Rational? dar = getDisplayAspectRatio()?.tryToRational();
      if (dar != null) {
        width = (Rational.fromInt(height) * dar).toBigInt().toInt();
      }
    }
    width ??= getWidth();

    if (width == null || height == null) {
      return null;
    }
    return Size(width.toDouble(), height.toDouble());
  }
}
