#!/bin/bash

#
# Script name: fzf-wiki.sh
# Description: Search and open offline copies of various Wikis using fzf with modified display names.
# Dependencies: fzf, xdg-open, sed, bat
# GitLab: https://www.gitlab.com/dwt1/dmscripts
# License: https://www.gitlab.com/dwt1/dmscripts/LICENSE
# Contributors: Derek Taylor
#               marvhus
#

# 设置错误处理
set -euo pipefail

# 定义缓存目录
CACHE_DIR="$HOME/.cache/fzf-wiki"

# 创建缓存目录（如果不存在）
mkdir -p "$CACHE_DIR"

# 定义 Wiki 名称到路径的映射
declare -A wiki_paths=(
  ["archlinux"]="$HOME/Wiki/archlinux.org/html/en/"
  ["taskwarrior"]="$HOME/Wiki/taskwarrior.org/docs/"
  ["lazy_vim"]="$HOME/Wiki/www.lazyvim.org/"
  ["yak_mkdocs"]="$HOME/Wiki/yakworks.github.io/docmark/"
  ["hyprland"]="$HOME/Wiki/wiki.hyprland.org/"
  ["fzf"]="$HOME/Wiki/github.com/junegunn/fzf/wiki/"
  ["neovim"]="$HOME/Wiki/neovim.io/doc/user/"
  ["hugo_zh"]="$HOME/Wiki/hugo.opendocs.io/getting-started/"
  # 在此处添加更多的 Wiki 名称和路径
  # ["wiki_name"]="$HOME/Wiki/wiki_name/path/"
)

# 使用 fzf 选择 Wiki 名称
select_wiki() {
  # 获取所有 Wiki 名称
  wikis=("${!wiki_paths[@]}")

  # 使用 fzf 进行选择
  choice=$(printf '%s\n' "${wikis[@]}" |
    fzf --prompt="Select Wiki: " --height=90% --reverse --border) || {
    echo "Program terminated."
    exit 0
  }

  # 如果选择为空，退出程序
  if [ -z "$choice" ]; then
    echo "Program terminated."
    exit 0
  fi

  # 获取对应的路径
  wikidir="${wiki_paths[$choice]}"

  # 检查路径是否存在
  if [ ! -d "$wikidir" ]; then
    echo "Error: Wiki directory '$wikidir' does not exist."
    exit 1
  fi

  echo "Selected Wiki: $choice"
  echo "Path: $wikidir"

  # 继续执行文件选择
  select_html "$choice" "$wikidir"
}

# 使用 fzf 选择 HTML 文件
select_html() {
  local wiki_name="$1"
  local wikidir="$2"

  # 定义缓存文件路径
  local cache_file="$CACHE_DIR/${wiki_name}.cache"

  # 检查缓存是否存在且是否最新
  if [ -f "$cache_file" ]; then
    # 比较缓存文件和目录的修改时间
    if [ "$cache_file" -nt "$wikidir" ]; then
      # 缓存是最新的
      cached=true
    else
      # 缓存过时，需要重新生成
      cached=false
    fi
  else
    # 缓存不存在
    cached=false
  fi

  if [ "$cached" != true ]; then
    echo "Generating cache for '$wiki_name'..."
    generate_cache "$wikidir" "$cache_file"
  fi

  # 读取缓存文件
  file_list=()
  while IFS=$'\t' read -r display_name file; do
    file_list+=("$display_name"$'\t'"$file")
  done <"$cache_file"

  if [ ${#file_list[@]} -eq 0 ]; then
    echo "No HTML documentation found in '$wikidir'."
    exit 1
  fi

  # 使用 fzf 进行选择
  choice=$(printf '%s\n' "${file_list[@]}" |
    fzf --delimiter ' ' --with-nth=1 --preview 'bat --style=numbers --color=always {2}' --prompt="Select Article: " --height=90% --reverse --border) || exit 1

  # 提取实际文件路径
  article=$(echo "$choice" | awk -F' ' '{print $2}')

  # 检查文件是否存在
  if [ -f "$article" ]; then
    # 使用默认浏览器打开文章
    nohup xdg-open "$article" >/dev/null 2>&1 &
    echo "Opened '$article'"
  else
    echo "Selected article '$article' does not exist."
    exit 1
  fi
}

# 生成缓存文件
generate_cache() {
  local wikidir="$1"
  local cache_file="$2"

  # 查找所有 HTML 文件并生成文件列表
  mapfile -d '' wikidocs < <(find "$wikidir" -type f -iname "*.html" -print0)

  # 清空或创建缓存文件
  >"$cache_file"

  for file in "${wikidocs[@]}"; do
    # 生成相对路径
    relative_path="${file#$wikidir}"

    # 生成显示名称
    if [[ "$(basename "$file")" == "index.html" ]]; then
      # 将路径中的 '/' 替换为 '_'，并将 '_index.html' 替换为 '.html'
      display_name=$(echo "$relative_path" | sed 's/\//_/g' | sed 's/_index\.html$/.html/')
    else
      # 将路径中的 '/' 替换为 '_'
      display_name=$(echo "$relative_path" | sed 's/\//_/g' | sed 's/\.html$//')
      # 添加原始文件名的后缀
      display_name="${display_name}.html"
    fi

    # 组合显示名称和实际路径，用制表符分隔
    echo -e "${display_name} ${file}" >>"$cache_file"
  done

  echo "Cache generated at '$cache_file'"
}

# 启动脚本
select_wiki
