#!/bin/bash

STATUS_FILE="/tmp/recording_status"
RECORDING_FLAG="/tmp/recording_flag"

if [ -f "$RECORDING_FLAG" ]; then
  if [ -f "$STATUS_FILE" ]; then
    SECONDS=$(cat "$STATUS_FILE")
    SECONDS=$((SECONDS / 2)) # i donot know why time is two than true.
    HOURS=$((SECONDS / 3600))
    MINUTES=$(((SECONDS % 3600) / 60))
    SECS=$((SECONDS % 60))
    TIME_FORMAT=$(printf "%02d:%02d:%02d" $HOURS $MINUTES $SECS)
  else
    TIME_FORMAT="00:00:00"
  fi

  MODE=$(cat "$RECORDING_FLAG")
  if [ "$MODE" == "全屏录制" ]; then
    MODE_ICON="" # 全屏录制图标，可以根据需要调整
  else
    MODE_ICON="" # 区域录制图标，可以根据需要调整
  fi

  echo "{\"text\": \"$MODE_ICON $TIME_FORMAT\", \"class\": \"recording\"}"
else
  echo "{\"text\": \"\", \"class\": \"\"}"
fi
