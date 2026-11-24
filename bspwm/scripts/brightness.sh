
#!/usr/bin/env bash

case "$1" in
    up)
        brightnessctl -d amdgpu_bl1 set 10%+
        ;;
    down)
        brightnessctl -d amdgpu_bl1 set 10%-
        ;;
    *)
        exit 1
        ;;
esac

brightness=$(brightnessctl -d amdgpu_bl1 info | grep -oP '\(\K[0-9]+(?=%\))')

dunstify -a brightness -u low \
    -h int:value:"$brightness" \
    -h string:x-dunst-stack-tag:brightness \
    "Brightness" "$brightness%"