#!/bin/bash

PORT=8080
# create a unique directory
OUTPUT_DIR=$(date '+%m-%d-%y-%T')
OUTPUT_SEG_NAME='test_pattern_live_video'

[ -e pipe0 ] && rm pipe0
mkfifo pipe0

# encode with FFMPEG
X264_ENC='libx264 -tune zerolatency -profile:v high -preset ultrafast -bf 0 -refs 3 -sc_threshold 0'

ffmpeg \
    -hide_banner \
    -re \
    -f lavfi \
    -i "testsrc2=size=1920x1080:rate=30" \
    -pix_fmt yuv420p \
    -map 0:v \
    -c:v ${X264_ENC} \
    -g 150 \
    -keyint_min 150 \
    -b:v 4000k \
    -vf "fps=30" \
    -f mpegts \
    pipe: > pipe0 &

# package as DASH
packager \
   --io_block_size 65536 \
   in=pipe0,stream=video,init_segment='http://0.0.0.0:'${PORT}'/'${OUTPUT_DIR}'/'${OUTPUT_SEG_NAME}'_init.m4s',segment_template='http://0.0.0.0:'${PORT}'/'${OUTPUT_DIR}'/'${OUTPUT_SEG_NAME}'_$Number$.m4s' \
   --segment_duration 5 \
   --mpd_output "http://0.0.0.0:${PORT}/${OUTPUT_DIR}/manifest.mpd" \
    >& log.log
   
rm pipe0
