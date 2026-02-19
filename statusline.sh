#!/usr/bin/env zsh
# cc-stat: Claude Code custom statusline
#
# Reads session JSON from stdin, outputs formatted status bar.
# Fields: model, context gauge, tokens, cost, duration, lines changed

emulate -L zsh

input=$(cat)

f=("${(@f)$(echo "$input" | jq -r '
  (.model.display_name // ""),
  (.context_window.used_percentage // 0 | tostring),
  (.cost.total_cost_usd // 0 | tostring),
  (.cost.total_duration_ms // 0 | tostring),
  (.cost.total_api_duration_ms // 0 | tostring),
  (.cost.total_lines_added // 0 | tostring),
  (.cost.total_lines_removed // 0 | tostring),
  (.agent.name // ""),
  (.context_window.context_window_size // 200000 | tostring),
  (.context_window.total_input_tokens // 0 | tostring),
  (.context_window.total_output_tokens // 0 | tostring),
  (.exceeds_200k_tokens // false | tostring)
')}")
MODEL="${f[1]}"
USED_PCT="${f[2]}"
COST="${f[3]}"
DURATION_MS="${f[4]}"
API_DURATION_MS="${f[5]}"
LINES_ADD="${f[6]}"
LINES_DEL="${f[7]}"
AGENT="${f[8]}"
CTX_SIZE="${f[9]}"
TOTAL_IN="${f[10]}"
TOTAL_OUT="${f[11]}"
EXCEEDS_200K="${f[12]}"

# ANSI colors for context gauge
RST=$'\033[0m'
CLR_WARN=$'\033[38;5;222m'   # pastel yellow  (60-79%)
CLR_HIGH=$'\033[38;5;209m'   # pastel salmon   (80-99%)
CLR_CRIT=$'\033[38;5;174m'   # pastel pink     (exceeds 200k)

gauge_clr=""
if [[ "$EXCEEDS_200K" == "true" ]]; then
  gauge_clr="$CLR_CRIT"
elif (( USED_PCT >= 80 )); then
  gauge_clr="$CLR_HIGH"
elif (( USED_PCT >= 60 )); then
  gauge_clr="$CLR_WARN"
fi

# Gauge bar (5 blocks)
gauges=("▱▱▱▱▱" "▰▱▱▱▱" "▰▰▱▱▱" "▰▰▰▱▱" "▰▰▰▰▱" "▰▰▰▰▰")
idx=$(( USED_PCT * 5 / 100 ))
(( idx > 5 )) && idx=5
(( idx < 0 )) && idx=0
# zsh arrays are 1-based
(( idx += 1 ))

# Context window label
if (( CTX_SIZE >= 1000000 )); then
  ctx_label="1M"
else
  ctx_label="200K"
fi

# Total tokens (human readable)
total_tok=$(( TOTAL_IN + TOTAL_OUT ))
tok_str=$(awk -v t="$total_tok" 'BEGIN {
  if (t >= 1000000) printf "%.1fM", t/1000000
  else if (t >= 1000) printf "%.1fK", t/1000
  else printf "%d", t
}')

# Cost
cost_str=$(awk -v c="$COST" 'BEGIN { if (c >= 0.1) printf "$%.2f", c; else printf "$%.4f", c }')

# Duration formatter
fmt_dur() {
  local s=$(( $1 / 1000 ))
  local m=$(( s / 60 )) sec=$(( s % 60 ))
  (( m > 0 )) && echo "${m}m${sec}s" || echo "${sec}s"
}
dur=$(fmt_dur "$DURATION_MS")
api_dur=$(fmt_dur "$API_DURATION_MS")

# === Build output ===
out="󰯉 ${MODEL}"
[[ -n "$AGENT" ]] && out+=" 󱚣 ${AGENT}"

if [[ -n "$gauge_clr" ]]; then
  out+=" ${gauge_clr}${gauges[$idx]} ${USED_PCT}%${RST}/${ctx_label}"
else
  out+=" ${gauges[$idx]} ${USED_PCT}%/${ctx_label}"
fi

out+=" ${tok_str}"
out+=" ${cost_str}"
out+=" ⏱ ${dur}(󰒍 ${api_dur})"
(( LINES_ADD > 0 || LINES_DEL > 0 )) && out+=" +${LINES_ADD}/-${LINES_DEL}"

echo "$out"
