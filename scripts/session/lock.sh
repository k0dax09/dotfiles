#!/usr/bin/env bash
# lock.sh — lock the session with swaylock (uses current wallpaper, blurred).
# Fallback to a plain color if no wallpaper is set.
set -euo pipefail

WALL="${HOME}/.cache/dotfiles/wallpaper"

ARGS=(--clock --indicator --fade-in 0.2 --grace 2)

if [ -f "$WALL" ]; then
  exec swaylock -i "$WALL" --effect-blur 7x3 "${ARGS[@]}"
else
  exec swaylock --color 0f1012 "${ARGS[@]}"
fi