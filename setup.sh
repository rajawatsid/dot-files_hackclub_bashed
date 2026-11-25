#!/bin/bash 
:'
# How will this work?
It should essentially move all the files that are in this repository (https://github.com/rajawatsid/dot-files_hackclub_bashed) to the users ~/.config directory
basic flowchart of how it should work:
    checks the location of where the user cloned the git repo -> checks if the user already has any files in the respective .config folder -> creates a backup of them in a new folder .config/[utc time]_config_backup/ (also ensuring that there is no former backup folder created in there) -> checks and installs any required dependencies -> moves the repos files and folders to their respective places -> gives a cute "tis done" prompt

maybe add colours or whatever later
'

# variables
REPO_DIR="$(cd "$(dirname "${BASH_COURCE[0]}")") && pwd)"
CONIG_DIR="$HOME/.config"

# folders to copy
folders=("bspwm" "dunst" "i3lock" "kitty" "picom" "polybar" "rofi" "sxhkd" "conky")

# packages needed
# add steps to have i3lock-color later
packages=(
    bspwm
    sxhkd
    dunst-
    kitty
    picom
    polybar
    rofi
    brightnessctl
    flameshot
)

# to make sure running as not-sudo
if [ "$EUID" -eq 0 ]; then
    echo "run this script as normal user not root"
    exit 1
fi

if [ ! -d "$REPO_DIR/bspwm" ]; then
    echo "couldn't find repo files"
    exit 1
fi

mkdir -p "$CONFIG_DIR"

# old config backups with utc
BACKUP_NAME="$(date -u + "%Y%m%d_%H%M%S)_config_backup"
BACKUP_DIR="$CONFIG_DIR/$BACKUP_NAME"

# to check if backup is alreedy there
i=1
while [ -e "$BACKUP_DIR" ]; do
    BACKUP_DIR="$CONFIG_DIR/${BACKUP_NAME}_$i"
    i=$((i + 1))
done

# checking which configs are already there
for folder in "${folders[@]}"; do

    if [ -e "$CONFIG_DIR/$folder" ]; then

        # to make it only when needed
        mkdir -p "$BACKUP_DIR"

        echo "Backing up $folder..."

        cp -a "$CONFIG_DIR/$folder" "$BACKUP_DIR/"

    fi

done

# installing dependencies

echo "checking dependencies..."

missing=()

for package in "${packages[@]}"; do

    if ! dpkg -s "$package" >/dev/null 2>&1; then
        missing+=("$package")
    fi

done

if [ ${#missing[@]} -gt 0 ]; then

    echo "Some packages are missing. Installing them..."

    if ! command -v sudo >/dev/null 2>&1; then
        echo "sudo is required to install packages."
        exit 1
    fi

    sudo apt-get update
    sudo apt-get install -y "${missing[@]}"

else
    echo "All dependencies are already installed!"
fi


# copying config files

for folder in "${folders[@]}"; do

    if [ -d "$REPO_DIR/$folder" ]; then

        cp -a "$REPO_DIR/$folder" "$CONFIG_DIR/"

        echo "Copied $folder"

    else
        echo "Couldn't find $folder, skipping..."
    fi

done

# if all is  done

echo ""
echo "its done"
echo "this script has successfully copies all configs to $CONFIG_DIR"

if [ -d "$BACKUP_DIR" ]; then
    echo "Old configs were backed up to: $BACKUP_DIR"
fi

echo "you might need to log out and select bspwm to use your new setup"