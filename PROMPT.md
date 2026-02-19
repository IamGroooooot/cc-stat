# cc-stat: Claude Code에게 설치를 요청하는 프롬프트

아래 프롬프트를 Claude Code 세션에 그대로 붙여넣으면,
Claude가 자동으로 statusline을 설치해줍니다.

---

## 한국어 프롬프트

```
내 Claude Code에 커스텀 statusline을 설치해줘.

아래 스크립트를 ~/.claude/statusline.sh 로 저장하고 실행 권한을 부여한 뒤,
~/.claude/settings.json 에 statusLine 설정을 추가해줘. 기존 설정은 보존해야 해.

### statusline.sh 내용:

#!/usr/bin/env bash
input=$(cat)
readarray -t f <<< "$(echo "$input" | jq -r '
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
')"
MODEL="${f[0]}" USED_PCT="${f[1]}" COST="${f[2]}"
DURATION_MS="${f[3]}" API_DURATION_MS="${f[4]}"
LINES_ADD="${f[5]}" LINES_DEL="${f[6]}" AGENT="${f[7]}"
CTX_SIZE="${f[8]}" TOTAL_IN="${f[9]}" TOTAL_OUT="${f[10]}"
EXCEEDS_200K="${f[11]}"
RST=$'\033[0m'
CLR_WARN=$'\033[38;5;222m' CLR_HIGH=$'\033[38;5;209m' CLR_CRIT=$'\033[38;5;174m'
gauge_clr=""
if [[ "$EXCEEDS_200K" == "true" ]]; then gauge_clr="$CLR_CRIT"
elif (( USED_PCT >= 80 )); then gauge_clr="$CLR_HIGH"
elif (( USED_PCT >= 60 )); then gauge_clr="$CLR_WARN"; fi
gauges=("▱▱▱▱▱" "▰▱▱▱▱" "▰▰▱▱▱" "▰▰▰▱▱" "▰▰▰▰▱" "▰▰▰▰▰")
idx=$(( USED_PCT * 5 / 100 )); (( idx > 5 )) && idx=5; (( idx < 0 )) && idx=0
if (( CTX_SIZE >= 1000000 )); then ctx_label="1M"; else ctx_label="200K"; fi
total_tok=$(( TOTAL_IN + TOTAL_OUT ))
tok_str=$(awk -v t="$total_tok" 'BEGIN { if (t>=1000000) printf "%.1fM",t/1000000; else if (t>=1000) printf "%.1fK",t/1000; else printf "%d",t }')
cost_str=$(awk -v c="$COST" 'BEGIN { if (c>=0.1) printf "$%.2f",c; else printf "$%.4f",c }')
fmt_dur() { local s=$(($1/1000)) m=$((s/60)) sec=$((s%60)); (( m>0 )) && echo "${m}m${sec}s" || echo "${sec}s"; }
dur=$(fmt_dur "$DURATION_MS"); api_dur=$(fmt_dur "$API_DURATION_MS")
out="󰯉 ${MODEL}"
[[ -n "$AGENT" ]] && out+=" 󱚣 ${AGENT}"
if [[ -n "$gauge_clr" ]]; then out+=" ${gauge_clr}${gauges[$idx]} ${USED_PCT}%${RST}/${ctx_label}"
else out+=" ${gauges[$idx]} ${USED_PCT}%/${ctx_label}"; fi
out+=" ${tok_str}  ${cost_str}  ⏱ ${dur}(󰒍 ${api_dur})"
(( LINES_ADD > 0 || LINES_DEL > 0 )) && out+=" +${LINES_ADD}/-${LINES_DEL}"
echo "$out"

### settings.json에 추가할 설정:

"statusLine": {
  "type": "command",
  "command": "~/.claude/statusline.sh 경로를 절대경로로",
  "padding": 0
}

jq가 필요하니 없으면 설치 방법도 알려줘.
```

---

## English Prompt

```
Install a custom statusline for my Claude Code.

Save the script below as ~/.claude/statusline.sh, make it executable,
and add the statusLine config to ~/.claude/settings.json (preserve existing settings).

[paste the same script from above]

The settings.json needs this entry:
"statusLine": {
  "type": "command",
  "command": "/absolute/path/to/.claude/statusline.sh",
  "padding": 0
}

Requires jq - tell me how to install it if it's missing.
```
