#!/usr/bin/env bash
# waybar-toggle.sh — show/hide the waybar top panel.
set -euo pipefail
command -v waybar >/dev/null 2>&1 || exit 0
if pgrep -x waybar >/dev/null 2>&1; then
  pkill -x waybar
else
  nohup waybar >/dev/null 2>&1 &
fi