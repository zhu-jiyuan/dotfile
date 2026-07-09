#!/usr/bin/env bash
# Claude Code statusLine:
#   <jj change description>  <model>  ctx  $cost  wf $workflow-cost  <rate limits>
# $cost includes dynamic-workflow subagent spend (which Claude Code omits from
# .cost.total_cost_usd); "wf $…" breaks out that workflow portion.

input=$(cat)

# Nerd Font icons
icon_5h=$'\U000f0954'   # clock  (5-hour limit)
icon_wk=$'\U000f0e17'   # calendar (weekly limit)

cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
rl_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_wk=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl_5h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl_wk_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Format seconds-until-reset as a short "Xd"/"Xh"/"Xm" string
fmt_reset() {
    local reset_at="$1" now diff
    [ -z "$reset_at" ] && return
    now=$(date +%s)
    diff=$((reset_at - now))
    [ "$diff" -le 0 ] && return
    if [ "$diff" -ge 86400 ]; then
        printf " (%dd)" "$((diff / 86400))"
    elif [ "$diff" -ge 3600 ]; then
        printf " (%dh)" "$((diff / 3600))"
    else
        printf " (%dm)" "$(((diff + 59) / 60))"
    fi
}

# Cost in USD of the current session's dynamic-workflow subagents.
# Claude Code's .cost.total_cost_usd does NOT include background workflow
# subagents (they run detached), so we price their token usage ourselves from
# their transcripts under <session>/subagents/workflows/<wf>/agent-*.jsonl.
# Rates per 1M tokens: [input, cache-read(0.1x), cache-write-5m(1.25x),
# cache-write-1h(2x), output]. Current models have no long-context premium,
# so 1M-context tokens bill at the standard rate.
WF_JQ='
def rate($model):
  { "claude-opus-4-8":  [5,   0.5,  6.25, 10, 25],
    "claude-sonnet-5":  [3,   0.3,  3.75, 6,  15],
    "claude-haiku-4-5": [1,   0.1,  1.25, 2,  5],
    "claude-fable-5":   [10,  1,    12.5, 20, 50] } as $t
  | (($model // "") | sub("\\[1m\\]$";"") | sub("@.*$";"") | sub("-[0-9]{8}$";"")) as $k
  | ($t[$k] // $t["claude-opus-4-8"]);
def cost($m):
  rate($m.model) as $r
  | ($m.usage.input_tokens // 0) * $r[0]
  + ($m.usage.cache_read_input_tokens // 0) * $r[1]
  + (($m.usage.cache_creation.ephemeral_5m_input_tokens // $m.usage.cache_creation_input_tokens // 0)) * $r[2]
  + ($m.usage.cache_creation.ephemeral_1h_input_tokens // 0) * $r[3]
  + ($m.usage.output_tokens // 0) * $r[4];
# Dedupe streaming re-writes: per message.id keep the record with the largest
# output_tokens (the final usage line for that assistant turn).
reduce (inputs | select(.message.usage) | .message | select(.id)) as $m ({};
  .[$m.id] as $p
  | if ($p == null) or (($m.usage.output_tokens // 0) > ($p.usage.output_tokens // 0))
    then .[$m.id] = $m else . end)
| ([.[]] | map(cost(.)) | add // 0) / 1000000
'
wf_cost=""
if [ -n "$transcript" ]; then
    wf_dir="${transcript%.jsonl}/subagents/workflows"
    if [ -d "$wf_dir" ]; then
        wf_cost=$(find "$wf_dir" -name 'agent-*.jsonl' -print0 2>/dev/null \
            | xargs -0 -r jq -n "$WF_JQ" 2>/dev/null \
            | awk '{s += $1} END { if (s > 0) printf "%.6f", s }')
    fi
fi

# Total tokens currently in the context window (from last message usage)
tokens=""
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
    tokens=$(jq -s '[.[] | select(.message.usage) | .message.usage] | last
        | ((.input_tokens // 0)+(.cache_read_input_tokens // 0)+(.cache_creation_input_tokens // 0))' \
        "$transcript" 2>/dev/null)
fi

# jj change description (first line of the working-copy change @), if in a jj repo
jj_part=""
if command -v jj >/dev/null 2>&1; then
    desc=$(cd "$cwd" 2>/dev/null && \
        jj --no-pager --ignore-working-copy log --no-graph -r @ -T 'description.first_line()' 2>/dev/null)
    if [ -n "$desc" ]; then
        jj_part="$desc"
    else
        jj_part="(no description)"
    fi
fi

# Session cost in USD (e.g. $0.42), including dynamic-workflow subagents.
# cost_part shows the combined total; wf_part breaks out the workflow portion.
cost_part=""
wf_part=""
if [ -n "$cost" ] || [ -n "$wf_cost" ]; then
    total_cost=$(awk "BEGIN{printf \"%.6f\", ${cost:-0} + ${wf_cost:-0}}")
    cost_part="  \$$(awk "BEGIN{printf \"%.2f\", $total_cost}")"
fi
if [ -n "$wf_cost" ] && [ "$(awk "BEGIN{print ($wf_cost >= 0.005)}")" = 1 ]; then
    wf_part="  wf \$$(awk "BEGIN{printf \"%.2f\", $wf_cost}")"
fi

# Rate-limit usage (Pro/Max only, present after first API call)
rl_part=""
if [ -n "$rl_5h" ]; then
    rl_part="${rl_part}  ${icon_5h} 5h $(awk "BEGIN{printf \"%.0f\", $rl_5h}")%$(fmt_reset "$rl_5h_reset")"
fi
if [ -n "$rl_wk" ]; then
    rl_part="${rl_part}  ${icon_wk} wk $(awk "BEGIN{printf \"%.0f\", $rl_wk}")%$(fmt_reset "$rl_wk_reset")"
fi

# Total tokens in context (formatted as e.g. 32.3k)
tok_part=""
if [ -n "$tokens" ] && [ "$tokens" -gt 0 ] 2>/dev/null; then
    if [ "$tokens" -ge 1000 ]; then
        tok_part="  ctx $(awk "BEGIN{printf \"%.1fk\", $tokens/1000}")"
    else
        tok_part="  ctx ${tokens}"
    fi
fi

# Assemble — use printf for ANSI colors
# yellow jj description | dim model | dim context | green cost | magenta limits
if [ -n "$jj_part" ]; then
    printf "\033[33m%s\033[0m" "$jj_part"
fi
if [ -n "$model" ]; then
    printf "  \033[2m%s\033[0m" "$model"
fi
if [ -n "$tok_part" ]; then
    printf " \033[2m%s\033[0m" "$tok_part"
fi
if [ -n "$cost_part" ]; then
    printf " \033[32m%s\033[0m" "$cost_part"
fi
if [ -n "$wf_part" ]; then
    printf " \033[36m%s\033[0m" "$wf_part"
fi
if [ -n "$rl_part" ]; then
    printf " \033[35m%s\033[0m" "$rl_part"
fi
