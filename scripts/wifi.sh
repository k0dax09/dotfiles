#!/usr/bin/env bash
# wifi.sh — nmcli-based wifi menu.
#   ./wifi.sh               # interactive connect/disconnect menu
#   ./wifi.sh status        # one-line summary for waybar
set -euo pipefail
. "$(dirname "$0")/lib.sh"

status() {
  local active
  active="$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2-)"
  if [ -n "$active" ]; then
    echo "wifi: $active"
  elif [[ "$(nmcli radio wifi)" == enabled ]]; then
    echo "wifi: scanning"
  else
    echo "wifi: off"
  fi
}

connect() {
  nmcli radio wifi on
  local ap pass
  # list visible APs (name already known ones marked)
  ap="$(nmcli -t -f SSID,SIGNAL dev wifi list 2>/dev/null \
        | awk -F: '{printf "%s\t%s%%\n",$1,$2}' | sort -u \
        | menu "wifi: " | cut -f1)" || exit 1
  [ -z "$ap" ] && return
  if nmcli -t -f NAME connection show | grep -qxF "$ap"; then
    nmcli connection up id "$ap"
  else
    pass="$(menu_password "$ap")"
    nmcli device wifi connect "$ap" password "$pass"
  fi
  notify "wifi" "connected to $ap"
}

menu_password() {
  "$FUZZEL_BIN" --dmenu --password --prompt "password for $1: "
}

toggle() { nmcli radio wifi toggle; }

case "${1:-menu}" in
  status) status ;;
  toggle) toggle ;;
  up) connect ;;
  *) connect ;;
esac