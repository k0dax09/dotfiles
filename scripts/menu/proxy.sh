#!/usr/bin/env bash
# proxy.sh — toggle the mini-VPN (TUN, all traffic through proxy).
#
# sing-box (default): native TUN + auto_route + strict_route (kill-switch built in).
# xray-core (optional): local SOCKS/HTTP inbound + tun2socks to route all traffic.
#
#   ./proxy.sh toggle        # start if stopped, stop if running (default)
#   ./proxy.sh up
#   ./proxy.sh down
#   ./proxy.sh status
set -euo pipefail
. "$(dirname "$0")/../lib.sh"

CORE="${ANIREVPN_CORE:-sing-box}"      # sing-box | xray
SVC="anirevpn"                          # systemd unit for the active core

status() {
  if systemctl is-active --quiet "$SVC"; then
    echo "proxy: up ($CORE)"
  else
    echo "proxy: down"
  fi
}

up()   { systemctl start "$SVC"; notify "proxy" "$CORE up (TUN active)"; }
down() { systemctl stop "$SVC";  notify "proxy" "$CORE down"; }

case "${1:-toggle}" in
  toggle) status >/dev/null && down || up ;;
  up)     up ;;
  down)   down ;;
  status) status ;;
  *) echo "usage: $0 {toggle|up|down|status}" ;;
esac