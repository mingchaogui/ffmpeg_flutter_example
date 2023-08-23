import 'dart:ui';

class NvFFmpegVideoFilterArgs {
  Size? size;
  bool resetSar = false;
  bool hdrToSdr = false;

  String toCommand() {
    final int? width = size?.width.toInt();
    final int? height = size?.height.toInt();

    final List<String> filters = <String>[
      if (size != null)
        'scale=$width:$height:force_original_aspect_ratio=increase,crop=$width:$height',
      if (resetSar) 'setsar',
      if (hdrToSdr)
        'zscale=t=linear:npl=100,format=gbrpf32le,zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p',
    ];

    return filters.join(',');
  }
}
