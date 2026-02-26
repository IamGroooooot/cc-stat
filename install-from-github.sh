#!/usr/bin/env sh
set -eu

# Install cc-stat directly from GitHub without pre-cloning the repo.

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd -P)
SCRIPT_NAME=$(basename "$0")

REPO=""
REF="latest"
CONFIG_DIR=${CLAUDE_CONFIG_DIR:-"$HOME/.claude"}
TARGET_NAME="statusline.sh"
FORCE=0
DRY_RUN=0

usage() {
  cat <<'USAGE'
Install cc-stat from GitHub

Downloads a GitHub tarball and runs the project's install script.

Usage:
  ./install-from-github.sh [options]

Options:
  --repo OWNER/REPO    GitHub repository (if omitted, tries current git remote)
  --ref REF            Git ref (default: latest release tag)
                       Examples: v1.2.0, main, <commit-sha>
  --config-dir DIR     Claude Code config dir (default: $CLAUDE_CONFIG_DIR or ~/.claude)
  --target-name NAME   Installed script filename (default: statusline.sh)
  --script-name NAME   Alias of --target-name
  --force              Overwrite existing installed script
  --dry-run            Print planned actions without downloading/installing
  --help, -h           Show help

Examples:
  ./install-from-github.sh --repo your-org/cc-stat
  ./install-from-github.sh --repo your-org/cc-stat --ref v1.2.3
  ./install-from-github.sh --repo your-org/cc-stat --ref main --force
USAGE
}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

usage_error() {
  message=$1
  printf 'Error: %s\n' "$message" >&2
  printf "Run '%s --help' for usage.\n" "$SCRIPT_NAME" >&2
  exit 2
}

note() {
  printf '%s\n' "$*"
}

ensure_value() {
  [ "$2" -ge 2 ] || usage_error "Option $1 requires a value (example: $1 <value>)."
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "'$1' command is required."
}

infer_repo_from_git() {
  if ! command -v git >/dev/null 2>&1; then
    return 1
  fi

  remote_url=$(git -C "$SCRIPT_DIR" config --get remote.origin.url 2>/dev/null || true)
  [ -n "$remote_url" ] || return 1

  case "$remote_url" in
    https://github.com/*)
      inferred=${remote_url#https://github.com/}
      ;;
    git@github.com:*)
      inferred=${remote_url#git@github.com:}
      ;;
    ssh://git@github.com/*)
      inferred=${remote_url#ssh://git@github.com/}
      ;;
    *)
      return 1
      ;;
  esac

  inferred=${inferred%.git}
  [ -n "$inferred" ] || return 1
  printf '%s\n' "$inferred"
}

resolve_latest_tag() {
  repo=$1
  latest_url="https://api.github.com/repos/$repo/releases/latest"

  tag=$(curl -fsSL "$latest_url" | jq -r '.tag_name // empty') || return 1
  [ -n "$tag" ] || return 1

  printf '%s\n' "$tag"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      ensure_value "$1" "$#"
      REPO=$2
      shift 2
      ;;
    --ref)
      ensure_value "$1" "$#"
      REF=$2
      shift 2
      ;;
    --config-dir)
      ensure_value "$1" "$#"
      CONFIG_DIR=$2
      shift 2
      ;;
    --target-name|--script-name)
      ensure_value "$1" "$#"
      TARGET_NAME=$2
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
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage_error "Unknown option: $1"
      ;;
  esac
done

if [ -z "$REPO" ]; then
  REPO=$(infer_repo_from_git || true)
fi

[ -n "$REPO" ] || usage_error "--repo OWNER/REPO is required (or run from a GitHub clone with origin set)."

case "$REPO" in
  */*) ;;
  *) usage_error "Invalid --repo '$REPO' (expected OWNER/REPO)." ;;
esac

case "$TARGET_NAME" in
  */*) usage_error "--target-name/--script-name must be a file name, not a path." ;;
esac

require_cmd curl
require_cmd tar
require_cmd mktemp
require_cmd jq

RESOLVED_REF=$REF
if [ "$REF" = "latest" ]; then
  if RESOLVED_REF=$(resolve_latest_tag "$REPO"); then
    note "Resolved latest release tag: $RESOLVED_REF"
  else
    fail "Unable to resolve latest release tag for $REPO. Use --ref explicitly."
  fi
fi

ARCHIVE_URL="https://codeload.github.com/$REPO/tar.gz/$RESOLVED_REF"

if [ "$DRY_RUN" -eq 1 ]; then
  note "[dry-run] Repo: $REPO"
  note "[dry-run] Ref : $RESOLVED_REF"
  note "[dry-run] Would download: $ARCHIVE_URL"
  note "[dry-run] Would run install with: --config-dir '$CONFIG_DIR' --target-name '$TARGET_NAME'"
  if [ "$FORCE" -eq 1 ]; then
    note "[dry-run] Would pass: --force"
  fi
  exit 0
fi

tmp_dir=$(mktemp -d)
cleanup() {
  [ -n "${tmp_dir:-}" ] && [ -d "$tmp_dir" ] && rm -rf "$tmp_dir"
}
trap cleanup EXIT INT TERM

archive_path="$tmp_dir/repo.tar.gz"

note "Downloading $REPO@$RESOLVED_REF ..."
curl -fsSL "$ARCHIVE_URL" -o "$archive_path"

root_prefix=$(tar -tzf "$archive_path" | head -n 1 | cut -d/ -f1)
[ -n "$root_prefix" ] || fail "Unable to detect archive root directory."

note "Extracting archive ..."
tar -xzf "$archive_path" -C "$tmp_dir"
repo_root="$tmp_dir/$root_prefix"

[ -f "$repo_root/install.sh" ] || fail "install.sh not found in downloaded repository."

note "Running installer ..."
if [ "$FORCE" -eq 1 ]; then
  sh "$repo_root/install.sh" --config-dir "$CONFIG_DIR" --target-name "$TARGET_NAME" --force
else
  sh "$repo_root/install.sh" --config-dir "$CONFIG_DIR" --target-name "$TARGET_NAME"
fi

note ""
note "GitHub install complete."
