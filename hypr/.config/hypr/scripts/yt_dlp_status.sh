#!/bin/bash

# yt-dlp 状态脚本：yt_dlp_status.sh
# 显示当前 yt-dlp 下载任务数量

# 获取 yt-dlp 进程数量
YTDLP_COUNT=$(pgrep -fc yt-dlp)

# 如果有活跃下载任务，输出 JSON
if [ "$YTDLP_COUNT" -gt 0 ]; then
  echo "{\"text\": \"🎥 yt-dlp: $YTDLP_COUNT 下载中\", \"class\": \"yt_dlp\"}"
else
  # 无活跃任务，输出空内容以隐藏模块
  exit 0
fi
