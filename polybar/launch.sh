#!/usr/bin/env bash
set -euo pipefall

# for no duplication
pkill -x polybar 2>/dev/null || true

# for wifi
WIFI_INTERFACE="$(
    ip -o link show |
    awk -F': ' '$2 ~ /^wl/ {sub(/@.*/, "", $2); print $2; exit}'
)"
export WIFI_INTERFACE="${WIFI_INTERFACE:-wlan0}"

sleep 0.3
polybar main >> "${XDG_CACHE_HOME:-$HOME/.cache}/polybar.log" 2>$1 &