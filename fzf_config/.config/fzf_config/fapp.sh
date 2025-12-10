#!/usr/bin/env bash
# fapp.sh - 使用 fzf 作为应用启动器（同名优先使用用户目录）

set -euo pipefail

# 目录优先级：用户目录在前，系统目录在后
APP_DIRS=(
  "$HOME/.local/share/applications"
  "/usr/share/applications"
)

declare -A APP_MAP # key: basename(应用条目)  value: fullpath

# 收集 .desktop 与 .AppImage，按优先级写入 APP_MAP（先到先得）
for dir in "${APP_DIRS[@]}"; do
  [[ -d "$dir" ]] || continue
  # -print0 防止空格/特殊字符问题
  while IFS= read -r -d '' f; do
    base="$(basename "$f")"
    # 只在第一次出现时记录（用户目录会先写入，从而“盖住”系统目录的同名条目）
    [[ -n "${APP_MAP[$base]-}" ]] || APP_MAP["$base"]="$f"
  done < <(find "$dir" -maxdepth 1 -type f \( -name "*.desktop" -o -name "*.AppImage" \) -print0 2>/dev/null)
done

# 如果一个都没找到，直接退
((${#APP_MAP[@]} > 0)) || {
  echo "No apps found."
  exit 1
}

# 列出键名给 fzf 选择（可按需加 sort）
selected="$(printf '%s\n' "${!APP_MAP[@]}" | sort | fzf --height=40% --reverse --prompt='Launch Applications: ' | head -n 1)"

[[ -n "${selected:-}" ]] || exit 0

fullpath="${APP_MAP[$selected]}"

# 根据类型执行
if [[ "$fullpath" == *.desktop ]]; then
  # 你原来使用 rundesktop，这里保留；若使用 dex 也可替换为:
  # nohup dex "$fullpath" >/dev/null 2>&1 &
  nohup dex "$fullpath" >/dev/null 2>&1 &
elif [[ "$fullpath" == *.AppImage ]]; then
  chmod +x "$fullpath"
  nohup "$fullpath" >/dev/null 2>&1 &
fi
