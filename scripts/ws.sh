#!/usr/bin/env bash
# ws.sh — visual workspace switcher (pick a desktop via fuzzel).
# Info comes from `niri msg workspaces` (active gets a marker).
set -euo pipefail
. "$(dirname "$0")/lib.sh"

# niri msg events/workspaces output format depends on version; map by name.
ws_menu() {
  local active line
  active="$(niri msg workspaces 2>/dev/null | awk '/active workspace/{print prev} {prev=$0}')"
  active="${active:-1}"

  for i in $(seq 1 9); do
    if [ "$i" = "$active" ]; then
      printf '●  %s\n' "workspace $i"
    else
      printf '      %s\n' "workspace $i"
    fi
    done | menu "workspaces: " | grep -oE '[0-9]+$' | { read -r n; [ -n "$n" ] && niri msg action focus-workspace "$n" 2>/dev/null || true; }
}

ws_menu