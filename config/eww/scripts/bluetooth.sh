#!/usr/bin/env bash
case "${1:-status}" in
  status)
    if [ "$(bluetoothctl show 2>/dev/null | awk '/Powered:/{print $2}')" != "yes" ]; then
      echo "off"; exit
    fi
    mac="$(bluetoothctl devices Connected 2>/dev/null | awk '{print $2; exit}')"
    if [ -n "$mac" ]; then
      bluetoothctl info "$mac" 2>/dev/null | awk -F': ' '/Name/{print $2; exit}'
    else
      echo "on"
    fi ;;
  click) exec bluetooth.sh ;;
  *) echo "usage: $0 {status|click}" ;;
esac
