#!/usr/bin/env bash
# Display Claude Code + Codex quota usage in tmux status bar.
# Output example: CC h23 w68 CX h12 w45
#   h = current 5-hour rolling window % used
#   w = current 7-day rolling window % used
#
# Endpoints used (both undocumented, may break without notice):
#   Claude: GET https://api.anthropic.com/api/oauth/usage
#   Codex : GET https://chatgpt.com/backend-api/wham/usage

set -u

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-ai-quota"
CACHE_TTL=300         # seconds — reuse cached response within this window
CURL_TIMEOUT=3        # seconds — fail fast so the status bar stays snappy

mkdir -p "$CACHE_DIR"

now_ts() { date +%s; }

cache_fresh() {
    local file=$1
    [[ -f $file ]] || return 1
    local mtime age
    mtime=$(stat -c %Y "$file" 2>/dev/null) || return 1
    age=$(( $(now_ts) - mtime ))
    (( age < CACHE_TTL ))
}

fetch_claude() {
    local cache="$CACHE_DIR/claude.json"
    if cache_fresh "$cache"; then
        cat "$cache"
        return 0
    fi
    local creds="$HOME/.claude/.credentials.json"
    [[ -f $creds ]] || return 1
    local token
    token=$(jq -r '.claudeAiOauth.accessToken // empty' "$creds" 2>/dev/null)
    [[ -n $token ]] || return 1
    local resp
    resp=$(curl -sS --max-time "$CURL_TIMEOUT" \
        "https://api.anthropic.com/api/oauth/usage" \
        -H "Authorization: Bearer $token" \
        -H "anthropic-beta: oauth-2025-04-20" \
        -H "Content-Type: application/json" 2>/dev/null) || return 1
    # Sanity check: must contain at least one of the expected fields.
    echo "$resp" | jq -e '.five_hour.utilization // .seven_day.utilization' >/dev/null 2>&1 || return 1
    printf '%s' "$resp" > "$cache"
    printf '%s' "$resp"
}

CODEX_AUTH="$HOME/.codex/auth.json"
CODEX_CLIENT_ID="app_EMoamEEZ73f0CkXaXp7hrann"
CODEX_REFRESH_URL="https://auth.openai.com/oauth/token"
CODEX_REFRESH_FAIL_MARKER="$CACHE_DIR/codex.refresh_failed"
CODEX_REFRESH_BACKOFF=600   # don't retry refresh more than once every 10 min

# Hit the OpenAI OAuth refresh endpoint and write new tokens back to auth.json
# in-place (atomic via temp file). Mirrors what `codex` CLI does internally —
# endpoint, client_id, and body shape are taken from openai/codex source
# (codex-rs/login/src/auth/manager.rs).
codex_refresh() {
    [[ -f $CODEX_AUTH ]] || return 1
    # Honor a recent failure to avoid hammering the refresh endpoint when the
    # refresh_token itself is dead (user needs to re-run `codex login`).
    if [[ -f $CODEX_REFRESH_FAIL_MARKER ]]; then
        local marker_age=$(( $(now_ts) - $(stat -c %Y "$CODEX_REFRESH_FAIL_MARKER" 2>/dev/null || echo 0) ))
        (( marker_age < CODEX_REFRESH_BACKOFF )) && return 1
    fi
    local refresh_token
    refresh_token=$(jq -r '.tokens.refresh_token // empty' "$CODEX_AUTH" 2>/dev/null)
    [[ -n $refresh_token ]] || return 1
    local body
    body=$(jq -nc --arg cid "$CODEX_CLIENT_ID" --arg rt "$refresh_token" \
        '{client_id: $cid, grant_type: "refresh_token", refresh_token: $rt}')
    local resp
    resp=$(curl -sS --max-time "$CURL_TIMEOUT" -X POST "$CODEX_REFRESH_URL" \
        -H "Content-Type: application/json" \
        --data "$body" 2>/dev/null) || { touch "$CODEX_REFRESH_FAIL_MARKER"; return 1; }
    local new_access new_refresh
    new_access=$(echo "$resp" | jq -r '.access_token // empty' 2>/dev/null)
    new_refresh=$(echo "$resp" | jq -r '.refresh_token // empty' 2>/dev/null)
    if [[ -z $new_access ]]; then
        touch "$CODEX_REFRESH_FAIL_MARKER"
        return 1
    fi
    # Atomic update: merge into existing auth.json so we keep account_id,
    # id_token claims, and any other fields untouched.
    local tmp
    tmp=$(mktemp "${CODEX_AUTH}.XXXXXX") || return 1
    if jq --arg a "$new_access" --arg r "$new_refresh" --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '
        .tokens.access_token = $a
        | (if $r != "" then .tokens.refresh_token = $r else . end)
        | .last_refresh = $now
    ' "$CODEX_AUTH" > "$tmp" 2>/dev/null && [[ -s $tmp ]]; then
        chmod 600 "$tmp"
        mv "$tmp" "$CODEX_AUTH"
        rm -f "$CODEX_REFRESH_FAIL_MARKER"
        return 0
    else
        rm -f "$tmp"
        return 1
    fi
}

