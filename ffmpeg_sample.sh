input="$HOME/Downloads/flutter_video_compress_test/800-400-1.3gp"
output="$HOME/Downloads/flutter_video_compress_test/ffmpeg_out.MP4"

# 2-Pass Encoding
#ffmpeg -y
# -i "$HOME/Downloads/IMG_2504.MOV" \
#-vf scale=1920:1080 \
#-c:v hevc_videotoolbox -b:v 2600k -x265-params pass=1 \
#-an \
#-f null \
#"/dev/null" && \
#ffmpeg -i "$input" \
#-tag:v hvc1 \
#-movflags +faststart \
#-vf scale=1920:1080 \
#-fpsmax 60000/1001 \
#-c:v hevc_videotoolbox -b:v 2600k -x265-params pass=2 \
#-c:a aac -b:a 128k \
#"$output"

# 1-Pass Encoding (H.264)
#ffmpeg -y \
#-ss 0 \
#-i "$input" \
#-fpsmax 60000/1001 \
#-movflags +faststart \
#-pix_fmt yuv420p \
#-tag:v avc1 \
#-vf scale=1920:1080 \
#-c:v libx264 -b:v 2600k \
#-c:a aac -b:a 128k \
#"$output"

# 1-Pass Encoding (H.265)
ffmpeg -y \
-ss 0 \
-i "$input" \
-fpsmax 60000/1001 \
-movflags +faststart \
-tag:v hvc1 \
-vf scale=1920:1920 \
-c:v hevc_videotoolbox -b:v 2600k \
-c:a aac -b:a 128k \
"$output"

# Video: hevc (Main 10) (hvc1 / 0x31637668), yuv420p10le(tv, bt2020nc/bt2020/arib-std-b67), 3840x2160, 52754 kb/s, 59.97 fps, 60 tbr, 600 tbn (default)
#    Metadata:
#      creation_time   : 2023-06-21T11:33:42.000000Z
#      handler_name    : Core Media Video
#      vendor_id       : [0][0][0][0]
#      encoder         : HEVC
# Audio: aac (LC) (mp4a / 0x6134706D), 44100 Hz, stereo, fltp, 179 kb/s (default)
#    Metadata:
#      creation_time   : 2023-06-21T11:33:42.000000Z
#      handler_name    : Core Media Audio
#      vendor_id       : [0][0][0][0]
#ffprobe -show_format "$HOME/Downloads/IMG_2504.MOV"

# Video: hevc (Main) (hvc1 / 0x31637668), yuv420p(tv, bt709), 1920x1080, 9722 kb/s, 59.97 fps, 60 tbr, 1000k tbn (default)
#    Metadata:
#      creation_time   : 2023-06-21T11:34:28.000000Z
#      handler_name    : Core Media Video
#      vendor_id       : FFMP
# Audio: aac (LC) (mp4a / 0x6134706D), 44100 Hz, stereo, fltp, 124 kb/s (default)
#     Metadata:
#      creation_time   : 2023-06-21T11:34:28.000000Z
#      handler_name    : Core Media Audio
#      vendor_id       : [0][0][0][0]
#ffprobe -show_format "$HOME/Downloads/IMG_2504@douyin.MOV"

# Video: h264 (High) (avc1 / 0x31637661), yuv420p(tv, bt2020nc/bt2020/arib-std-b67, progressive), 1920x1080, 2743 kb/s, 59.94 fps, 59.94 tbr, 60k tbn (default)
#    Metadata:
#      handler_name    : Core Media Video
#      vendor_id       : [0][0][0][0]
#      encoder         : Lavc60.3.100 libx264
# Audio: aac (LC) (mp4a / 0x6134706D), 44100 Hz, stereo, fltp, 128 kb/s (default)
#    Metadata:
#      handler_name    : Core Media Audio
#      vendor_id       : [0][0][0][0]
ffprobe -show_format "$output"