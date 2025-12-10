#!/bin/bash

# 检查 /dev/sda2 是否挂载
MOUNT_POINT=$(df -h | grep '/dev/sda2' | awk '{print $6}')

# 如果挂载了 /dev/sda2，返回 JSON 格式的状态
if [ -n "$MOUNT_POINT" ]; then
  # 获取 /dev/sda2 的使用情况
  DISK_USAGE=$(df -h | grep '/dev/sda2' | awk '{print $5}')
  echo "{\"text\": \" $DISK_USAGE\", \"class\": \"mounts\", \"on-click\": \"~/Scripts/unmount.sh\"}"
else
  # 如果未挂载，不显示任何内容
  exit 0
fi
