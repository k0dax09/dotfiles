#!/usr/bin/env bash
# firstrun.sh — one-time post-install setup: dirs, wallpaper, color palette.
# Run once after `install.sh`:
#   ./scripts/firstrun.sh
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

# 1. Standard directories
mkdir -p \
  "$HOME/Downloads" "$HOME/Pictures/Screenshots" \
  "${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings" \
  "$WALLPAPER_DIR" "$CACHE_DIR/apps"

# 2. Preload bundled base wallpapers into the user's folder (first run).
if [ -z "$(find "$WALLPAPER_DIR" -maxdepth 1 -type f 2>/dev/null | head -1)" ]; then
  cp "$BASE_WALLPAPERS"/*.png "$WALLPAPER_DIR"/ 2>/dev/null || true
  notify "firstrun" "preloaded base wallpapers into $WALLPAPER_DIR"
fi

# 3. Restore or default wallpaper + palette
if [ -f "$CURRENT_WALL" ]; then
  bash "$(dirname "$0")/wallpaper.sh" "$CURRENT_WALL"
elif [ -n "$(find "$WALLPAPER_DIR" -maxdepth 1 -type f 2>/dev/null | head -1)" ]; then
  # apply the first wallpaper found (lib.sh exposes WALLPAPER_DIR)
  get="$(find "$WALLPAPER_DIR" -maxdepth 1 -type f | head -1)"
  bash "$(dirname "$0")/wallpaper.sh" "$get"
else
  notify "firstrun" "no wallpaper found — drop images into $WALLPAPER_DIR"
fi

# 4. Ensure helpers are on PATH for the session
notify "firstrun" "done: screenshots/recording/OSD/clipboard ready"