#!/usr/bin/env bash

# my little power menu :D

bg="#879965"
bg_alt="#91A477"
fg="#263321"
fg_dim="#526347"
accent="#F2F5E9"
border="#71845B"
urgent="#A64B45"

# i want automatic length and breadth
get_width() {
    local longest=0

    for option in "$@"; do
        if (( ${#option} > longest )); then
            longest=${#option}
        fi
    done

    local width=$((250 + longest * 9))

    (( width < 340 )) && width=340
    (( width > 520 )) && width=520

    echo "$width"
}


show_menu() {
    local prompt="$1"
    shift

    local options=("$@")
    local width
    width=$(get_width "$prompt" "${options[@]}")

    printf '%s\n' "${options[@]}" | rofi \
        -dmenu \
        -i \
        -no-custom \
        -p "$prompt" \
        -lines "${#options[@]}" \
        -theme-str "
            window {
                width: ${width}px;
                background-color: ${bg};
                border: 2px;
                border-color: ${border};
                border-radius: 14px;
            }

            mainbox {
                background-color: ${bg};
                padding: 12px;
            }

            inputbar {
                background-color: ${bg};
                text-color: ${accent};
                padding: 8px;
                border: 0px;
            }

            prompt {
                text-color: ${accent};
            }

            entry {
                text-color: ${fg};
            }

            listview {
                lines: ${#options[@]};
                fixed-height: true;
                background-color: ${bg};
                spacing: 6px;
            }

            element {
                background-color: ${bg};
                text-color: ${fg};
                padding: 10px;
                border-radius: 8px;
            }

            element selected {
                background-color: ${bg_alt};
                text-color: ${fg};
            }

            element-text {
                text-color: inherit;
            }
        "
}


# for options
options=(
    "󰒲  Suspend"
    "󰐥  Power off"
    "󰤄  Hibernate"
    "󰜉  Restart"
)

# show the main menu
choice=$(show_menu "Power menu" "${options[@]}")

# escape or close is to do nothing
[[ -z "$choice" ]] && exit 0


confirm_action() {
    local action="$1"

    local answer
    answer=$(show_menu "Confirm?" \
        "Yes, $action" \
        "Cancel")

    [[ "$answer" == "Yes, $action" ]]
}


case "$choice" in

    "󰒲  Suspend")
        if confirm_action "suspend"; then
            systemctl suspend
        fi
        ;;

    "󰐥  Power off")
        if confirm_action "power off"; then
            systemctl poweroff
        fi
        ;;

    "󰤄  Hibernate")
        if confirm_action "hibernate"; then
            systemctl hibernate
        fi
        ;;

    "󰜉  Restart")
        if confirm_action "restart"; then
            systemctl reboot
        fi
        ;;

esac

exit 0
