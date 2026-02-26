#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd -P)
SCRIPT_NAME=$(basename "$0")
# shellcheck disable=SC1091
. "$SCRIPT_DIR/scripts/common.sh"

CONFIG_DIR=${CLAUDE_CONFIG_DIR:-"$HOME/.claude"}
TARGET_NAME="statusline.sh"
REMOVE_ANY_STATUSLINE=0
DRY_RUN=0
BACKUP=1

usage() {
  cat <<'USAGE'
cc-stat uninstaller

Removes the installed statusline script and/or statusLine config key.

Usage:
  ./uninstall.sh [options]

Options:
  --config-dir DIR          Claude Code config dir (default: $CLAUDE_CONFIG_DIR or ~/.claude)
  --target-name NAME        Installed script filename (default: statusline.sh)
  --script-name NAME        Alias of --target-name
  --remove-any-statusline   Remove statusLine even if command path is different
  --all-statusline          Alias of --remove-any-statusline
  --dry-run                 Print planned actions without modifying files
  --no-backup               Do not create settings.json backup before edit
  --help, -h                Show help

Examples:
  ./uninstall.sh
  ./uninstall.sh --config-dir ~/.my-claude
  ./uninstall.sh --all-statusline --dry-run
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
    --remove-any-statusline|--all-statusline)
      REMOVE_ANY_STATUSLINE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --no-backup)
      BACKUP=0
      shift
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
  log "Nothing to uninstall (config dir not found): $CONFIG_DIR"
  exit 0
fi

CONFIG_DIR_ABS=$(abs_path "$CONFIG_DIR") || die "Unable to resolve config directory path: $CONFIG_DIR"
SCRIPT_PATH="$CONFIG_DIR_ABS/$TARGET_NAME"
SCRIPT_PATH_COMPARE=$(normalize_path_if_exists "$SCRIPT_PATH")
SETTINGS_PATH="$CONFIG_DIR_ABS/settings.json"

if [ -f "$SCRIPT_PATH" ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    log "[dry-run] Would remove script: $SCRIPT_PATH"
  else
    rm -f "$SCRIPT_PATH"
    log "Removed script: $SCRIPT_PATH"
  fi
else
  log "Script already absent: $SCRIPT_PATH"
fi

if [ ! -f "$SETTINGS_PATH" ]; then
  log "settings.json not found, skipping settings cleanup: $SETTINGS_PATH"
  log ""
  log "cc-stat uninstall complete."
  exit 0
fi

require_jq
jq -e . "$SETTINGS_PATH" >/dev/null 2>&1 || die "settings.json is not valid JSON: $SETTINGS_PATH"

has_statusline=$(jq -r 'has("statusLine")' "$SETTINGS_PATH")
if [ "$has_statusline" != "true" ]; then
  log "statusLine key not present in settings.json"
  log ""
  log "cc-stat uninstall complete."
  exit 0
fi

should_remove=0
if [ "$REMOVE_ANY_STATUSLINE" -eq 1 ]; then
  should_remove=1
else
  configured_cmd=$(jq -r '.statusLine.command // empty' "$SETTINGS_PATH")
  configured_cmd_compare=$(normalize_path_if_exists "$configured_cmd")

  if [ "$configured_cmd_compare" = "$SCRIPT_PATH_COMPARE" ]; then
    should_remove=1
  else
    warn "statusLine.command points to a different script: $configured_cmd"
    warn "Use --remove-any-statusline (or --all-statusline) if you still want to remove statusLine."
  fi
fi

if [ "$should_remove" -eq 1 ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    log "[dry-run] Would remove statusLine from: $SETTINGS_PATH"
  else
    if [ "$BACKUP" -eq 1 ]; then
      backup_path=$(backup_file "$SETTINGS_PATH")
      [ -n "$backup_path" ] && log "Backed up settings: $backup_path"
    fi

    tmp_file=$(mktemp "$CONFIG_DIR_ABS/.settings.json.tmp.XXXXXX")
    cleanup() {
      [ -n "${tmp_file:-}" ] && [ -f "$tmp_file" ] && rm -f "$tmp_file"
    }
    trap cleanup EXIT INT TERM

    jq 'del(.statusLine)' "$SETTINGS_PATH" > "$tmp_file"
    mv "$tmp_file" "$SETTINGS_PATH"
    trap - EXIT INT TERM

    log "Removed statusLine from: $SETTINGS_PATH"
  fi
fi

log ""
log "cc-stat uninstall complete."
