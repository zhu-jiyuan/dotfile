#!/usr/bin/env zsh
# Claude Code statusLine (zsh):
#   <model>  ctx <tokens> (<pct>%)  <rate limits>  <jj change description>
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
effort=$(field '.effort.level // empty')
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

# jj change description (first line of the working-copy change @).
# Shown only when cwd is inside a jj repo; an empty description reads
# "(no description)". Outside a repo the segment is omitted entirely.
# Rendered at assembly time: its width budget depends on the other segments.
in_jj=""
jj_desc=""
if command -v jj >/dev/null 2>&1 && [ -n "$cwd" ]; then
    if jj_desc=$(cd "$cwd" 2>/dev/null && \
        jj --no-pager --ignore-working-copy log --no-graph -r @ \
            -T 'description.first_line()' 2>/dev/null); then
        in_jj=1
    fi
fi

# Display width of $1 with ANSI colors removed. The (m) flag counts CJK as 2.
vis_width() {
    setopt localoptions extendedglob
    local s="${1//$'\033'\[[0-9;]#m/}"
    printf '%s' "${(m)#s}"
}

# Cut $1 to at most $2 display columns, ending in "…" when anything was removed.
fit_cols() {
    local s="$1" max="$2"
    if (( ${(m)#s} > max )); then
        while (( ${(m)#s} > max - 1 )); do s="${s[1,-2]}"; done
        s="${s}…"
    fi
    printf '%s' "$s"
}

# Rate-limit usage (Pro/Max only, present after first API call)
# Each limit is colored by its own usage: green <50, yellow <80, red >=80.
pct_color() {
    awk "BEGIN{ if ($1 < 50) print 32; else if ($1 < 80) print 33; else print 31 }"
}
rl_items=()
if [ -n "$rl_5h" ]; then
    c=$(pct_color "$rl_5h")
    rl_items+=("$(printf '\033[%sm%s 5h %.0f%%\033[0m\033[2m%s\033[0m' "$c" "$icon_5h" "$rl_5h" "$(fmt_reset "$rl_5h_reset")")")
fi
if [ -n "$rl_wk" ]; then
    c=$(pct_color "$rl_wk")
    rl_items+=("$(printf '\033[%sm%s wk %.0f%%\033[0m\033[2m%s\033[0m' "$c" "$icon_wk" "$rl_wk" "$(fmt_reset "$rl_wk_reset")")")
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
# model | context | limits | yellow jj description (rightmost)
parts=()
# Dynamic colors: model by family, effort by level, ctx by usage percentage.
model_lc="${model:l}"
case "$model_lc" in
    *opus*)   model_c=35 ;;  # magenta
    *sonnet*) model_c=34 ;;  # blue
    *haiku*)  model_c=36 ;;  # cyan
    *fable*)  model_c=33 ;;  # yellow
    *)        model_c=2  ;;  # dim
esac
case "$effort" in
    low)    effort_c=32 ;;   # green
    medium) effort_c=36 ;;   # cyan
    high)   effort_c=33 ;;   # yellow
    xhigh)  effort_c=31 ;;   # red
    max)    effort_c=35 ;;   # magenta
    *)      effort_c=2  ;;
esac
ctx_c=2
if [ -n "$ctx_pct" ]; then
    ctx_i=$(awk "BEGIN{printf \"%d\", $ctx_pct}")
    if [ "$ctx_i" -lt 50 ]; then ctx_c=32
    elif [ "$ctx_i" -lt 80 ]; then ctx_c=33
    else ctx_c=31; fi
fi
if [ -n "$model" ]; then
    m_seg="$(printf '\033[%sm%s\033[0m' "$model_c" "$model")"
    [ -n "$effort" ] && m_seg="$m_seg$(printf ' \033[2m·\033[0m \033[%sm%s\033[0m' "$effort_c" "$effort")"
    parts+=("$m_seg")
fi
if [ -n "$tok_part" ]; then
    parts+=("$(printf '\033[%sm%s\033[0m' "$ctx_c" "$tok_part")")
fi
[ -n "$rl_part" ]   && parts+=("$rl_part")
sep="  "

# The description gets only the columns the other segments leave, so it can
# never push them off the line. Claude Code sets COLUMNS to the terminal width;
# zsh reads 0 when it is absent (e.g. a manual run), which falls back to a fixed
# budget. The reserve covers the UI's own padding and Nerd Font icons that some
# terminals draw 2 columns wide. Too little room drops the description entirely.
if [ -n "$in_jj" ]; then
    jj_reserve=6
    jj_min=8
    if (( COLUMNS > 0 )); then
        rest_width=$(vis_width "${(pj:$sep:)parts}")
        jj_budget=$(( COLUMNS - rest_width - ${#sep} - jj_reserve ))
    else
        jj_budget=40
    fi
    if (( jj_budget >= jj_min )); then
        if [ -n "$jj_desc" ]; then
            jj_part="$(printf '\033[33m%s\033[0m' "$(fit_cols "$jj_desc" "$jj_budget")")"
        else
            jj_part="$(printf '\033[2;33m%s\033[0m' "$(fit_cols "(no description)" "$jj_budget")")"
        fi
        parts+=("$jj_part")
    fi
fi

printf '%s' "${(pj:$sep:)parts}"
