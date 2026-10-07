#!/usr/bin/env bash
# media.sh — media info + playerctl control menu.
#   ./media.sh --current     # short now-playing for waybar
#   ./media.sh                # interactive control menu
set -euo pipefail
. "$(dirname "$0")/lib.sh"

current() {
  local playing="$(playerctl metadata --format '{{trunc(title,30)}} — {{artist}}' 2>/dev/null)"
  [ -n "$playing" ] && echo "$playing" || exit 1
}

menu_ctl() {
  local action
  action="$(printf 'play/pause\nnext\nprevious\nstop\nraise volume\nlower volume\n' | menu "media: ")" || exit 1
  case "$action" in
    play/pause)    playerctl play-pause ;;
    next)          playerctl next ;;
    previous)      playerctl previous ;;
    stop)          playerctl stop ;;
    raise\ volume) playerctl volume 0.05+ ;;
    lower\ volume) playerctl volume 0.05- ;;
  esac
}

case "${1:-}" in
  --current) current ;;
  *)         menu_ctl ;;
esac