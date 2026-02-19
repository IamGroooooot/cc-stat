#!/usr/bin/env bash
set -euo pipefail

# cc-stat uninstaller
# Removes the custom statusline from Claude Code settings

CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config-dir) CONFIG_DIR="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

SETTINGS="$CONFIG_DIR/settings.json"
SCRIPT="$CONFIG_DIR/statusline.sh"

# Remove script file
if [[ -f "$SCRIPT" ]]; then
  rm "$SCRIPT"
  echo "Removed: $SCRIPT"
fi

# Remove statusLine key from settings.json
if [[ -f "$SETTINGS" ]]; then
  UPDATED=$(jq 'del(.statusLine)' "$SETTINGS")
  echo "$UPDATED" > "$SETTINGS"
  echo "Removed statusLine from: $SETTINGS"
fi

echo ""
echo "  cc-stat uninstalled. Restart Claude Code to apply."
echo ""
