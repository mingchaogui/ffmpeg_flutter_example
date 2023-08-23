#input="$HOME/Downloads/Video/BigBuckBunny.mp4"
input="https://nova-dev-db.novanetwork.one/nova/article/video/kr7ur5FbfxWKiGU18OtE2MvNusM2/6e19043c-ef54-4319-a287-30b9d1c90cc4.MP4"
output="$HOME/Downloads/flutter_video_compress_test/thumb/thumb%04d.jpg"

ffmpeg -i $input -ss 00:00:00 -frames:v 1 thumb/0.jpeg
ffmpeg -i $input -ss 00:00:03 -frames:v 1 thumb/1.jpeg
ffmpeg -i $input -ss 00:00:06 -frames:v 1 thumb/2.jpeg
ffmpeg -i $input -ss 00:00:09 -frames:v 1 thumb/3.jpeg
ffmpeg -i $input -ss 00:00:12 -frames:v 1 thumb/4.jpeg
ffmpeg -i $input -ss 00:00:15 -frames:v 1 thumb/5.jpeg
ffmpeg -i $input -ss 00:00:18 -frames:v 1 thumb/6.jpeg
ffmpeg -i $input -ss 00:00:21 -frames:v 1 thumb/7.jpeg
ffmpeg -i $input -ss 00:00:24 -frames:v 1 thumb/8.jpeg
ffmpeg -i $input -ss 00:00:30 -frames:v 1 thumb/9.jpeg

#ffprobe -show_format "$output"