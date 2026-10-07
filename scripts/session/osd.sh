#!/usr/bin/env bash
# osd.sh — volume & brightness OSD (swayosd).
#   osd.sh volume up|down|mute
#   osd.sh bright up|down
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

SINK="@DEFAULT_AUDIO_SINK@"

have_swayosd() { command -v swayosd-client >/dev/null 2>&1; }

case "${1:-}" in
  volume)
    if have_swayosd; then
      case "${2:-}" in
        up)   swayosd-client --output-volume raise ;;
        down) swayosd-client --output-volume lower ;;
        mute) swayosd-client --output-volume mute-toggle ;;
      esac
    else
      case "${2:-}" in
        up)   wpctl set-volume "$SINK" 5%+ ;;
        down) wpctl set-volume "$SINK" 5%- ;;
        mute) wpctl set-mute   "$SINK" toggle ;;
      esac
      pct="$(wpctl get-volume "$SINK" 2>/dev/null | awk '{printf "%d", $2*100}')"
      notify-send -a OSD -u low -t 900 -h int:value:"$pct" "Volume  ${pct}%"
    fi
    ;;
  bright)
    if have_swayosd; then
      case "${2:-}" in
        up)   swayosd-client --brightness raise ;;
        down) swayosd-client --brightness lower ;;
      esac
    else
      if [ "${2:-}" = up ]; then brightnessctl set +5%; else brightnessctl set 5%-; fi
      pct="$(brightnessctl -m | awk -F, '{gsub(/%/,"",$4); print $4}')"
      notify-send -a OSD -u low -t 900 -h int:value:"$pct" "Brightness  ${pct}%"
    fi
    ;;
  *) echo "usage: $0 {volume up|down|mute} | {bright up|down}" ;;
esac
