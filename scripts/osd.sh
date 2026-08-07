#!/usr/bin/env bash
# osd.sh — volume & brightness with a progress notification (mako).
#   osd.sh volume up|down|mute
#   osd.sh bright up|down
set -euo pipefail
. "$(dirname "$0")/lib.sh"

SINK="@DEFAULT_AUDIO_SINK@"

vol_pct() {
  wpctl get-volume "$SINK" 2>/dev/null | awk '{printf "%d", $2*100}'
}

brt_pct() {
  brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'
}

show() { # <summary> <percent>
  notify-send -a "OSD" -u low -t 900 -h int:value:"$2" "$1"
}

case "${1:-}" in
  volume)
    case "${2:-}" in
      up)   wpctl set-volume "$SINK" 5%+ ;;
      down) wpctl set-volume "$SINK" 5%- ;;
      mute) wpctl set-mute   "$SINK" toggle ;;
    esac
    show "Volume  $(vol_pct)%" "$(vol_pct)"
    ;;
  bright)
    if [ "${2:-}" = up ]; then brightnessctl set +5%; else brightnessctl set 5%-; fi
    show "Brightness  $(brt_pct)%" "$(brt_pct)"
    ;;
  *) echo "usage: $0 {volume up|down|mute} | {bright up|down}" ;;
esac