fetch_codex() {
    local cache="$CACHE_DIR/codex.json"
    if cache_fresh "$cache"; then
        cat "$cache"
        return 0
    fi
    [[ -f $CODEX_AUTH ]] || return 1
    _codex_request() {
        local token account
        token=$(jq -r '.tokens.access_token // empty' "$CODEX_AUTH" 2>/dev/null)
        account=$(jq -r '.tokens.account_id // empty' "$CODEX_AUTH" 2>/dev/null)
        [[ -n $token && -n $account ]] || return 1
        curl -sS --max-time "$CURL_TIMEOUT" \
            "https://chatgpt.com/backend-api/wham/usage" \
            -H "Authorization: Bearer $token" \
            -H "ChatGPT-Account-Id: $account" \
            -H "Accept: application/json" \
            -H "Origin: https://chatgpt.com" \
            -H "Referer: https://chatgpt.com/" \
            -H "User-Agent: Mozilla/5.0" 2>/dev/null
    }
    local resp
    resp=$(_codex_request) || return 1
    # On token_expired, refresh once and retry.
    if echo "$resp" | jq -e '.error.code == "token_expired" or .status == 401' >/dev/null 2>&1; then
        codex_refresh && resp=$(_codex_request)
    fi
    echo "$resp" | jq -e '.rate_limit.primary_window // .rate_limit.five_hour // .rate_limits // .five_hour // .weekly' >/dev/null 2>&1 || return 1
    printf '%s' "$resp" > "$cache"
    printf '%s' "$resp"
}

# Colorize a percentage value for tmux. Resets to cyan afterwards so the
# surrounding labels stay in the outer status color.
#   < 50  green   |  50-79  yellow  |  >= 80  red  |  -- (unknown)  grey
_fmt_pct() {
    local v=$1 color
    if [[ $v == "--" ]]; then
        printf '#[fg=colour244]--#[fg=cyan]'
        return
    fi
    if   (( v >= 80 )); then color=red
    elif (( v >= 50 )); then color=yellow
    else                     color=green
    fi
    printf '#[fg=%s]%s%%#[fg=cyan]' "$color" "$v"
}

format_claude() {
    local json
    json=$(fetch_claude) || { printf 'CC --'; return; }
    local h w
    h=$(echo "$json" | jq -r '.five_hour.utilization | if . == null then "--" else (.|round|tostring) end')
    w=$(echo "$json" | jq -r '.seven_day.utilization | if . == null then "--" else (.|round|tostring) end')
    printf 'CC h%s w%s' "$(_fmt_pct "$h")" "$(_fmt_pct "$w")"
}

format_codex() {
    local json
    json=$(fetch_codex) || { printf 'CX --'; return; }
    # Codex response shape has shifted over time; try the documented locations
    # in priority order and pick the first non-null.
    local h w
    h=$(echo "$json" | jq -r '
        [ .rate_limit.primary_window.used_percent,
          .rate_limit.five_hour.percent_used,
          .rate_limits.primary.used_percent,
          .five_hour.utilization,
          .five_hour.percent_used
        ] | map(select(. != null)) | .[0]
        | if . == null then "--" else (.|round|tostring) end')
    w=$(echo "$json" | jq -r '
        [ .rate_limit.secondary_window.used_percent,
          .rate_limit.weekly.percent_used,
          .rate_limits.secondary.used_percent,
          .seven_day.utilization,
          .weekly.percent_used
        ] | map(select(. != null)) | .[0]
        | if . == null then "--" else (.|round|tostring) end')
    printf 'CX h%s w%s' "$(_fmt_pct "$h")" "$(_fmt_pct "$w")"
}

printf '%s %s' "$(format_claude)" "$(format_codex)"
