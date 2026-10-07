#!/usr/bin/env bash
# nightlight.sh — toggle blue-light filter (gammastep/wlsunset).
set -euo pipefail
. "$(dirname "$0")/lib.sh"

if pgrep -x gammastep >/dev/null 2>&1; then
  pkill -x gammastep
  notify "nightlight" "off"
else
  gammastep -O 3500 >/dev/null 2>&1 & disown
  notify "nightlight" "on (3500K)"
fi