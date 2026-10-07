#!/usr/bin/env bash
if pgrep -x gammastep >/dev/null 2>&1; then
  pkill -x gammastep
  notify-send "nightlight" "off"
else
  gammastep -O 3500 >/dev/null 2>&1 & disown
  notify-send "nightlight" "on (3500K)"
fi
