#!/usr/bin/env sh
# cc-stat: Claude Code custom statusline
# Reads JSON from stdin and prints a single compact status line.

set -eu

if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' 'cc-stat: jq is required'
  exit 0
fi

input=$(cat)
[ -n "$input" ] || exit 0

assignments=$(printf '%s' "$input" | jq -r '
  "MODEL=" + ((.model.display_name // "Claude") | @sh) + "\n" +
  "USED_PCT=" + ((.context_window.used_percentage // 0 | tostring) | @sh) + "\n" +
  "COST=" + ((.cost.total_cost_usd // 0 | tostring) | @sh) + "\n" +
  "DURATION_MS=" + ((.cost.total_duration_ms // 0 | tostring) | @sh) + "\n" +
  "API_DURATION_MS=" + ((.cost.total_api_duration_ms // 0 | tostring) | @sh) + "\n" +
  "LINES_ADD=" + ((.cost.total_lines_added // 0 | tostring) | @sh) + "\n" +
  "LINES_DEL=" + ((.cost.total_lines_removed // 0 | tostring) | @sh) + "\n" +
  "AGENT=" + ((.agent.name // "") | @sh) + "\n" +
  "CTX_SIZE=" + ((.context_window.context_window_size // 200000 | tostring) | @sh) + "\n" +
  "TOTAL_IN=" + ((.context_window.total_input_tokens // 0 | tostring) | @sh) + "\n" +
  "TOTAL_OUT=" + ((.context_window.total_output_tokens // 0 | tostring) | @sh) + "\n" +
  "EXCEEDS_200K=" + ((.exceeds_200k_tokens // false | tostring) | @sh)
' 2>/dev/null || true)

[ -n "$assignments" ] || exit 0
eval "$assignments"

to_nonneg_int() {
  case "$1" in
    ''|*[!0-9]*) printf '0' ;;
    *) printf '%s' "$1" ;;
  esac
}

format_compact() {
  awk -v n="$1" 'BEGIN {
    n += 0
    if (n >= 1000000000) { v = n / 1000000000; s = "B" }
    else if (n >= 1000000) { v = n / 1000000; s = "M" }
    else if (n >= 1000) { v = n / 1000; s = "K" }
    else { printf "%.0f", n; exit }

    if (v >= 100 || v == int(v)) printf "%.0f%s", v, s
    else printf "%.1f%s", v, s
  }'
}

format_cost() {
  awk -v c="$1" 'BEGIN {
    c += 0
    if (c >= 0.1) printf "$%.2f", c
    else printf "$%.4f", c
  }'
}

format_duration_ms() {
  ms=$(to_nonneg_int "$1")
  sec=$((ms / 1000))
  h=$((sec / 3600))
  m=$(((sec % 3600) / 60))
  s=$((sec % 60))

  if [ "$h" -gt 0 ]; then
    printf '%dh%02dm' "$h" "$m"
  elif [ "$m" -gt 0 ]; then
    printf '%dm%02ds' "$m" "$s"
  else
    printf '%ds' "$s"
  fi
}

USED_PCT=$(to_nonneg_int "${USED_PCT:-0}")
DURATION_MS=$(to_nonneg_int "${DURATION_MS:-0}")
API_DURATION_MS=$(to_nonneg_int "${API_DURATION_MS:-0}")
LINES_ADD=$(to_nonneg_int "${LINES_ADD:-0}")
LINES_DEL=$(to_nonneg_int "${LINES_DEL:-0}")
CTX_SIZE=$(to_nonneg_int "${CTX_SIZE:-200000}")
TOTAL_IN=$(to_nonneg_int "${TOTAL_IN:-0}")
TOTAL_OUT=$(to_nonneg_int "${TOTAL_OUT:-0}")

WARN_PCT=$(to_nonneg_int "${CC_STAT_WARN_PCT:-60}")
HIGH_PCT=$(to_nonneg_int "${CC_STAT_HIGH_PCT:-80}")
if [ "$HIGH_PCT" -lt "$WARN_PCT" ]; then
  HIGH_PCT=$WARN_PCT
fi

idx=$((USED_PCT * 5 / 100))
if [ "$idx" -lt 0 ]; then
  idx=0
elif [ "$idx" -gt 5 ]; then
  idx=5
fi

case "$idx" in
  0) gauge='▱▱▱▱▱' ;;
  1) gauge='▰▱▱▱▱' ;;
  2) gauge='▰▰▱▱▱' ;;
  3) gauge='▰▰▰▱▱' ;;
  4) gauge='▰▰▰▰▱' ;;
  *) gauge='▰▰▰▰▰' ;;
esac

RST=$(printf '\033[0m')
CLR_WARN=$(printf '\033[38;5;222m')
CLR_HIGH=$(printf '\033[38;5;209m')
CLR_CRIT=$(printf '\033[38;5;174m')

if [ -n "${NO_COLOR:-}" ]; then
  RST=''
  CLR_WARN=''
  CLR_HIGH=''
  CLR_CRIT=''
fi

gauge_clr=''
if [ "${EXCEEDS_200K:-false}" = 'true' ]; then
  gauge_clr=$CLR_CRIT
elif [ "$USED_PCT" -ge "$HIGH_PCT" ]; then
  gauge_clr=$CLR_HIGH
elif [ "$USED_PCT" -ge "$WARN_PCT" ]; then
  gauge_clr=$CLR_WARN
fi

ctx_label=$(format_compact "$CTX_SIZE")
total_tok=$((TOTAL_IN + TOTAL_OUT))
tok_str=$(format_compact "$total_tok")
cost_str=$(format_cost "${COST:-0}")
dur=$(format_duration_ms "$DURATION_MS")
api_dur=$(format_duration_ms "$API_DURATION_MS")

out="󰯉 ${MODEL:-Claude}"
if [ -n "${AGENT:-}" ]; then
  out="$out 󱚣 ${AGENT}"
fi

if [ -n "$gauge_clr" ]; then
  out="$out ${gauge_clr}${gauge} ${USED_PCT}%${RST}/${ctx_label}"
else
  out="$out ${gauge} ${USED_PCT}%/${ctx_label}"
fi

out="$out ${tok_str} ${cost_str} ⏱ ${dur}(󰒍 ${api_dur})"
if [ "$LINES_ADD" -gt 0 ] || [ "$LINES_DEL" -gt 0 ]; then
  out="$out +${LINES_ADD}/-${LINES_DEL}"
fi

printf '%s\n' "$out"
