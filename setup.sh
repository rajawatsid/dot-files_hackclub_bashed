#!/usr/bin/env bash

set -euo pipefail



# ============================
# For ubuntu
# created on : 25 November 2026
# remember to run : chmod +x `setup.sh` before running `./setup.sh`
# ============================

# add clours

info() {
    echo "[INFO] $*"
}

success() {
    echo "[OK] $*"
}

warn() {
    echo "[WARN] $*"
}

error() {
    echo "[ERROR] $*" >&2
}

# -------------------- Repository --------------------


REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_DIR="${HOME}/.config"

if [[ ! -d "$REPO_ROOT/bspwm" || ! -f "$REPO_ROOT/bspwm/bspwmrc" ]]; then
    error "this is not appear to be repo root."
    exit 1
fi

if [[ ! -w "$HOME" ]]; then
    error "your home directory isn't writable: $HOME"
    exit 1
fi

info "Repository: $REPO_ROOT"
info "Configuration directory: $CONFIG_DIR"
# -------------------- OS detection --------------------

# maybe add more distro support or something, only possible if able to get hands on experience with that


if [[ ! -r /etc/os-release ]]; then
    error "Cannot identify the operating system."
    error "This script supports Ubuntu-based systems only."
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

OS_ID="${ID:-unknown}"
OS_LIKE="${ID_LIKE:-}"

if [[ "$OS_ID" != "debian" && "$OS_ID" != "ubuntu" &&
      " $OS_LIKE " != *" debian "* &&
      " $OS_LIKE " != *" ubuntu "* ]]; then
    error "Unsupported distribution: $OS_ID"
    error "No system changes have been made."
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    error "apt-get was not found."
    error "This script needs Ubuntu"
    exit 1
fi

# -------------------- Package definitions --------------------

# These are main things i'd want on desktop.
# might split this list up more later if it gets too long.


# These packages provide the commands and applications used
# by the repository's existing configuration.

BASE_PACKAGES=(
    bspwm
    sxhkd
    rofi
    kitty
    picom
    dunst
    polybar
    feh
    conky
    xinput
    x11-xserver-utils
    flameshot
    nemo
    xdg-utils
    network-manager
    pulseaudio-utils
    brightnessctl
    fonts-papirus-icon-theme
    fonts-noto-core
    fonts-noto-color-emoji
    fonts-jetbrains-mono
)

NERD_FONT_PACKAGES=(
    fonts-jetbrains-mono-nerd
    fonts-nerd-fonts-jetbrains-mono
)

# idt i3lock-color should be mandatory
LOCK_PACKAGES=(
    i3lock-color
)

AVAILABLE_PACKAGES=()
UNAVAILABLE_PACKAGES=()
INSTALLED_PACKAGES=()
FAILED_PACKAGES=()

NERD_FONT_AVAILABLE=false
LOCK_PACKAGE_AVAILABLE=false
FONT_FALLBACK_AVAILABLE=false

# -------------------- Privilege detection --------------------

APT_PREFIX=()

if [[ "$EUID" -eq 0 ]]; then
    info "Running as root. Package installation can proceed."
    APT_PREFIX=()
elif command -v sudo >/dev/null 2>&1; then
    info "Checking sudo authorization..."

    if sudo -v; then
        APT_PREFIX=(sudo)
        success "Sudo authorization available"
    else
        warn "Sudo authorization unavailable"
    fi
else
    warn "sudo is not installed"
fi

CAN_INSTALL=false

