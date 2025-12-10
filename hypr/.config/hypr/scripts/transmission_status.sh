#!/bin/bash

# Transmission 状态脚本：transmission_status.sh
# 显示当前 Transmission 下载任务数量及总进度

# 获取 Transmission 下载任务信息
STATUS=$(transmission-remote -l 2>/dev/null)

if [ $? -ne 0 ]; then
  # Transmission 未连接或未运行
  exit 0
fi

# 解析任务数量和进度
ACTIVE_TASKS=$(echo "$STATUS" | grep -E "Downloading|Seeding" | wc -l)
TOTAL_TASKS=$(echo "$STATUS" | grep -c "Total:")

# 获取总进度百分比
TOTAL_PROGRESS=$(echo "$STATUS" | grep "Total:" | awk '{print $3}')

# 如果有活跃任务，输出 JSON
if [ "$ACTIVE_TASKS" -gt 0 ]; then
  echo "{\"text\": \"🎬 Transmission: $ACTIVE_TASKS/$TOTAL_TASKS 进度: $TOTAL_PROGRESS\", \"class\": \"transmission\"}"
else
  # 无活跃任务，输出空内容以隐藏模块
  exit 0
fi
