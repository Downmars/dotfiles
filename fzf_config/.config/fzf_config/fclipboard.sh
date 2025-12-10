#!/bin/bash
# 定义预览命令
preview_cmd='
    cliphist decode {} > /tmp/clip_content; \
    mime_type=$(file -b --mime-type /tmp/clip_content); \
    if [[ "$mime_type" == image/* ]]; then \
        chafa --clear -s 80 /tmp/clip_content; \
    else \
        bat --style=numbers --color=always /tmp/clip_content; \
    fi
'

# 主执行部分
selected_clip=$(cliphist list | fzf --no-sort \
  --preview "$preview_cmd" \
  --preview-window=right:50%:wrap \
  --border \
  --ansi)

# 提取 clip_id，假设 clip_id 是第一列
clip_id=$(echo "$selected_clip" | awk '{print $1}')

# 如果选择了内容，则复制到剪贴板并发送通知
if [ -n "$clip_id" ]; then
  cliphist decode "$clip_id" | wl-copy
fi
