#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd -P)
SCRIPT_NAME=$(basename "$0")
# shellcheck disable=SC1091
. "$SCRIPT_DIR/scripts/common.sh"

CONFIG_DIR=${CLAUDE_CONFIG_DIR:-"$HOME/.claude"}
TARGET_NAME="statusline.sh"
SOURCE_SCRIPT="$SCRIPT_DIR/statusline.sh"
FORCE=0
DRY_RUN=0
BACKUP=1

usage() {
  cat <<'USAGE'
cc-stat installer

Install/updates a statusline script and merges statusLine into settings.json.

Usage:
  ./install.sh [options]

Options:
  --config-dir DIR         Claude Code config dir (default: $CLAUDE_CONFIG_DIR or ~/.claude)
  --target-name NAME       Installed script filename (default: statusline.sh)
  --script-name NAME       Alias of --target-name
  --source FILE            Source script path (default: ./statusline.sh)
  --source-script FILE     Alias of --source
  --force                  Overwrite an existing installed script
  --dry-run                Print planned actions without modifying files
  --no-backup              Do not create settings.json backup before edit
  --help, -h               Show help

Examples:
  ./install.sh
  ./install.sh --config-dir ~/.my-claude --script-name team-status.sh
  ./install.sh --source ./custom-statusline.sh --force
  ./install.sh --dry-run
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
    --source|--source-script)
      ensure_value "$1" "$#" "$SCRIPT_NAME"
      SOURCE_SCRIPT=$2
      shift 2
      ;;
    --force)
      FORCE=1
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

[ -f "$SOURCE_SCRIPT" ] || die "Source statusline script not found: $SOURCE_SCRIPT"
SOURCE_SCRIPT_ABS=$(abs_path "$SOURCE_SCRIPT") || die "Unable to resolve source script path: $SOURCE_SCRIPT"

require_jq
if ! command -v claude >/dev/null 2>&1; then
  warn "'claude' command not found in PATH. Install still works, but verify Claude Code setup."
fi

if [ -d "$CONFIG_DIR" ]; then
  CONFIG_DIR_ABS=$(abs_path "$CONFIG_DIR") || die "Unable to resolve config directory path: $CONFIG_DIR"
else
  if [ "$DRY_RUN" -eq 1 ]; then
    log "[dry-run] Would create config directory: $CONFIG_DIR"
    CONFIG_DIR_ABS=$CONFIG_DIR
  else
    mkdir -p "$CONFIG_DIR"
    CONFIG_DIR_ABS=$(abs_path "$CONFIG_DIR") || die "Unable to resolve config directory path: $CONFIG_DIR"
    log "Created config directory: $CONFIG_DIR_ABS"
  fi
fi

DEST="$CONFIG_DIR_ABS/$TARGET_NAME"
SETTINGS="$CONFIG_DIR_ABS/settings.json"

if [ -e "$DEST" ] && [ "$FORCE" -ne 1 ]; then
  if cmp -s "$SOURCE_SCRIPT_ABS" "$DEST"; then
    log "Statusline script already up to date: $DEST"
  else
    die "Destination already exists: $DEST (use --force to overwrite)."
  fi
fi

if [ "$DRY_RUN" -eq 1 ]; then
  log "[dry-run] Would copy: $SOURCE_SCRIPT_ABS -> $DEST"
else
  cp "$SOURCE_SCRIPT_ABS" "$DEST"
  chmod 755 "$DEST"
  log "Installed statusline script: $DEST"
fi

if [ -f "$SETTINGS" ]; then
  jq -e . "$SETTINGS" >/dev/null 2>&1 || die "settings.json is not valid JSON: $SETTINGS"
fi

if [ "$DRY_RUN" -eq 1 ]; then
  log "[dry-run] Would update: $SETTINGS"
else
  if [ "$BACKUP" -eq 1 ] && [ -f "$SETTINGS" ]; then
    backup_path=$(backup_file "$SETTINGS")
    [ -n "$backup_path" ] && log "Backed up settings: $backup_path"
  fi

  tmp_file=$(mktemp "$CONFIG_DIR_ABS/.settings.json.tmp.XXXXXX")
  cleanup() {
    [ -n "${tmp_file:-}" ] && [ -f "$tmp_file" ] && rm -f "$tmp_file"
  }
  trap cleanup EXIT INT TERM

  if [ -f "$SETTINGS" ]; then
    jq --arg cmd "$DEST" '. + {"statusLine":{"type":"command","command":$cmd,"padding":0}}' "$SETTINGS" > "$tmp_file"
  else
    jq -n --arg cmd "$DEST" '{"statusLine":{"type":"command","command":$cmd,"padding":0}}' > "$tmp_file"
  fi

  mv "$tmp_file" "$SETTINGS"
  trap - EXIT INT TERM
  log "Updated settings: $SETTINGS"
fi

cat <<EOF_SUMMARY

cc-stat installed successfully.

Config directory : $CONFIG_DIR_ABS
Script path      : $DEST
Settings path    : $SETTINGS

Next steps:
  1) Restart Claude Code
  2) Run "$SCRIPT_DIR/doctor.sh" --config-dir "$CONFIG_DIR_ABS" to verify setup
EOF_SUMMARY
