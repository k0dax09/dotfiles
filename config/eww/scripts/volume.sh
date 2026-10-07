#!/usr/bin/env bash
SINK="@DEFAULT_AUDIO_SINK@"
case "${1:-get}" in
  get)           wpctl get-volume "$SINK" 2>/dev/null | awk '{print int($2*100)}' ;;
  get-formatted) printf "%d%%\n" "$(wpctl get-volume "$SINK" 2>/dev/null | awk '{print int($2*100)}')" ;;
  set)           wpctl set-volume "$SINK" "$(awk -v v="$2" 'BEGIN{printf "%.2f", v/100}')" ;;
  *) echo "usage: $0 {get|get-formatted|set <0-100>}" ;;
esac
