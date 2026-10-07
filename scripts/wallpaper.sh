#!/usr/bin/env bash
# wallpaper.sh — pick a wallpaper, set it, regenerate colorscheme.
#   ./wallpaper.sh             # interactive (fuzzel) pick from $WALLPAPER_DIR
#   ./wallpaper.sh /path/img   # apply a specific image
set -euo pipefail
. "$(dirname "$0")/lib.sh"

COLOR_PY="$(dirname "$0")/colorscheme.py"

apply() {
  local img="$1"
  [ -f "$img" ] || { notify "wallpaper" "not found: $img"; exit 1; }
  cp "$img" "$CURRENT_WALL"

  # Restart swaybg with the new image (ВАЖНО: -i, не -c).
  pkill -x swaybg 2>/dev/null || true
  nohup swaybg -i "$CURRENT_WALL" -m fill >/dev/null 2>&1 &
  notify "wallpaper" "applied $(basename "$img")"

  # Regenerate color palette from the wallpaper.
  python3 "$COLOR_PY" "$CURRENT_WALL" || notify "colorscheme" "failed"
}

interactive() {
  local img
  {
    find "$WALLPAPER_DIR" -maxdepth 2 -type f \
      \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null
    find "$BASE_WALLPAPERS" -maxdepth 1 -type f \
      \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null
  } | sort | \
    while IFS= read -r f; do printf '%s\t%s\n' "$(basename "$f")" "$f"; done | \
    menu "wallpaper: " | cut -f2 > "$CACHE_DIR/.picked"
  img="$(cat "$CACHE_DIR/.picked")"
  [ -n "$img" ] && apply "$img"
}

[ "$#" -ge 1 ] && apply "$1" || interactive
