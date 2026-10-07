#!/usr/bin/env bash
case "${1:-get}" in
  get)           brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,"",$4); print $4}' ;;
  get-formatted) printf "%s%%\n" "$(brightnessctl -m 2>/dev/null | awk -F, '{gsub(/%/,"",$4); print $4}')" ;;
  set)           brightnessctl set "$2%" ;;
  *) echo "usage: $0 {get|get-formatted|set <0-100>}" ;;
esac
