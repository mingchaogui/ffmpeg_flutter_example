// https://ffmpeg.org/ffmpeg.html
class NvFFmpegArgs {
  NvFFmpegArgs({
    required this.inputPath,
    required this.outputPath,
  });

  final String inputPath;
  final String outputPath;

  // -benchmark (global)
  //
  // Show benchmarking information at the end of an encode.
  // Shows real, system and user time used and maximum memory consumption.
  // Maximum memory consumption is not supported on all systems, it will usually display as 0 if not supported.
  bool benchmark = false;

  // https://ffmpeg.org/ffmpeg.html#toc-Stream-selection
  //
  // ffmpeg provides the -map option for manual control of stream selection in each output file.
  // Users can skip -map and let ffmpeg perform automatic stream selection as described below.
  // The -vn / -an / -sn / -dn options can be used to skip inclusion of video, audio, subtitle and data streams respectively,
  // whether manually mapped or automatically selected, except for those streams which are outputs of complex filtergraphs.
  bool enableVideo = true;
  bool enableAudio = true;
  bool enableSubtitle = true;
  bool enableData = true;

  FFmpegVideoEncoder? videoEncoder;
  FFmpegAudioEncoder? audioEncoder;

  FFmpegHwaccel? hwaccel;

  // -ss position (input/output)
  //
  // When used as an input option (before -i), seeks in this input file to position.
  // Note that in most formats it is not possible to seek exactly, so ffmpeg will seek to the closest seek point before position.
  // When transcoding and -accurate_seek is enabled (the default), this extra segment between the seek point and position
  // will be decoded and discarded. When doing stream copy or when -noaccurate_seek is used, it will be preserved.
  Duration? startTime;
  // -to position (input/output)
  //
  // Stop reading the input at position.
  Duration? endTime;

  // -ac[:stream_specifier] channels (input/output,per-stream)
  //
  // Set the number of audio channels.
  // For output streams it is set by default to the number of input audio channels.
  // For input streams this option only makes sense for audio grabbing devices and raw demuxers and is mapped to the corresponding demuxer options.
  int? audioChannels;

  // -fpsmax[:stream_specifier] fps (output,per-stream)
  //
  // Set maximum frame rate (Hz value, fraction or abbreviation).
  // Clamps output frame rate when output framerate is auto-set and is higher than this value. Useful in batch processing or when input framerate is wrongly detected as very high. It cannot be set together with -r. It is ignored during streamcopy.
  String? fpsmax;

  // -pix_fmt[:stream_specifier] format (input/output,per-stream)
  //
  // Set pixel format. Use -pix_fmts to show all the supported pixel formats. If the selected pixel format can not be selected, ffmpeg will print a warning and select the best pixel format supported by the encoder. If pix_fmt is prefixed by a +, ffmpeg will exit with an error if the requested pixel format can not be selected, and automatic conversions inside filtergraphs are disabled. If pix_fmt is a single +, ffmpeg selects the same pixel format as the input (or graph output) and automatic conversions are disabled.
  String? pixFmt;

  // Create the filtergraph specified by filtergraph and use it to filter the stream.
  //
  // https://trac.ffmpeg.org/wiki/Scaling
  String? videoFilter;

  // -b:v
  //
  // specifies the target (average) bit rate for the encoder to use
  //
  // https://trac.ffmpeg.org/wiki/Limiting%20the%20output%20bitrate
  String? videoBitrate;

  // -b:a
  String? audioBitrate;

  List<String> toArguments() {
    return <String>[
      // https://ffmpeg.org/ffmpeg.html#Main-options
      // Overwrite output files without asking.
      '-y',
      if (benchmark) '-benchmark',
      if (hwaccel != null) ...<String>['-hwaccel', hwaccel!.name],
      if (startTime != null) ...<String>['-ss', startTime.toString()],
      if (endTime != null) ...<String>['-to', endTime.toString()],
      '-i',
      inputPath,
      if (audioChannels != null) ...<String>[
        '-ac',
        audioChannels.toString(),
      ],
      if (fpsmax != null) ...<String>['-fpsmax', fpsmax.toString()],
      // faststart for web video
      // https://trac.ffmpeg.org/wiki/Encode/H.264#faststartforwebvideo
      '-movflags',
      '+faststart',
      if (pixFmt != null) ...<String>['-pix_fmt', pixFmt!],
      if (videoEncoder?.vTag != null) ...<String>[
        '-tag:v',
        videoEncoder!.vTag!,
      ],
      if (videoFilter != null) ...<String>['-filter:v', videoFilter!],
      if (videoEncoder != null) ...<String>[
        '-codec:v',
        videoEncoder!.name,
        ...videoEncoder!.params,
      ],
      if (!enableVideo) '-vn',
      if (videoBitrate != null) ...<String>['-b:v', videoBitrate!],
      if (audioEncoder != null) ...<String>[
        '-codec:a',
        audioEncoder!.name,
      ],
      if (!enableAudio) '-vn',
      if (audioBitrate != null) ...<String>['-b:a', audioBitrate!],
      if (!enableSubtitle) '-sn',
      if (!enableData) '-dn',
      outputPath,
    ];
  }

