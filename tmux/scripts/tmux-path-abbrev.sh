#!/usr/bin/env bash
# Abbreviate a path for tmux status-left, powerlevel10k-style.
# Usage: tmux-path-abbrev.sh <path>
#   - Replaces leading $HOME with ~
#   - If resulting length <= THRESHOLD, prints as-is
#   - Otherwise shortens every intermediate segment to its first character
#     (dotfile segments keep 2 chars so ".config" becomes ".c" not ".")

set -u

THRESHOLD=40
path="${1:-}"
[ -z "$path" ] && exit 0

path="${path%/}"
[ -z "$path" ] && path="/"

home="${HOME%/}"
if [ -n "$home" ]; then
    case "$path" in
        "$home")   path="~" ;;
        "$home"/*) path="~${path#"$home"}" ;;
    esac
fi

if [ "${#path}" -le "$THRESHOLD" ]; then
    printf '%s' "$path"
    exit 0
fi

prefix=""
rest="$path"
case "$path" in
    "~"|"~/"*)
        prefix="~"
        rest="${path#"~"}"
        ;;
esac

IFS='/' read -ra segments <<< "$rest"

non_empty_idx=()
for i in "${!segments[@]}"; do
    [ -n "${segments[$i]}" ] && non_empty_idx+=("$i")
done

if [ "${#non_empty_idx[@]}" -le 1 ]; then
    printf '%s' "$path"
    exit 0
fi

last_idx="${non_empty_idx[-1]}"
for i in "${non_empty_idx[@]}"; do
    if [ "$i" != "$last_idx" ]; then
        seg="${segments[$i]}"
        case "$seg" in
            .?*) segments[$i]="${seg:0:2}" ;;
            *)   segments[$i]="${seg:0:1}" ;;
        esac
    fi
done

joined=$(IFS='/'; printf '%s' "${segments[*]}")
printf '%s%s' "$prefix" "$joined"
