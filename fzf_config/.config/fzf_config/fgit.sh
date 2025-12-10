#!/usr/bin/env bash
# fgit_branch.sh - 使用 fzf 管理 Git 分支

branch=$(git branch --all | grep -v 'HEAD' | fzf --height=40% --prompt="切换分支: " | sed 's/remotes\///' | awk '{print $1}')
if [ -n "$branch" ]; then
  git checkout "$branch"
fi
