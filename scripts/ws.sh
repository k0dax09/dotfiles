#!/usr/bin/env bash
# ws.sh — visual workspace switcher (pick a desktop via fuzzel).
# Использует JSON-вывод niri, а не парсинг человекочитаемого текста.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

active="$(niri msg -j workspaces 2>/dev/null \
  | jq -r '.[] | select(.is_active) | .idx' \
  | head -1)"
active="${active:-1}"

sel="$(
  for i in $(seq 1 9); do
    if [ "$i" = "$active" ]; then
      printf '●  workspace %s\n' "$i"
    else
      printf '   workspace %s\n' "$i"
    fi
  done | menu "workspaces: "
)" || exit 0

n="$(printf '%s' "$sel" | grep -oE '[0-9]+$' || true)"
[ -n "$n" ] && niri msg action focus-workspace "$n"
