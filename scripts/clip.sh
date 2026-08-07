#!/usr/bin/env bash
# clip.sh — clipboard history manager (cliphist + fuzzel).
#   ./clip.sh store          # run as daemon: wl-paste --watch cliphist store
#   ./clip.sh pick           # pick an entry and copy it (bound in niri)
#   ./clip.sh clear          # wipe history
set -euo pipefail
. "$(dirname "$0")/lib.sh"

case "${1:-pick}" in
  store) wl-paste --watch cliphist store & disown ;;
  clear) cliphist wipe && notify "clipboard" "history cleared" ;;
  pick)
    local sel
    sel="$(cliphist list | menu "clipboard: ")" || exit 1
    [ -n "$sel" ] && printf '%s' "$sel" | cliphist decode | wl-copy
    ;;
  *) echo "usage: $0 {store|pick|clear}" ;;
esac