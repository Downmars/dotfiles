#!/bin/bash

# 获取文件 MIME 类型
mime=$(file --mime-type -b "$1")
echo "1"
# 获取文件大小（可读格式）
file_size=$(du -h "$1" | cut -f1)
echo "2"
# 显示文件信息
file_info="MIME: $mime\nSize: $file_size\n$(file "$1")"

if [[ $mime =~ ^image/ ]]; then
  # 图像文件
  dimensions=$(identify -format "%wx%h" "$1" 2>/dev/null || echo "Unknown dimensions")
  echo -e "$file_info\nDimensions: $dimensions\n\n-----------------------------\n\n$(kitty +kitten icat --width 80 --height 40 "$1" 2>/dev/null || echo "No preview available")"

elif [[ $mime == text/* ]]; then
  # 文本文件
  echo -e "$file_info\n\n-----------------------------\n\n$(bat --style=numbers --color=always "$1" 2>/dev/null || cat "$1")"

elif [[ $mime == application/pdf ]]; then
  # PDF 文件
  echo -e "$file_info\n\n-----------------------------\n\n$(pdftotext -l 1 -nopgbrk "$1" - | head -n 20 || echo "Cannot preview PDF content")"

elif [[ $mime =~ ^video/ ]]; then
  # 视频文件
  video_info=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=duration,width,height,codec_name \
    -of default=noprint_wrappers=1 "$1" 2>/dev/null)
  duration=$(echo "$video_info" | grep "duration" | cut -d= -f2)
  width=$(echo "$video_info" | grep "width" | cut -d= -f2)
  height=$(echo "$video_info" | grep "height" | cut -d= -f2)
  codec=$(echo "$video_info" | grep "codec_name" | cut -d= -f2)
  formatted_duration=$(date -u -d @"$duration" +"%H:%M:%S" 2>/dev/null || echo "${duration}s")

  echo -e "$file_info\nDuration: $formatted_duration\nResolution: ${width}x${height}\nCodec: $codec\n\n-----------------------------\n"

else
  # 其他文件类型
  echo -e "$file_info\n\n-----------------------------\n\n$(file -b "$1")"
fi
