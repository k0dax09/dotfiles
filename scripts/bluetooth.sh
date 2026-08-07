#!/usr/bin/env bash
# bluetooth.sh — bluetoothctl-based menu + waybar status.
#   ./bluetooth.sh           # interactive menu (power on/off, connect/disconnect)
#   ./bluetooth.sh status    # "bt: on/off + device" for waybar
set -euo pipefail
. "$(dirname "$0")/lib.sh"

BLUETOOTH="bluetoothctl"

status() {
  local powered mac name
  powered="$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2}')"
  if [ "$powered" = "yes" ]; then
    mac="$(bluetoothctl devices Connected 2>/dev/null | awk '{print $2}' | head -1)"
    if [ -n "$mac" ]; then
      name="$(bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/Name/{print $2}')"
      echo "bt: ${name:-$mac}"
    else
      echo "bt: on"
    fi
  else
    echo "bt: off"
  fi
}

menu() {
  local action
  action="$(printf 'power on\npower off\nconnect...\nscan on\nscan off\n' | menu "bluetooth: ")" || exit 1
  case "$action" in
    power\ on)  bluetoothctl power on ;;
    power\ off) bluetoothctl power off ;;
    scan\ on)   bluetoothctl scan on & disown ;;
    scan\ off)  bluetoothctl scan off ;;
    connect...)
      bluetoothctl power on
      local sel mac
      # menu lists "MAC  name", first token is the address
      sel="$(bluetoothctl devices 2>/dev/null | awk '{print $2"  "$3" "$4" "$5}' | menu "connect: ")" || exit 1
      mac="$(printf '%s' "$sel" | awk '{print $1}')"
      [ -n "$mac" ] && bluetoothctl connect "$mac"
      ;;
  esac
}

case "${1:-menu}" in
  status) status ;;
  menu) menu ;;
  *) menu ;;
esac