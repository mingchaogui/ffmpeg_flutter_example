const double _kFpsBase = 30.0;
// 给定一个最小码率，避免过度压缩导致画面破损
const int _kMinBitrate = 2250 * 1000;

// https://support.google.com/youtube/answer/2853702?hl=zh-Hans
enum NvVideoBitrateLimit {
  // (4500 * 1000 bps) / (1920 * 1080)
  normal(2.17013888889);

  const NvVideoBitrateLimit(this.bitrateBase);

  final double bitrateBase;

  int calculate({
    required num pixels,
    num? fps,
  }) {
    double result = pixels * bitrateBase;
    if (fps != null && fps > _kFpsBase) {
      result *= 1 + (fps - _kFpsBase) / _kFpsBase / 2;
    }
    return result > _kMinBitrate ? result.ceil() : _kMinBitrate;
  }
}
