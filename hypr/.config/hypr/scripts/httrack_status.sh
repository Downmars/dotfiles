#!/bin/bash

# HTTrack 状态脚本：httrack_status.sh
# 显示当前 HTTrack 下载任务数量

# 获取 HTTrack 下载任务数量，确保只匹配以 'httrack' 开头的进程
HTTRACK_COUNT=$(pgrep -fc "^httrack ")

# 如果有活跃下载任务，输出 JSON
if [ "$HTTRACK_COUNT" -gt 0 ]; then
  echo "{\"text\": \"🌐 HTTrack: $HTTRACK_COUNT 下载中\", \"class\": \"httrack\"}"
else
  # 无活跃任务，输出空内容以隐藏模块
  exit 0
fi
