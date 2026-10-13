#!/usr/bin/env bash
# Network speed for status-right: "↓39K  ↑1.2M", each value in four columns.
#
# Only physical interfaces count (en* on macOS; on Linux, interfaces with a
# device link), so VPN tunnels, loopback and container bridges stay out and
# Wi-Fi or Ethernet is picked up without configuration. The rate divides by
# the real time between samples, and a sample under a second old is reused,
# so tmux clients refreshing together share one reading.
# Usage: tmux-net.sh <arrow colour> <value colour>

set -u

label=${1:-default}
value=${2:-default}
state="${TMPDIR:-/tmp}/tmux-net-$(id -u)"

# Milliseconds; tmux runs this with /bin/bash 3.2 on macOS, which has no
# EPOCHREALTIME.
now=$(perl -MTime::HiRes=time -e 'printf "%d", time * 1000')

t0="" rx0="" tx0="" out=""
if [ -r "$state" ]; then
    { read -r t0 rx0 tx0; IFS= read -r out; } <"$state"
fi
if [ -n "$t0" ] && [ -n "$out" ] && (( now - t0 < 1000 )); then
    printf '%s' "$out"
    exit 0
fi

# Total bytes received and sent on physical interfaces.
counters() {
    if [ "$(uname)" = Darwin ]; then
        # Link rows only. Count fields from the right: tunnel rows have no
        # address column.
        netstat -ibn | awk '$1 ~ /^en[0-9]+$/ && $3 ~ /^<Link/ { rx += $(NF-4); tx += $(NF-1) }
            END { printf "%.0f %.0f", rx, tx }'
    else
        local rx=0 tx=0 dev
        for dev in /sys/class/net/*; do
            [ -e "$dev/device" ] || continue
            rx=$((rx + $(<"$dev/statistics/rx_bytes")))
            tx=$((tx + $(<"$dev/statistics/tx_bytes")))
        done
        printf '%s %s' "$rx" "$tx"
    fi
}
read -r rx tx <<<"$(counters)"

out=$(awk -v t="$now" -v t0="$t0" -v rx="$rx" -v rx0="$rx0" -v tx="$tx" -v tx0="$tx0" \
          -v l="$label" -v v="$value" '
    function human(b) {
        if (b < 1024) return sprintf("%dB", b)
        if (b < 1048576) return sprintf("%dK", b / 1024)
        if (b < 10485760) return sprintf("%.1fM", b / 1048576)
        if (b < 1073741824) return sprintf("%dM", b / 1048576)
        return sprintf("%.1fG", b / 1073741824)
    }
    BEGIN {
        dt = (t - t0) / 1000
        # First sample, or the counters went backwards (interface reset).
        if (t0 == "" || dt <= 0 || rx < rx0 || tx < tx0) { d = "-"; u = "-" }
        else { d = human((rx - rx0) / dt); u = human((tx - tx0) / dt) }
        printf "#[fg=%s]↓#[fg=%s]%-4s #[fg=%s]↑#[fg=%s]%-4s", l, v, d, l, v, u
    }')

printf '%s %s %s\n%s\n' "$now" "$rx" "$tx" "$out" >"$state.$$" && mv -f "$state.$$" "$state"
printf '%s' "$out"
