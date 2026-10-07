#!/usr/bin/env bash
# rec.sh — toggle screen recording (wf-recorder).
#   rec.sh         # start/stop; saves to ~/Videos/Recordings/rec_<ts>.mp4
#   rec.sh stop    # stop only
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
mkdir -p "$DIR"
PIDFILE="$CACHE_DIR/rec.pid"
OUTFILE="$CACHE_DIR/rec.path"

status() { [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; }

stop() {
  if status; then
    kill -INT "$(cat "$PIDFILE")" 2>/dev/null || true
    rm -f "$PIDFILE"
    notify "rec" "saved → $(cat "$OUTFILE" 2>/dev/null)"
  else
    rm -f "$PIDFILE"; notify "rec" "not recording"
  fi
}

start() {
  local out="$DIR/rec_$(date +%Y-%m-%d_%H-%M-%S).mp4"
  echo "$out" > "$OUTFILE"
  wf-recorder -g "$(slurp)" -f "$out" &
  echo $! > "$PIDFILE"
  notify "rec" "recording… (Mod+Ctrl+R to stop)"
}

case "${1:-toggle}" in
  toggle) if status; then stop; else start; fi ;;
  start)  start ;;
  stop)   stop ;;
  *) echo "usage: $0 {toggle|start|stop}" ;;
esac