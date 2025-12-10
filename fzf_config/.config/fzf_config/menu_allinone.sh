#!/usr/bin/env bash
# menu_allinone.sh - Comprehensive Function Menu

# Define menu options
options=(
  "Open File"
  "Manage Processes"
  #  "Change Directory"
  "Open Website"
  "Launch Application"
  "Search Wiki"
  "Clipboard Manager"
  "Exit"
)

# Display menu using fzf
choice=$(printf "%s\n" "${options[@]}" | fzf $FZF_OPTS --height=90% --reverse --prompt="Select an action: ")

# Execute corresponding action based on selection
case "$choice" in
"Open File")
  ~/.config/fzf_config/fopen.sh
  notify-send -i /usr/share/icons/font_awesome/regular/folder-open.svg "Operation Complete" "File opened"
  ;;
"Manage Git")
  ~/.config/fzf_config/fgit.sh
  notify-send -i /usr/share/icons/font_awesome/brands/git.svg "Operation Complete" "Git branches managed"
  ;;
"Manage Tasks")
  ~/.config/fzf_config/ftask.sh
  notify-send -i /usr/share/icons/font_awesome/regular/calendar-days.svg "Operation Complete" "Tasks managed"
  ;;
"Manage Processes")
  ~/.config/fzf_config/fkill.sh
  notify-send -i /usr/share/icons/font_awesome/solid/hand-middle-finger.svg "Operation Complete" "Processes managed"
  ;;
# "Change Directory")
#   ~/.config/fzf_config/fbookmark.sh
#   notify-send "Operation Complete" "Directory changed"
#   ;;
"Open Website")
  ~/.config/fzf_config/fweb.sh
  notify-send "Operation Complete" "Website opened"
  ;;
"Launch Application")
  ~/.config/fzf_config/fapp.sh
  notify-send -i /usr/share/icons/font_awesome/brands/app-store-ios.svg "Operation Complete" "Application launched"
  ;;
"Search Wiki")
  ~/.config/fzf_config/fwiki.sh
  notify-send -i /usr/share/icons/font_awesome/solid/book-open.svg "Operation Complete" "Wiki searched"
  ;;
"Clipboard Manager")
  ~/.config/fzf_config/fclipboard.sh
  notify-send -i /usr/share/icons/font_awesome/regular/clipboard.svg "Operation Complete" "Clipboard managed"
  ;;
"Exit")
  exit 0
  ;;
*)
  echo "Unrecognized option"
  ;;
esac
