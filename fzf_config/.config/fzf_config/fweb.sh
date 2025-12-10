#!/usr/bin/env bash
# fweb.sh - Use fzf to Select and Open Websites

# Define default search engine
SEARCH_ENGINE="https://www.google.com/search?q="

# Define predefined websites list file
WEBSITES_FILE="$HOME/.config/fzf_config/.fweb_websites"

# Check if predefined websites list file exists
if [ ! -f "$WEBSITES_FILE" ]; then
  echo "Predefined websites list file not found: $WEBSITES_FILE"
  exit 1
fi

# Read predefined websites list
# Assuming each line format is: Name<tab>URL
WEBSITES=$(awk -F'\t' '{print $1 "\t" $2}' "$WEBSITES_FILE")

# Add custom options
OPTIONS=$(echo -e "$WEBSITES\n---\nCustom URL\nSearch...")

# Display menu using fzf
CHOICE=$(echo "$OPTIONS" | fzf --height=40% --reverse --prompt="Select a website: " --delimiter='\t' --with-nth=1 --preview='echo {1}')

# Check if user canceled selection
if [ -z "$CHOICE" ]; then
  exit 0
fi

# Handle user selection
case "$CHOICE" in
"---")
  # Separator, do nothing
  exit 0
  ;;
"Custom URL")
  # Prompt user to enter a custom URL
  read -p "Enter URL (including http:// or https://): " URL
  # Simple URL format validation
  if [[ "$URL" =~ ^https?:// ]]; then
    nohup xdg-open "$URL" >/dev/null 2>&1 &
  else
    # If no protocol prefix, default to adding http://
    nohup xdg-open "http://$URL" >/dev/null 2>&1 &
  fi
  ;;
"Search...")
  # Prompt user to enter search keywords
  read -p "Enter search query: " QUERY
  # Perform search using default search engine
  # URL-encode the search query
  ENCODED_QUERY=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$QUERY")
  nohup xdg-open "${SEARCH_ENGINE}${ENCODED_QUERY}" >/dev/null 2>&1 &
  disown
  ;;
*)
  # Handle predefined website selection
  # Split name and URL using tab
  URL=$(echo -e "$CHOICE" | awk -F'\t' '{print $2}')
  nohup xdg-open "$URL" >/dev/null 2>&1 &
  disown
  ;;
esac