if [[ "$EUID" -eq 0 ]] || (( ${#APT_PREFIX[@]} > 0 )); then
    CAN_INSTALL=true
fi

# -------------------- Package installation --------------------

package_available() {
    local package="$1"

    apt-cache show "$package" >/dev/null 2>&1
}

select_packages() {
    local package

    for package in "${BASE_PACKAGES[@]}"; do
        if package_available "$package"; then
            AVAILABLE_PACKAGES+=("$package")
        else
            UNAVAILABLE_PACKAGES+=("$package")
        fi
    done

    #  jerbrains monofont check
    for package in "${NERD_FONT_PACKAGES[@]}"; do
        if package_available "$package"; then
            AVAILABLE_PACKAGES+=("$package")
            NERD_FONT_AVAILABLE=true
            break
        fi
    done

    # If a patched font is unavailable, install regular
    # JetBrains Mono if the package exists.
    if [[ "$NERD_FONT_AVAILABLE" == false ]] &&
       package_available "fonts-jetbrains-mono"; then
        FONT_FALLBACK_AVAILABLE=true
    fi

    # checking i3lock color
    for package in "${LOCK_PACKAGES[@]}"; do
        if package_available "$package"; then
            AVAILABLE_PACKAGES+=("$package")
            LOCK_PACKAGE_AVAILABLE=true
            break
        fi
    done
}

install_packages() {
    local package

    if [[ "$CAN_INSTALL" == false ]]; then
        warn "Package installation skipped: administrative access unavailable"
        return 0
    fi

    info "Updating APT package lists..."

    if ! "${APT_PREFIX[@]}" apt-get update; then
        error "apt-get update failed"
        warn "Continuing with dotfile installation"
        return 0
    fi

    # Refresh package availability using the updated package lists.
    AVAILABLE_PACKAGES=()
    UNAVAILABLE_PACKAGES=()

    select_packages

    if (( ${#AVAILABLE_PACKAGES[@]} == 0 )); then
        warn "No installable packages were found"
        return 0
    fi

    info "Installing available packages..."

    printf '  %s\n' "${AVAILABLE_PACKAGES[@]}"

    if "${APT_PREFIX[@]}" apt-get install -y --no-install-recommends \
        "${AVAILABLE_PACKAGES[@]}"; then
        success "APT installation command completed"
    else
        error "Some package installations might have failed"
    fi

    # to verif actual instl status instead of assuming that a successful commnd means every package is there
    for package in "${AVAILABLE_PACKAGES[@]}"; do
        if dpkg-query -W -f='${Status}' "$package" 2>/dev/null |
            grep -qx 'install ok installed'; then
            INSTALLED_PACKAGES+=("$package")
        else
            FAILED_PACKAGES+=("$package")
        fi
    done
}

info "Checking package availability..."
select_packages

install_packages

# -------------------- Configuration installation --------------------

# now to putting the config folders in ~/.config.


mkdir -p "$CONFIG_DIR"

BACKUP_TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"

backup_destination() {
    local destination="$1"
    local backup="${destination}.backup-${BACKUP_TIMESTAMP}"

    # maybe not have overwriting on earlier backup if two runs happen within the same second.
    if [[ -e "$backup" || -L "$backup" ]]; then
        backup="${backup}-$$"
    fi

    mv -- "$destination" "$backup"

    success "Backed up existing configuration:"
    printf '       %s\n' "$backup"
}

install_config() {
    local name="$1"
    local source="${REPO_ROOT}/${name}"
    local destination="${CONFIG_DIR}/${name}"

    if [[ ! -d "$source" ]]; then
        warn "Skipping missing repository directory: $source"
        return 0
    fi
    if [[ -L "$destination" ]]; then
        local existing_target

        existing_target="$(readlink -f -- "$destination" 2>/dev/null || true)"

        if [[ "$existing_target" == "$source" ]]; then
            success "$name is already linked correctly."
            return 0
        fi

        backup_destination "$destination"

    elif [[ -e "$destination" ]]; then
        # Preserve existing user configurations
    # maybe ask before replacing these in a future version?

        backup_destination "$destination"
    fi

    if ln -s -- "$source" "$destination"; then
        success "Installed $name"
    else
        error "Could not install $name"
    fi
}

info "Installing configuration directories..."

CONFIGS=(
    bspwm
    sxhkd
    dunst
    i3lock
    kitty
    picom
    polybar
    rofi
)

for config in "${CONFIGS[@]}"; do
    install_config "$config"
done

# -------------------- Script permissions --------------------


info "Setting executable permissions..."

EXECUTABLES=(
    "$REPO_ROOT/bspwm/bspwmrc"
    "$REPO_ROOT/bspwm/scripts/brightness.sh"
    "$REPO_ROOT/bspwm/scripts/volume.sh"
    "$REPO_ROOT/polybar/launch.sh"
    "$REPO_ROOT/i3lock/lock.sh"
)

for script in "${EXECUTABLES[@]}"; do
    if [[ -f "$script" ]]; then
        if chmod +x "$script"; then
            success "Executable: ${script#"$REPO_ROOT"/}"
        else
            error "Could not set executable permission: $script"
        fi
    else
        warn "Missing script: $script"
    fi
done

# config warnings

# most of it looks like if else i think
printf '\n'
info "Checking optional configuration requirements..."

if [[ ! -f "$HOME/.config/conky/conkyrc" ]]; then
    warn "No Conky configuration was found."
    warn "bspwmrc attempts to start Conky using:"
    printf '       ~/.config/conky/conkyrc\n'
    warn "Conky is optional; this repository does not provide that file."
fi

if [[ "$NERD_FONT_AVAILABLE" == false ]]; then
    warn "JetBrainsMono Nerd Font was not available as an APT package"

    if [[ "$FONT_FALLBACK_AVAILABLE" == true ]]; then
        warn "Regular JetBrains Mono is available but it is NOT a Nerd Font"
    else
        warn "Regular JetBrains Mono was also unavailable"
    fi

    warn "Install the patched JetBrainsMono Nerd Font manually."
    warn "Use the official Nerd Fonts project:"
    printf '       https://github.com/ryanoasis/nerd-fonts\n'
    warn "Then refresh your font cache with: fc-cache -f"
fi

if [[ "$LOCK_PACKAGE_AVAILABLE" == false ]]; then
    warn "i3lock-color was not available in the configured APT repositories."
    warn "The lock script uses color-specific i3lock options."
    warn "Standard i3lock is NOT an equivalent replacement."
    warn "The Super+L lock shortcut may not work until i3lock-color is installed."
    warn "Check your distribution's trusted package repositories for i3lock-color."
fi

if ! command -v nmcli >/dev/null 2>&1; then
    warn "nmcli is unavailable."
    warn "Polybar's network interface detection requires NetworkManager tools."
fi

if ! command -v pactl >/dev/null 2>&1; then
    warn "pactl is unavailable"
    warn "The volume script requires a compatible PulseAudio/PipeWire audio setup."
    warn "No audio server has been installed or reconfigured."
fi

if ! command -v dunstify >/dev/null 2>&1; then
    warn "dunstify is unavailable; volume/brightness notifications may not work."
fi

if ! command -v brightnessctl >/dev/null 2>&1; then
    warn "brightnessctl is unavailable."
fi

if [[ ! -e /sys/class/backlight/amdgpu_bl1 ]]; then
    warn "The configured brightness device amdgpu_bl1 was not detected."
    warn "brightness.sh may need a device adjustment for this hardware."
    warn "The repository script has not been modified."
fi

# admin instruction

if [[ "$CAN_INSTALL" == false ]]; then
    printf '\n'
    warn "Packages could not be installed automatically."
    info "Run the following commands from an administrator account:"
    printf '\n'

    printf '  su <sudouser> or <->\n'
    printf '  apt-get update\n'
    printf '  apt-get install -y --no-install-recommends'

    for package in "${BASE_PACKAGES[@]}"; do
        printf ' %s' "$package"
    done

    printf '\n\n'

    info "Or, if your account has sudo authorization:"
    printf '\n'
    printf '  sudo apt-get update\n'
    printf '  sudo apt-get install -y --no-install-recommends'

    for package in "${BASE_PACKAGES[@]}"; do
        printf ' %s' "$package"
    done

    printf '\n\n'

    warn "Install i3lock-color separately if your APT repositories provide it:"
    printf '  apt-get install i3lock-color\n'
    printf '\n'

    info "The configuration files have still been installed where possible."
fi

# FINAL

# drhuv said to add outputs in a log file, find how to

printf '\n'
printf '%s\n' '============================================================'
printf '                         SETUP SUMMARY\n'
printf '%s\n' '............................................................'

printf '\n'
success "Configuration directories processed:"
for config in "${CONFIGS[@]}"; do
    if [[ -L "$CONFIG_DIR/$config" ]]; then
        printf '  - %s\n' "$config"
    fi
done

printf '\n'
if (( ${#INSTALLED_PACKAGES[@]} > 0 )); then
    success "Packages verified as installed:"
    printf '  - %s\n' "${INSTALLED_PACKAGES[@]}"
else
    warn "No packages were verified as newly installed"
fi

if (( ${#FAILED_PACKAGES[@]} > 0 )); then
    printf '\n'
    error "Package not verified as installed:"
    printf '  - %s\n' "${FAILED_PACKAGES[@]}"
fi

if (( ${#UNAVAILABLE_PACKAGES[@]} > 0 )); then
    printf '\n'
    warn "Packages unavailable in the checked APT package lists:"
    printf '  - %s\n' "${UNAVAILABLE_PACKAGES[@]}"
fi

printf '\n'
info "Important notes:"
printf '  - The repository is linked directly into ~/.config.\n'
printf '  - Keep this checkout in its current location.\n'
printf '  - Existing configurations were backed up before replacement.\n'
printf '  - The todo directory was not installed.\n'
printf '  - No .xinitrc or display-manager configuration was changed.\n'
printf '  - No network or audio configuration was changed.\n'

printf '\n'
info "Starting BSPWM:"
printf '  1. Log out of your current desktop session.\n'
printf '  2. At your display manager, select BSPWM from the session menu.\n'
printf '  3. Log in.\n'
printf '\n'
info "If you use startx, configure your own .xinitrc to start bspwm."
info "This script deliberately does not overwrite an existing .xinitrc."

printf '\n'
success "Setup script finished."
printf '%s\n' '============================================================'