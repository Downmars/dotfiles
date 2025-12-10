#!/usr/bin/env bash
# fkill_htop.sh - 使用 fzf 选择并杀死进程

process=$(ps aux | fzf --height=90% --reverse --preview 'echo {}' | awk '{print $2}')
if [ -n "$process" ]; then
  kill -9 "$process"
fi
