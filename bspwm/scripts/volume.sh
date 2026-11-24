
#!/usr/bin/env bash

case "$1" in
    up)
        pactl set-sink-volume @DEFAULT_SINK@ +5%
        ;;
    down)
        pactl set-sink-volume @DEFAULT_SINK@ -5%
        ;;
    mute)
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        ;;
    *)
        exit 1
        ;;
esac

volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+(?=%)' | head -n 1)
muted=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')

if [ "$muted" = "yes" ]; then
    dunstify -a volume -u low \
        -h int:value:0 \
        -h string:x-dunst-stack-tag:volume \
        "Volume" "Muted"
else
    dunstify -a volume -u low \
        -h int:value:"$volume" \
        -h string:x-dunst-stack-tag:volume \
        "Volume" "$volume%"
fi
