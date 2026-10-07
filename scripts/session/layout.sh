#!/usr/bin/env bash
# layout.sh — показать текущую xkb-раскладку для waybar custom/layout.
# niri не отдаёт раскладку через msg, поэтому читаем из /proc или через
# xkb-switch, если установлен. Иначе — короткий код "us/ru" из $XKB_DEFAULT_LAYOUT.
set -euo pipefail

if command -v xkb-switch >/dev/null 2>&1; then
  xkb-switch -p
  exit 0
fi

# Fallback: первый layout из niri-конфига (см. config/niri/cfg/input.kdl)
LAYOUT="$(grep -oP 'layout "\K[^"]+' "$HOME/.config/niri/cfg/input.kdl" 2>/dev/null | head -1 || true)"
echo "${LAYOUT%%,*}"
