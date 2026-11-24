#!/usr/bin/env bash

set - Eeui pipefail

# ============================
# For ubuntu
# created on : 25 November 2026
# remember to run : chmod +x `setup.sh` before running `./setup.sh`
# ============================

REPO_ROOT= "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_DIR="${HOME}/.config"

if [[ ! -d "$REPO_ROOT/bspwm" || ! -f "$REPO_ROOT/bspwm/bspwmrc" ]]; then
    error "This does not appear to be the repository root."
    exit 1
fi

if [[ ! -w "$HOME" ]]; then
    error "Your home directory is not writable: $HOME"
    exit 1
fi

info "Repository: $REPO_ROOT"
info "Configuration directory: $CONFIG_DIR"