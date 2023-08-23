import 'dart:math' as math;

import 'package:flutter/material.dart';

enum NvVideoSizeLimit {
  normal(1920, 1920);

  const NvVideoSizeLimit(
    this.width,
    this.height,
  );

  final int width;
  final int height;

  Size clamp(num w, num h) {
    final double scale = math.min(
      width / w,
      height / h,
    );
    if (scale >= 1.0) {
      return Size(w.toDouble(), h.toDouble());
    }
    return Size(w * scale, h * scale);
  }

  Size get size {
    return Size(width.toDouble(), height.toDouble());
  }
}
