input="$HOME/Downloads/flutter_video_compress_test/800-400-1.3gp"
output="$HOME/Downloads/flutter_video_compress_test/ffmpeg_out.MP4"

# 2-Pass Encoding (H.265)
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

ffprobe -show_format "$output"