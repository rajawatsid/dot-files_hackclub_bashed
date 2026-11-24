#!/usr/bin/env bash

i3lock \
    --blur=6 \
    \
    --inside-color=303E2A \
    --ring-color=71845B \
    --insidever-color=B9CC9B \
    --ringver-color=B9CC9B \
    --insidewrong-color=30201E \
    --ringwrong-color=A64B45 \
    --keyhl-color=B9CC9B \
    --bshl-color=C87970 \
    --ringwrong-color=C87970 \
    --insidewrong-color=30201E \
    \
    --line-color=00000000 \
    --separator-color=00000000 \
    --keyhl-color=B9CC9B \
    --bshl-color=A64B45 \
    \
    --verif-color=F2F5E9 \
    --wrong-color=A64B45 \
    --time-color=F2F5E9 \
    --date-color=91A477 \
    --layout-color=91A477 \
    \
    --timeoutline-color=263321FF \
    --dateoutline-color=263321FF \
    \
    --force-clock \
    --indicator \
    --radius=110 \
    --ring-width=4 \
    --line-color=00000000 \
    --separator-color=00000000 \
    \
    --time-str="%I:%M %p" \
    --date-str="%A, %d %B" \
    --time-font="JetBrainsMono Nerd Font" \
    --date-font="JetBrainsMono Nerd Font" \
    --time-size=72 \
    --date-size=20 \
    \
    --ind-pos="x+w/2:y+h/2" \
    --time-pos="ix:iy-200" \
    --date-pos="ix:iy-155" \
    \
    --verif-text="Verifying..." \
    --wrong-text="Nahhhhhhh"
    --noinput-text=""

    --verif-color=F2F5E9
    --wrong-color=C87970

    --verif-font="JetBrainsMono Nerd Font"
    --wrong-font="JetBrainsMono Nerd Font"

    --verif-size=16
    --wrong-size=16

    --show-failed-attempts \
    --ignore-empty-password