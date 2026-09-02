#!/usr/bin/env zsh
# Claude Code statusLine (zsh):
#   <jj change description>  <model>  ctx <tokens> (<pct>%)  $cost  wf $workflow-cost  <rate limits>
# $cost includes dynamic-workflow subagent spend (which Claude Code omits from
# .cost.total_cost_usd); "wf $…" breaks out that workflow portion.
#
# Input: the statusLine JSON on stdin (see https://code.claude.com/docs/en/statusline).

input=$(cat)

# Nerd Font icons
icon_5h=$'\U000f0954'   # clock  (5-hour limit)
icon_wk=$'\U000f0e17'   # calendar (weekly limit)

# Read one field from the stdin JSON. Uses a here-string, not echo, so zsh's
# echo never reinterprets backslash sequences inside the JSON.
field() { jq -r "$1" <<<"$input"; }

cwd=$(field '.cwd // .workspace.current_dir // empty')
model=$(field '.model.display_name // empty')
transcript=$(field '.transcript_path // empty')
cost=$(field '.cost.total_cost_usd // empty')
# Context tokens from the live payload. current_usage is null before the first
# API call and right after /compact; both cases leave these empty.
ctx_tokens=$(field '.context_window.current_usage
    | if . == null then empty
      else ((.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0)) end')
ctx_pct=$(field '.context_window.used_percentage // empty')
rl_5h=$(field '.rate_limits.five_hour.used_percentage // empty')
rl_wk=$(field '.rate_limits.seven_day.used_percentage // empty')
rl_5h_reset=$(field '.rate_limits.five_hour.resets_at // empty')
rl_wk_reset=$(field '.rate_limits.seven_day.resets_at // empty')

# Format seconds-until-reset (resets_at is Unix epoch seconds) as " (Xd)"/" (Xh)"/" (Xm)"
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
# cache-write-1h(2x), output]. A model id is matched by PREFIX against the
# table keys (so claude-fable-5-1 uses the claude-fable-5 row); unknown ids
# fall back to the claude-opus-4-8 row.
WF_JQ='
def rate($model):
  { "claude-opus-4-8":  [5,   0.5,  6.25, 10, 25],
    "claude-sonnet-5":  [3,   0.3,  3.75, 6,  15],
    "claude-haiku-4-5": [1,   0.1,  1.25, 2,  5],
    "claude-fable-5":   [10,  1,    12.5, 20, 50] } as $t
  | (($model // "") | sub("\\[1m\\]$";"") | sub("@.*$";"")) as $id
  | ([$t | to_entries[] | select(.key as $k | $id | startswith($k)) | .value] | first)
    // $t["claude-opus-4-8"];
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

# jj change description (first line of the working-copy change @).
# Shown only when cwd is inside a jj repo; an empty description reads
# "(no description)". Outside a repo the segment is omitted entirely.
jj_part=""
if command -v jj >/dev/null 2>&1 && [ -n "$cwd" ]; then
    if desc=$(cd "$cwd" 2>/dev/null && \
        jj --no-pager --ignore-working-copy log --no-graph -r @ -T 'description.first_line()' 2>/dev/null); then
        jj_part="${desc:-(no description)}"
    fi
fi

# Session cost in USD (e.g. $0.42), including dynamic-workflow subagents.
# cost_part shows the combined total; wf_part breaks out the workflow portion.
cost_part=""
wf_part=""
if [ -n "$cost" ] || [ -n "$wf_cost" ]; then
    total_cost=$(awk "BEGIN{printf \"%.6f\", ${cost:-0} + ${wf_cost:-0}}")
    cost_part="\$$(awk "BEGIN{printf \"%.2f\", $total_cost}")"
fi
if [ -n "$wf_cost" ] && [ "$(awk "BEGIN{print ($wf_cost >= 0.005)}")" = 1 ]; then
    wf_part="wf \$$(awk "BEGIN{printf \"%.2f\", $wf_cost}")"
fi

# Rate-limit usage (Pro/Max only, present after first API call)
rl_items=()
if [ -n "$rl_5h" ]; then
    rl_items+=("${icon_5h} 5h $(awk "BEGIN{printf \"%.0f\", $rl_5h}")%$(fmt_reset "$rl_5h_reset")")
fi
if [ -n "$rl_wk" ]; then
    rl_items+=("${icon_wk} wk $(awk "BEGIN{printf \"%.0f\", $rl_wk}")%$(fmt_reset "$rl_wk_reset")")
fi
rl_part="${(j:  :)rl_items}"

# Context: tokens in the window (e.g. 32.3k) plus the pre-calculated percentage
tok_part=""
if [ -n "$ctx_tokens" ] && [ "$ctx_tokens" -gt 0 ] 2>/dev/null; then
    if [ "$ctx_tokens" -ge 1000 ]; then
        tok_part="ctx $(awk "BEGIN{printf \"%.1fk\", $ctx_tokens/1000}")"
    else
        tok_part="ctx ${ctx_tokens}"
    fi
    if [ -n "$ctx_pct" ]; then
        tok_part="${tok_part} ($(awk "BEGIN{printf \"%.0f\", $ctx_pct}")%)"
    fi
fi

# Assemble: every segment is colored on its own, then joined by two spaces.
# yellow jj description | dim model | dim context | green cost | cyan workflow cost | magenta limits
parts=()
[ -n "$jj_part" ]   && parts+=("$(printf '\033[33m%s\033[0m' "$jj_part")")
[ -n "$model" ]     && parts+=("$(printf '\033[2m%s\033[0m' "$model")")
[ -n "$tok_part" ]  && parts+=("$(printf '\033[2m%s\033[0m' "$tok_part")")
[ -n "$cost_part" ] && parts+=("$(printf '\033[32m%s\033[0m' "$cost_part")")
[ -n "$wf_part" ]   && parts+=("$(printf '\033[36m%s\033[0m' "$wf_part")")
[ -n "$rl_part" ]   && parts+=("$(printf '\033[35m%s\033[0m' "$rl_part")")
printf '%s' "${(j:  :)parts}"
