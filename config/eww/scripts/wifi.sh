#!/usr/bin/env bash
case "${1:-status}" in
  status)
    ssid="$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '/^yes/{print $2; exit}')"
    if [ -n "$ssid" ]; then echo "$ssid"
    elif [ "$(nmcli radio wifi 2>/dev/null)" = "enabled" ]; then echo "scanning"
    else echo "off"; fi ;;
  click) exec wifi.sh ;;
  *) echo "usage: $0 {status|click}" ;;
esac
