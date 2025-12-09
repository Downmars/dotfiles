#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$HOME/dotfiles"
SYSTEM_DIR="$REPO_DIR/system"
PACMAN_LIST="$SYSTEM_DIR/pkglist.txt"
AUR_LIST="$SYSTEM_DIR/aurlist.txt"

DOTFILES_MODULES=(zsh kitty hypr waybar nvim fzf_config)

echo "=== Arch 恢复脚本启动 ==="

# 0. 基本检查
if [[ ! -f /etc/arch-release ]]; then
  echo "本脚本仅适用于 Arch / Arch-based 系统，已退出。"
  exit 1
fi

if [[ ! -d "$REPO_DIR" ]]; then
  echo "找不到目录：$REPO_DIR"
  echo "请先：git clone <你的仓库> ~/dotfiles"
  exit 1
fi

if [[ ! -f "$PACMAN_LIST" ]]; then
  echo "找不到 pacman 包列表：$PACMAN_LIST"
  exit 1
fi

echo "dotfiles 目录：$REPO_DIR"
echo "system 目录：  $SYSTEM_DIR"
echo

# 1. 更新系统 & 安装基础工具
echo "=== [1/5] 更新系统 & 安装基础工具（git / stow / base-devel） ==="
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm git stow base-devel

# 2. 安装 pacman 软件包
echo
echo "=== [2/5] 安装 pacman 软件包（来自 pkglist.txt） ==="
sudo pacman -S --needed - <"$PACMAN_LIST" || {
  echo "安装 pacman 包时出现错误，请检查网络或 pkglist.txt"
}

# 3. 安装 / 准备 yay，然后安装 AUR 包
echo
echo "=== [3/5] 安装 AUR 助手 yay（如果尚未安装） ==="
if ! command -v yay >/dev/null 2>&1; then
  echo "未检测到 yay，开始安装..."
  tmpdir="$(mktemp -d)"
  pushd "$tmpdir" >/dev/null
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  popd >/dev/null
  rm -rf "$tmpdir"
else
  echo "已检测到 yay，跳过安装。"
fi

if [[ -f "$AUR_LIST" ]]; then
  echo
  echo "=== [3.1/5] 安装 AUR 软件包（来自 aurlist.txt） ==="
  yay -S --needed - <"$AUR_LIST" || {
    echo "安装 AUR 包时出错，可以稍后手动重试：yay -S --needed - < $AUR_LIST"
  }
else
  echo "未找到 AUR 列表：$AUR_LIST，跳过 AUR 包安装。"
fi

# 4. 使用 stow 恢复 dotfiles
echo
echo "=== [4/5] 使用 stow 恢复 dotfiles ==="
cd "$REPO_DIR"

for module in "${DOTFILES_MODULES[@]}"; do
  if [[ ! -d "$REPO_DIR/$module" ]]; then
    echo "  - 模块 $module 不存在，跳过。"
    continue
  fi

  # 简单冲突检查：如果目标不是 symlink，先提示用户自己处理
  case "$module" in
  zsh)
    target="$HOME/.config/zshrc"
    ;;
  fzf_config)
    target="$HOME/.config/fzf_config"
    ;;
  *)
    target="$HOME/.config/$module"
    ;;
  esac

  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "  ⚠ 检测到本地已有非符号链接：$target"
    echo "    建议先备份或删除它，再手动执行：cd $REPO_DIR && stow $module"
    continue
  fi

  echo "  → stow $module"
  stow "$module"
done

# 5. （可选）恢复部分 /etc 配置（谨慎）
echo
echo "=== [5/5] 可选：恢复 system/ 下的系统配置文件（不会强制覆盖） ==="

restore_file() {
  local src="$1"
  local dst="$2"
  local name="$3"

  if [[ ! -f "$src" ]]; then
    echo "  - 跳过 $name（$src 不存在）"
    return
  fi

  if [[ -f "$dst" ]]; then
    echo "  - $name 已存在于 $dst，跳过覆盖。"
  else
    echo "  → 恢复 $name 到 $dst"
    sudo cp "$src" "$dst"
  fi
}

restore_file "$SYSTEM_DIR/fstab" "/etc/fstab" "fstab"
restore_file "$SYSTEM_DIR/hostname" "/etc/hostname" "hostname"
restore_file "$SYSTEM_DIR/locale.conf" "/etc/locale.conf" "locale.conf"
restore_file "$SYSTEM_DIR/locale.gen" "/etc/locale.gen" "locale.gen"
restore_file "$SYSTEM_DIR/mkinitcpio.conf" "/etc/mkinitcpio.conf" "mkinitcpio.conf"
restore_file "$SYSTEM_DIR/environment" "/etc/environment" "environment"
restore_file "$SYSTEM_DIR/hosts" "/etc/hosts" "hosts"
restore_file "$SYSTEM_DIR/vconsole.conf" "/etc/vconsole.conf" "vconsole.conf"

echo
echo "=== 恢复完成（部分 /etc 文件如果已存在会被保留原样）。==="
echo "如需重新生成 initramfs，请手动执行：sudo mkinitcpio -P"
echo "如修改了 locale.gen，请执行：sudo locale-gen"
echo "如修改了主机名，请确认 /etc/hosts 同步更新。"
echo
echo "Done 🎉"
