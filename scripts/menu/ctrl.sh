#!/usr/bin/env bash
# ctrl.sh — quick control center: volume, brightness, wifi, bluetooth.
# Bound in niri (Mod+Shift+C). Uses fuzzel as a compact toggle panel.
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

menu_ctrl() {
  local action
  action="$(printf '%s\n' \
      "volume up" "volume down" "volume mute" \
      "brightness up" "brightness down" \
      "wifi menu" "bluetooth menu" \
      "screen off" "toggle nightlight" \
    | menu "control: ")" || exit 1

  case "$action" in
    volume\ up)      wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ ;;
    volume\ down)    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    volume\ mute)    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
    brightness\ up)  brightnessctl set +5% ;;
    brightness\ down) brightnessctl set 5%- ;;
    wifi\ menu)      "$(dirname "$0")/wifi.sh" ;;
    bluetooth\ menu) "$(dirname "$0")/bluetooth.sh" ;;
    screen\ off)     niri msg action power-off-monitors ;;
    toggle\ nightlight) "$(dirname "$0")/nightlight.sh" toggle ;;
  esac
}

menu_ctrl