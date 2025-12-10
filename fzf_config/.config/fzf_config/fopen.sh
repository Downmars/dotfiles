#!/usr/bin/env bash
#!/usr/bin/env bash
# fopen_fd_bat.sh - 使用 fd 和 bat 快速打开文件，根据文件的 MIME 类型使用不同的工具，通过配置文件管理映射
set -euo pipefail

# 启用命令跟踪：在执行每条命令前会打印该命令
# set -x
# 配置文件路径
CONFIG_FILE="$HOME/.config/fzf_config/fopen_config/fopen_mime.conf"

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Configuration file not found: $CONFIG_FILE"
  exit 1
fi

# 检查所需工具是否已安装
required_tools=(fd fzf bat file xsel chafa)
for tool in "${required_tools[@]}"; do
  if ! command -v "$tool" &>/dev/null; then
    echo "Error: $tool is not installed. Please install it and try again."
    exit 1
  fi
done

# 读取配置文件并构建关联数组
declare -A MIME_COMMANDS

while IFS='=' read -r mime_pattern command; do
  # 忽略空行和注释行
  [[ "$mime_pattern" =~ ^#.*$ ]] && continue
  [[ -z "$mime_pattern" || -z "$command" ]] && continue
  # 去除可能的空格
  mime_pattern=$(echo "$mime_pattern" | xargs)
  command=$(echo "$command" | xargs)
  # 添加到关联数组
  MIME_COMMANDS["$mime_pattern"]="$command"
done <"$CONFIG_FILE"

# 默认打开命令
DEFAULT_OPEN_COMMAND="xdg-open"
# echo "3"
# 使用 fd 查找文件，并通过 fzf 选择
selected=$(fd --type f --hidden --follow | fzf --preview '/home/dm/.config/fzf_config/fopen_config/fopen_preview.sh {}' --height=90% --preview-window=right:50%:wrap --layout=default --info=inline)
# echo "4"
# 如果有选择，则根据 MIME 类型打开
if [ -n "$selected" ]; then
  # 获取文件的 MIME 类型
  mime_type=$(file --mime-type -b "$selected")

  # 初始化打开命令为空
  open_cmd=""

  # 遍历配置中的 MIME 类型模式，查找匹配的命令
  for pattern in "${!MIME_COMMANDS[@]}"; do
    # 将模式中的 '*' 转换为正则表达式
    regex="^${pattern//\*/.*}$"
    if [[ "$mime_type" =~ $regex ]]; then
      open_cmd="${MIME_COMMANDS[$pattern]}"
      break
    fi
  done

  # 特殊处理 'nvim' 命令
  if [ "$open_cmd" = "nvim" ]; then
    # 使用 kitty 打开 nvim
    kitty --detach -- nvim "$selected"
    # 退出脚本以关闭原终端
    exit 0
  fi

  # 如果未找到匹配的命令，使用默认命令
  if [ -z "$open_cmd" ]; then
    nohup open_cmd="$DEFAULT_OPEN_COMMAND" >/dev/null 2>&1 &
  fi

  # 检查命令是否是自定义函数
  if declare -F "$open_cmd" >/dev/null; then
    # 调用自定义函数，并将其放入后台运行
    "$open_cmd" "$selected" &
  else
    # 检查命令是否存在
    if command -v "$open_cmd" &>/dev/null; then
      # 使用对应的命令打开文件，并隐藏终端
      nohup "$open_cmd" "$selected" >/dev/null 2>&1 &
      exit 0
    else
      echo "Error: Command '$open_cmd' not found. Please install it or update the configuration file."
      exit 1
    fi
  fi
fi
