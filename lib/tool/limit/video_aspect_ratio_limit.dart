import 'package:flutter/material.dart';

/// 参考文档：
/// https://www.notion.so/Video-Size-c9da3641ff1a4e3ca59c7b84daf638bd
enum NvVideoAspectRatioLimit {
  // 上传比例，9:16 ~ 1.91:1
  upload(0.5625, 1.91),
  // 显示比例，4:5 ~ 1.91:1
  display(0.8, 1.91);

  const NvVideoAspectRatioLimit(
    this.lowerLimit,
    this.upperLimit,
  );

  final double lowerLimit;
  final double upperLimit;

  double clamp(double value) {
    return value.clamp(lowerLimit, upperLimit);
  }

  // 长边会被裁切
  Size clampSize(num width, num height) {
    final double targetRatio = clamp(width / height);
    if (width < height) {
      return Size(
        width.toDouble(),
        width / targetRatio,
      );
    }
    return Size(
      height * targetRatio,
      height.toDouble(),
    );
  }
}
