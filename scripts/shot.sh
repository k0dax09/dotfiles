#!/usr/bin/env bash
# shot.sh — screenshots with annotation.
#   shot.sh region   # select area (slurp) → annotate in swappy → save+copy
#   shot.sh full     # current screen → save + copy
#   shot.sh window   # focused window → save + copy
set -euo pipefail
. "$(dirname "$0")/lib.sh"

DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/screenshots"
mkdir -p "$DIR"
TS="$(date +%Y-%m-%d_%H-%M-%S)"
OUT="$DIR/shot_$TS.png"

case "${1:-region}" in
  region)
    grim -g "$(slurp)" "$OUT"
    if command -v swappy >/dev/null 2>&1; then
      swappy -f "$OUT"           # annotate; saves back into $OUT
      notify "shot" "annotated → $OUT"
    else
      notify "shot" "saved → $OUT"
    fi
    wl-copy < "$OUT" 2>/dev/null || true
    ;;
  full)
    grim "$OUT"
    wl-copy < "$OUT" 2>/dev/null || true
    notify "shot" "saved → $OUT"
    ;;
  window)
    local geo; geo="$(niri msg focused-window 2>/dev/null | awk '/Geometry/{print $3}' | tr -d '()')"
    grim -g "$geo" "$OUT"
    wl-copy < "$OUT" 2>/dev/null || true
    notify "shot" "saved → $OUT"
    ;;
  *) echo "usage: $0 {region|full|window}" ;;
esac