#!/usr/bin/env bash
set -euo pipefail

REPO="rajawatsid/dot-files_hackclub_bashed"
DEST="${DOTFILES_DIR:-$HOME/.dotfiles}"

command -v curl >/dev/null || { echo "curl is required"; exit 1; }
command -v tar  >/dev/null || { echo "tar is required";  exit 1; }

# Use the latest GitHub release if one exists, otherwise fall back to main
REF="${DOTFILES_REF:-}"
if [ -z "$REF" ]; then
  url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
        "https://github.com/$REPO/releases/latest" || true)
  case "$url" in
    */releases/tag/*) REF="${url##*/}" ;;
    *)                REF="main" ;;
  esac
fi

echo "==> Installing $REPO ($REF) into $DEST"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "https://github.com/$REPO/archive/$REF.tar.gz" | tar -xz -C "$tmp" --strip-components=1

# Replace the previous download but keep nothing else of the user's files
rm -rf "$DEST"
mv "$tmp" "$DEST"
trap - EXIT

cd "$DEST"
chmod +x setup.sh

# Reconnect stdin to the terminal so setup.sh prompts still work when piped
if [ -t 0 ] || [ ! -r /dev/tty ]; then
  bash setup.sh "$@"
else
  bash setup.sh "$@" </dev/tty
fi