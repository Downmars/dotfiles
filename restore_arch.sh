#!/usr/bin/env bash
set -euo pipefail

echo "====== Arch Linux Restore Script ======"

###########################################
# 0. Safety: do not run this script as root
###########################################
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  echo "❌ Do NOT run this script as root."
  echo "   Run it as your normal user (e.g. dm), the script will use sudo where needed."
  exit 1
fi

###########################################
# 1. Dotfiles root directory
###########################################
REPO_DIR="$HOME/.config/dotfiles"

if [ ! -d "$REPO_DIR" ]; then
  echo "❌ Dotfiles directory not found: $REPO_DIR"
  exit 1
fi

cd "$REPO_DIR"
echo "✔ Dotfiles directory: $REPO_DIR"
echo "✔ Current working directory: $(pwd)"

###########################################
# 2. System update (pacman)
###########################################
echo "====== Updating system with pacman ======"
sudo pacman -Syu --noconfirm || {
  echo "⚠ pacman -Syu failed, please check your mirrors or network."
}

###########################################
# 3. Install packages from system/pkglist.txt
###########################################
PKGLIST="$REPO_DIR/system/pkglist.txt"

if [ -f "$PKGLIST" ]; then
  echo "====== Installing packages from system/pkglist.txt ======"
  # Ignore missing packages instead of failing the whole script
  sudo pacman -S --needed --noconfirm - <"$PKGLIST" || {
    echo "⚠ Some packages in pkglist.txt could not be installed (missing or AUR-only)."
    echo "  This is usually normal. You can install them manually later if needed."
  }
else
  echo "⚠ No pkglist.txt found at $PKGLIST, skipping pacman package restore."
fi

###########################################
# 4. Restore dotfiles with stow
#    IMPORTANT: target (-t) must be $HOME
###########################################
echo "====== Restoring dotfiles using stow ======"

MODULES=(
  "zsh"
  "nvim"
  "kitty"
  "hypr"
  "waybar"
  "fzf_config"
)

for pkg in "${MODULES[@]}"; do
  if [ ! -d "$REPO_DIR/$pkg" ]; then
    echo "⚠ Skipping module '$pkg' (directory not found in $REPO_DIR)"
    continue
  fi

  echo "→ Restoring module: $pkg"

  # Special case: nvim may already exist as a real directory
  if [ "$pkg" = "nvim" ] && [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
    echo "  ⚠ Detected existing real directory: ~/.config/nvim"
    echo "    Stow will NOT overwrite it automatically."
    echo "    If you want to use dotfiles version, backup and remove it first, e.g.:"
    echo "      mv ~/.config/nvim ~/.config/nvim_backup_$(date +%Y%m%d)"
    echo "    Then rerun this script."
    continue
  fi

  # Try to unstow old links (safe if they don't exist)
  stow -t "$HOME" -D "$pkg" 2>/dev/null || true

  # Now stow the module
  if ! stow -t "$HOME" "$pkg"; then
    echo "  ❌ Failed to stow module '$pkg'."
    echo "    Most likely there are existing files or directories conflicting with stow."
    echo "    Please check related paths under ~ or ~/.config and clean them manually."
  else
    echo "  ✔ Module '$pkg' stowed successfully."
  fi
done

echo "====== All done. You may want to re-login or restart your session. ======"
