#!/usr/bin/env sh
# Shared helpers for cc-stat maintenance scripts.

log() {
  printf '%s\n' "$*"
}

warn() {
  printf 'Warning: %s\n' "$*" >&2
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage_error() {
  message=$1
  script_name=${2:-$0}
  printf 'Error: %s\n' "$message" >&2
  printf "Run '%s --help' for usage.\n" "$script_name" >&2
  exit 2
}

unknown_option() {
  option=$1
  script_name=${2:-$0}
  usage_error "Unknown option: $option" "$script_name"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "'$1' command is required."
}

require_jq() {
  if command -v jq >/dev/null 2>&1; then
    return
  fi

  cat >&2 <<'EOF_HINT'
Error: jq is required.
Install jq and rerun:
  macOS (Homebrew): brew install jq
  Ubuntu/Debian:    sudo apt install jq
  Fedora/RHEL:      sudo dnf install jq
  Arch Linux:       sudo pacman -S jq
EOF_HINT
  exit 1
}

ensure_value() {
  # Usage: ensure_value "--option" "$#" "$0"
  option=$1
  argc=$2
  script_name=${3:-$0}

  [ "$argc" -ge 2 ] || usage_error "Option $option requires a value (example: $option <value>)." "$script_name"
}

abs_path() {
  target=$1

  if [ -d "$target" ]; then
    (
      cd "$target" >/dev/null 2>&1 || exit 1
      pwd -P
    )
    return
  fi

  parent_dir=$(dirname "$target")
  base_name=$(basename "$target")

  (
    cd "$parent_dir" >/dev/null 2>&1 || exit 1
    printf '%s/%s\n' "$(pwd -P)" "$base_name"
  )
}

normalize_path_if_exists() {
  target=$1

  if [ -e "$target" ]; then
    abs_path "$target"
  else
    printf '%s\n' "$target"
  fi
}

backup_file() {
  file=$1
  [ -f "$file" ] || return 0

  ts=$(date +%Y%m%d-%H%M%S)
  backup_path="${file}.bak.${ts}"
  cp "$file" "$backup_path"
  printf '%s\n' "$backup_path"
}
