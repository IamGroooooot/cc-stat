#!/usr/bin/env bash
set -euo pipefail

# cc-stat installer
# Installs the custom statusline for Claude Code
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/user/cc-stat/main/install.sh | bash
#   # or
#   ./install.sh
#   ./install.sh --config-dir ~/.my-claude   # custom config dir

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config-dir) CONFIG_DIR="$2"; shift 2 ;;
    --help|-h)
      echo "cc-stat installer"
      echo ""
      echo "Usage: ./install.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --config-dir DIR   Claude Code config directory (default: ~/.claude)"
      echo "  --help, -h         Show this help"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# Preflight checks
# ---------------------------------------------------------------------------
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed."
  echo "  macOS:  brew install jq"
  echo "  Ubuntu: sudo apt install jq"
  echo "  Arch:   sudo pacman -S jq"
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo "Warning: 'claude' command not found. Is Claude Code installed?"
fi

# ---------------------------------------------------------------------------
# Install statusline script
# ---------------------------------------------------------------------------
mkdir -p "$CONFIG_DIR"

DEST="$CONFIG_DIR/statusline.sh"

# If running from repo clone, copy from local; otherwise download
if [[ -f "$SCRIPT_DIR/statusline.sh" ]]; then
  cp "$SCRIPT_DIR/statusline.sh" "$DEST"
else
  echo "Downloading statusline.sh..."
  curl -fsSL "https://raw.githubusercontent.com/user/cc-stat/main/statusline.sh" -o "$DEST"
fi

chmod +x "$DEST"

# ---------------------------------------------------------------------------
# Update settings.json (merge statusLine key, preserve existing settings)
# ---------------------------------------------------------------------------
SETTINGS="$CONFIG_DIR/settings.json"

# statusLine config to inject
SL_JSON=$(cat <<EOJSON
{
  "statusLine": {
    "type": "command",
    "command": "$DEST",
    "padding": 0
  }
}
EOJSON
)

if [[ -f "$SETTINGS" ]]; then
  # Merge: existing settings + statusLine (statusLine wins on conflict)
  MERGED=$(jq -s '.[0] * .[1]' "$SETTINGS" <(echo "$SL_JSON"))
  echo "$MERGED" > "$SETTINGS"
else
  echo "$SL_JSON" | jq '.' > "$SETTINGS"
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
echo "  cc-stat installed successfully!"
echo ""
echo "  Config dir : $CONFIG_DIR"
echo "  Script     : $DEST"
echo "  Settings   : $SETTINGS"
echo ""
echo "  Restart Claude Code to see the new status line."
echo ""
