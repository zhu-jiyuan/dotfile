#!/usr/bin/env bash
# CPU usage for status-right: a sparkline of the last eight readings (about
# 24 seconds at status-interval 3), then the current reading as a whole
# percentage padded to two digits.
#
# tmux-plugin-sysstat supplies the reading, with one decimal ("38.0%"), and
# its colour. A reading joins the history at most once every two seconds, so
# tmux clients refreshing together don't fill it with duplicates.
# Usage: tmux-cpu.sh <sparkline colour>

set -u

spark=${1:-default}
hist="${TMPDIR:-/tmp}/tmux-cpu-$(id -u)"

out=$("$HOME/.config/tmux/plugins/tmux-plugin-sysstat/scripts/cpu.sh")
n=0
if [[ $out =~ ([0-9]+)\.([0-9])% ]]; then
    n=$((10#${BASH_REMATCH[1]} + (${BASH_REMATCH[2]} >= 5)))
    out=${out/"${BASH_REMATCH[0]}"/$(printf '%2d%%' "$n")}
fi

now=$(date +%s)
last=0 samples=""
if [ -r "$hist" ]; then
    read -r last samples <"$hist"
fi
if (( now - last >= 2 )); then
    set -- $samples "$n"
    while [ $# -gt 8 ]; do shift; done
    samples="$*"
    printf '%s %s\n' "$now" "$samples" >"$hist.$$" && mv -f "$hist.$$" "$hist"
fi

# Pad with spaces until eight readings exist, so the width never changes.
blocks=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
set -- $samples
line=""
for (( i = $#; i < 8; i++ )); do line="$line "; done
for v in "$@"; do
    level=$(( v * 8 / 100 ))
    (( level > 7 )) && level=7
    line="$line${blocks[level]}"
done

printf '#[fg=%s]%s %s' "$spark" "$line" "$out"
