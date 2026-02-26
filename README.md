# cc-stat

Claude Code statusline for model/context/tokens/cost/duration/line-diff at a glance.

```text
󰯉 Claude 4 Opus ▰▰▱▱▱ 42%/200K 85.3K $0.47 ⏱ 3m12s(󰒍 1m45s) +120/-34
```

## Quick Start (Local Clone)

```sh
cd cc-stat
./cc-stat install
./cc-stat doctor
```

## Quick Start (GitHub-Based, no clone required)

1) Download installer script

```sh
curl -fsSL -o /tmp/cc-stat-install.sh \
  https://raw.githubusercontent.com/<OWNER>/<REPO>/main/install-from-github.sh
```

2) Run installer

```sh
sh /tmp/cc-stat-install.sh --repo <OWNER>/<REPO>
```

Recommended for reproducibility:
- Pin with `--ref <tag-or-commit>` instead of floating refs.

Example:

```sh
sh /tmp/cc-stat-install.sh --repo <OWNER>/<REPO> --ref v1.2.3
```

## Commands

All commands are available via `./cc-stat`:

```sh
./cc-stat install
./cc-stat uninstall
./cc-stat doctor
./cc-stat install-github --repo <OWNER>/<REPO>
```

You can still run scripts directly:
- `./install.sh`
- `./uninstall.sh`
- `./doctor.sh`
- `./install-from-github.sh`

## Requirements

- `jq` (required)
- Claude Code
- Nerd Font terminal (optional, icons only)

## Install Options

```sh
./cc-stat install --help
```

Common options:
- `--config-dir DIR`: target config directory (default: `$CLAUDE_CONFIG_DIR` or `~/.claude`)
- `--script-name NAME`: installed filename (default: `statusline.sh`)
- `--source-script FILE`: custom source statusline script
- `--force`: overwrite existing installed script
- `--dry-run`: preview actions only

## Uninstall

```sh
./cc-stat uninstall
```

If `statusLine.command` points to another script and you still want to remove the key:

```sh
./cc-stat uninstall --all-statusline
```

## Doctor

```sh
./cc-stat doctor
```

Checks:
- required dependencies
- installed script presence/executable bit
- `settings.json` JSON validity
- `statusLine.command` wiring

## What It Shows

| Field | Description |
|-------|-------------|
| 󰯉 Model | Current model name |
| 󱚣 Agent | Agent name (if using teams) |
| ▰▰▱▱▱ | Context usage gauge |
| `42%/200K` | Used context / context window size |
| `85.3K` | Total tokens (input + output) |
| `$0.47` | Session cost |
| `⏱ 3m12s(󰒍 1m45s)` | Total/API duration |
| `+120/-34` | Lines added/removed |

Color thresholds:
- warn: `60%+`
- high: `80%+`
- critical: `exceeds_200k_tokens=true`

You can override thresholds:
- `CC_STAT_WARN_PCT` (default `60`)
- `CC_STAT_HIGH_PCT` (default `80`)

## Customization

Edit installed script (default `~/.claude/statusline.sh`) to customize icons/colors/field order.

## License

MIT