  String toCommand() {
    return toArguments().join('\u0020');
  }
}

// -hwaccel[:stream_specifier] hwaccel (input,per-stream)
//
// Use hardware acceleration to decode the matching stream(s).
//
// This option has no effect if the selected hwaccel is not available or not supported by the chosen decoder.
//
// Note that most acceleration methods are intended for playback and will not be faster than software decoding on modern CPUs.
// Additionally, ffmpeg will usually need to copy the decoded frames from the GPU memory into the system memory,
// resulting in further performance loss. This option is thus mainly useful for testing.
enum FFmpegHwaccel {
  // Do not use any hardware acceleration (the default).
  none,
  // Automatically select the hardware acceleration method.
  auto,
  // Use VDPAU (Video Decode and Presentation API for Unix) hardware acceleration.
  vdpau,
  // Use DXVA2 (DirectX Video Acceleration) hardware acceleration.
  dxva2,
  // Use D3D11VA (DirectX Video Acceleration) hardware acceleration.
  d3d11va,
  // Use VAAPI (Video Acceleration API) hardware acceleration.
  vaapi,
  // Use the Intel QuickSync Video acceleration for video transcoding.
  qsv;
}

// To enable OpenCL lookahead add -x264opts opencl or -x264-params opencl=true to your command line.
// It will give a slight encoding speed boost using GPU, without hurting quality.
const List<String> _kX264Params = <String>[
  // It's experimental and can crash your GPU. It's not recommended.
  // https://obsproject.com/forum/threads/opencl-true-usefull-or-not.16862/
  // https://obsproject.com/forum/threads/when-putting-opencl-true-obs-crashes.39952/
  // '-x264-params',
  // 'opencl=true',
];

// https://trac.ffmpeg.org/wiki/Encode/MPEG-4
// https://trac.ffmpeg.org/wiki/Encode/H.264
// https://trac.ffmpeg.org/wiki/Encode/H.265
enum FFmpegVideoEncoder {
  copy('copy'),
  libx264('libx264', vTag: 'avc1', params: _kX264Params),
  // Not ready yet, waiting for FFmpeg 6.0 release
  h264Mediacodec('h264_mediacodec', vTag: 'avc1', params: _kX264Params),
  h264VideoToolBox('h264_videotoolbox', vTag: 'avc1', params: _kX264Params),
  hevc('hevc', vTag: 'hvc1'),
  hevcVideoToolBox('hevc_videotoolbox', vTag: 'hvc1');

  const FFmpegVideoEncoder(
    this.name, {
    this.vTag,
    this.params = const <String>[],
  });

  final String name;

  // Final Cut and Apple stuff compatibility
  // https://trac.ffmpeg.org/wiki/Encode/H.265#FinalCutandApplestuffcompatibility
  //
  // To make your file compatible with Apple "industry standard" H.265
  // you have to add the following argument -tag:v hvc1
  final String? vTag;

  final List<String> params;

  bool get isH264 {
    return this == FFmpegVideoEncoder.libx264 ||
        this == FFmpegVideoEncoder.h264Mediacodec ||
        this == FFmpegVideoEncoder.h264VideoToolBox;
  }
}

// https://trac.ffmpeg.org/wiki/Encode/HighQualityAudio
//
// Based on quality produced from high to low:
// libopus > libvorbis >= libfdk_aac > libmp3lame >= eac3/ac3 > aac > libtwolame > vorbis > mp2 > wmav2/wmav1
//
// The >= sign means greater or the same quality.
// This list is just a general guide and there may be cases where a codec listed to the right will perform better than one listed to the left at certain bitrates.
// The highest quality internal/native encoder available in FFmpeg without any external libraries is aac.
//
// Please note it is not recommended to use the experimental vorbis for Vorbis encoding; use libvorbis instead.
// Please note that wmav1 and wmav2 don't seem to be able to reach transparency at any given bitrate.
enum FFmpegAudioEncoder {
  copy('copy'),
  libopus('libopus'),
  libvorbis('libvorbis'),
  aac('aac');

  const FFmpegAudioEncoder(this.name);

  final String name;
}
