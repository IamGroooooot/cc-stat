#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd -P)
SCRIPT_NAME=$(basename "$0")
# shellcheck disable=SC1091
. "$SCRIPT_DIR/scripts/common.sh"

CONFIG_DIR=${CLAUDE_CONFIG_DIR:-"$HOME/.claude"}
TARGET_NAME="statusline.sh"

usage() {
  cat <<'USAGE'
cc-stat doctor

Validates dependencies and verifies your statusLine wiring.

Usage:
  ./doctor.sh [options]

Options:
  --config-dir DIR    Claude Code config dir (default: $CLAUDE_CONFIG_DIR or ~/.claude)
  --target-name NAME  Installed script filename (default: statusline.sh)
  --script-name NAME  Alias of --target-name
  --help, -h          Show help

Examples:
  ./doctor.sh
  ./doctor.sh --config-dir ~/.my-claude
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --config-dir)
      ensure_value "$1" "$#" "$SCRIPT_NAME"
      CONFIG_DIR=$2
      shift 2
      ;;
    --target-name|--script-name)
      ensure_value "$1" "$#" "$SCRIPT_NAME"
      TARGET_NAME=$2
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      unknown_option "$1" "$SCRIPT_NAME"
      ;;
  esac
done

case "$TARGET_NAME" in
  */*) die "--target-name/--script-name must be a file name, not a path." ;;
esac

if [ ! -d "$CONFIG_DIR" ]; then
  warn "Config directory does not exist: $CONFIG_DIR"
  warn "Run '$SCRIPT_DIR/install.sh' to install cc-stat first."
  exit 1
fi

CONFIG_DIR_ABS=$(abs_path "$CONFIG_DIR") || die "Unable to resolve config dir: $CONFIG_DIR"
SCRIPT_PATH="$CONFIG_DIR_ABS/$TARGET_NAME"
SCRIPT_PATH_COMPARE=$(normalize_path_if_exists "$SCRIPT_PATH")
SETTINGS_PATH="$CONFIG_DIR_ABS/settings.json"

EXIT_CODE=0

if command -v jq >/dev/null 2>&1; then
  log "[ok] jq is installed"
else
  warn "jq is missing (required for cc-stat)"
  warn "Install jq and rerun doctor."
  EXIT_CODE=1
fi

if command -v claude >/dev/null 2>&1; then
  log "[ok] claude command found"
else
  warn "'claude' command not found (Claude Code may not be installed in PATH)"
fi

if [ -x "$SCRIPT_PATH" ]; then
  log "[ok] statusline script exists: $SCRIPT_PATH"
else
  warn "statusline script missing or not executable: $SCRIPT_PATH"
  EXIT_CODE=1
fi

if [ -f "$SETTINGS_PATH" ]; then
  log "[ok] settings.json exists: $SETTINGS_PATH"

  if command -v jq >/dev/null 2>&1; then
    if jq -e . "$SETTINGS_PATH" >/dev/null 2>&1; then
      configured_cmd=$(jq -r '.statusLine.command // empty' "$SETTINGS_PATH")
      configured_cmd_compare=$(normalize_path_if_exists "$configured_cmd")

      if [ -z "$configured_cmd" ]; then
        warn "settings.json has no statusLine.command"
        EXIT_CODE=1
      elif [ "$configured_cmd_compare" = "$SCRIPT_PATH_COMPARE" ]; then
        log "[ok] statusLine.command points to $SCRIPT_PATH"
      else
        warn "statusLine.command points elsewhere: $configured_cmd"
        EXIT_CODE=1
      fi
    else
      warn "settings.json is not valid JSON"
      EXIT_CODE=1
    fi
  fi
else
  warn "settings.json not found: $SETTINGS_PATH"
  EXIT_CODE=1
fi

log ""
if [ "$EXIT_CODE" -eq 0 ]; then
  log "cc-stat doctor: all checks passed."
else
  log "cc-stat doctor: issues detected."
fi

exit "$EXIT_CODE"
