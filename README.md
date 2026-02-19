# cc-stat

Claude Code custom statusline that shows model, context usage, tokens, cost, duration, and lines changed at a glance.

```
󰯉 Claude 4 Opus ▰▰▱▱▱ 42%/200K 85.3K $0.47 ⏱ 3m12s(󰒍 1m45s) +120/-34
```

## What it shows

| Field | Description |
|-------|-------------|
| 󰯉 Model | Current model name |
| 󱚣 Agent | Agent name (when using agent teams) |
| ▰▰▱▱▱ | Context window gauge (5 blocks) |
| 42%/200K | Context used % / window size |
| 85.3K | Total tokens (input + output) |
| $0.47 | Session cost |
| ⏱ 3m12s | Total duration |
| 󰒍 1m45s | API duration |
| +120/-34 | Lines added/removed |

Colors change as context fills up:
- **60-79%** — pastel yellow
- **80-99%** — pastel salmon
- **200K+ overflow** — pastel pink

## Requirements

- **jq** (JSON processor)
- **Claude Code** with statusLine support
- A **Nerd Font** terminal for icons (optional, works without but icons won't render)

## Install

### Option 1: Script

```bash
git clone https://github.com/user/cc-stat.git
cd cc-stat
./install.sh
```

Or with a custom config directory:

```bash
./install.sh --config-dir ~/.my-claude-config
```

### Option 2: One-liner

```bash
curl -fsSL https://raw.githubusercontent.com/user/cc-stat/main/install.sh | bash
```

### Option 3: Ask Claude Code

Open Claude Code and paste the prompt from [PROMPT.md](./PROMPT.md).

## Uninstall

```bash
./uninstall.sh
# or with custom config dir:
./uninstall.sh --config-dir ~/.my-claude-config
```

## How it works

Claude Code's `statusLine` setting runs a command and pipes session JSON to stdin on every render tick. The script parses the JSON with `jq`, formats the fields, and outputs a single line with ANSI colors.

The session JSON includes fields like:

```json
{
  "model": { "display_name": "Claude 4 Opus" },
  "context_window": {
    "used_percentage": 42,
    "context_window_size": 200000,
    "total_input_tokens": 70000,
    "total_output_tokens": 15000
  },
  "cost": {
    "total_cost_usd": 0.47,
    "total_duration_ms": 192000,
    "total_api_duration_ms": 105000,
    "total_lines_added": 120,
    "total_lines_removed": 34
  },
  "agent": { "name": "researcher" },
  "exceeds_200k_tokens": false
}
```

## Customization

Edit `~/.claude/statusline.sh` to change:
- **Icons** — replace Nerd Font glyphs with emoji or text
- **Colors** — change `CLR_WARN`, `CLR_HIGH`, `CLR_CRIT` ANSI codes
- **Thresholds** — adjust the 60%/80% boundaries
- **Fields** — add/remove/reorder output sections

## License

MIT
