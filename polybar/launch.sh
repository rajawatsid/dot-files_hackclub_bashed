
#!/usr/bin/env bash
set -euo pipefail

# Prevent duplicates
pkill -x polybar 2>/dev/null || true

# wifi
WIFI_INTERFACE="$(
    nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null |
    awk -F: '$2 == "wifi" && $3 == "connected" {
        print $1
        exit
    }'
)"

# if no wifi is connected, use an available wifi adapter
if [[ -z "$WIFI_INTERFACE" ]]; then
    WIFI_INTERFACE="$(
        nmcli -t -f DEVICE,TYPE device status 2>/dev/null |
        awk -F: '$2 == "wifi" {
            print $1
            exit
        }'
    )"
fi

# Last-resort fallback
export WIFI_INTERFACE="${WIFI_INTERFACE:-wlan0}"


# log directory
mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}"

sleep 0.3

# Launch Polybar
polybar main >> "${XDG_CACHE_HOME:-$HOME/.cache}/polybar.log" 2>&1 &
