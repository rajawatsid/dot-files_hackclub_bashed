#!/bin/bash

# How will this work?
# It should essentially move all the files that are in this repository (https://github.com/rajawatsid/dot-files_hackclub_bashed) to the users ~/.config directory
# basic flowchart of how it should work:
#     checks the location of where the user cloned the git repo -> checks if the user already has any files in the respective .config folder -> creates a backup of them in a new folder .config/[utc time]_config_backup/ (also ensuring that there is no former backup folder created in there) -> checks and installs any required dependencies -> moves the repos files and folders to their respective places -> gives a cute "tis done" prompt
#
# maybe add colours or whatever later


# variables
REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

# folders to copy
folders=("bspwm" "dunst" "i3lock" "kitty" "picom" "polybar" "rofi" "sxhkd" "conky")

# packages needed
packages=(
    bspwm
    sxhkd
    dunst
    kitty
    picom
    polybar
    rofi
    brightnessctl
    flameshot
    conky
    rsync
    git
)

# to make sure running as not-sudo
if [ "$EUID" -eq 0 ]; then
    echo "run this script as normal user, not sudo"
    echo "the script will ask for sudo only when it needs to install packages"
    exit 1
fi

# checking if this is a debian/ubuntu kinda system
if [ ! -f /etc/debian_version ]; then
    echo "this script currently only works on Debian/Ubuntu based systems"
    exit 1
fi

# checking if the repo files are actually here
if [ ! -d "$REPO_DIR/bspwm" ]; then
    echo "couldn't find repo files"
    echo "make sure setup.sh is inside the dot-files repository"
    exit 1
fi

# checking if the needed commands exist
for command in dpkg apt-get; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "couldn't find $command, something is wrong with this system"
        exit 1
    fi
done

mkdir -p "$CONFIG_DIR"

# old config backups with utc
BACKUP_NAME="$(date -u +"%Y%m%d_%H%M%S")_config_backup"
BACKUP_DIR="$CONFIG_DIR/$BACKUP_NAME"

# to check if backup is already there
i=1
while [ -e "$BACKUP_DIR" ]; do
    BACKUP_DIR="$CONFIG_DIR/${BACKUP_NAME}_$i"
    i=$((i + 1))
done

# checking which configs are already there
for folder in "${folders[@]}"; do

    # only back up folders that are also in this repo
    if [ -e "$CONFIG_DIR/$folder" ] && [ -d "$REPO_DIR/$folder" ]; then

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

if [ "${#missing[@]}" -gt 0 ]; then

    echo "Some packages are missing. Installing them..."

    if ! command -v sudo >/dev/null 2>&1; then
        echo "sudo is not installed. Ask an administrator to install these packages:"
        printf '  %s\n' "${missing[@]}"
        echo "then run this script again as your normal user"
        exit 1
    fi

    # asking for sudo before doing the installation thingy
    if ! sudo -v; then
        echo "couldn't get sudo permissions"
        echo "ask an administrator to install the missing packages, then run this script again"
        exit 1
    fi

    sudo apt-get update
    sudo apt-get install -y "${missing[@]}"

else
    echo "All dependencies are already installed!"
fi

# copying config files

echo "copying configs..."

for folder in "${folders[@]}"; do

    if [ -d "$REPO_DIR/$folder" ]; then

        mkdir -p "$CONFIG_DIR/$folder"
        rsync -av "$REPO_DIR/$folder/" "$CONFIG_DIR/$folder/"

        echo "Copied $folder"

    else
        echo "Couldn't find $folder, skipping..."
    fi

done

# a little reminder for i3lock-color
# this one needs to be installed separately, follow the instructions in the repo
echo ""
echo "................................................................................"
echo "-========= PLJ INSTALL i3lock-color =========-"
echo "Follow the installation instructions here:"
echo "https://github.com/Raymo111/i3lock-color"
echo "Your lock.sh uses i3lock-color features, so regular i3lock might not work."
echo "-=========-"
echo "................................................................................"
echo ""

# if all is done

echo ""
echo "tis done"
echo "this script has successfully copied all configs to $CONFIG_DIR"

echo ""
if [ -d "$BACKUP_DIR" ]; then
    echo "Old configs were backed up to: $BACKUP_DIR"
else
    echo "No old configs needed backing up!"
fi

echo "you might need to log out and select bspwm to use your new setup"