#!/usr/bin/env bash
# vpn.sh — WireGuard toggle with a firewall kill-switch.
#
#   ./vpn.sh up      # bring wg0 up, drop all non-VPN traffic
#   ./vpn.sh down    # restore normal routing/firewall
#   ./vpn.sh status
#
# Requires a wg0 interface. Create it either in configuration.nix
# (networking.wireguard.interfaces.wg0) or a wg-quick file:
#   sudo nvim /etc/wireguard/wg0.conf   # → ifcfg, no manual IP needed
set -euo pipefail
. "$(dirname "$0")/lib.sh"

IFACE="wg0"
ENDPOINT="${VPN_ENDPOINT:-}"   # e.g. "vpn.example.com" — used to keep the tunnel reachable
# Firewall backend: prefer nftables, fall back to iptables.
FW="nft"
command -v nft >/dev/null 2>&1 || FW="iptables"

killswitch_on() {
  notify "vpn" "enabling kill-switch ($FW)"
  if [ "$FW" = "nft" ]; then
    # Allow only the tunnel + local, drop everything else that isn't the endpoint.
    nft flush table inet killswitch 2>/dev/null || true
    nft -f /dev/stdin <<'EOF'
table inet killswitch {
  chain out {
    type filter hook output priority 0; policy drop;
    ct state established,related accept
    iifname "lo" accept
    oifname "wg0" accept
    udp dport 51820 accept
    udp sport 51820 accept
  }
  chain in {
    type filter hook input priority 0; policy accept;
  }
}
EOF
  else
    iptables -P OUTPUT DROP
    iptables -A OUTPUT -o lo -j ACCEPT
    iptables -A OUTPUT -o "$IFACE" -j ACCEPT
    iptables -A OUTPUT -p udp --dport 51820 -j ACCEPT
    iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  fi
}

killswitch_off() {
  notify "vpn" "disabling kill-switch"
  if [ "$FW" = "nft" ]; then
    nft delete table inet killswitch 2>/dev/null || true
  else
    iptables -F OUTPUT
    iptables -P OUTPUT ACCEPT
  fi
}

case "${1:-status}" in
  up)
    command -v wg-quick >/dev/null 2>&1 || { notify "vpn" "wg-quick not installed"; exit 1; }
    wg-quick up "$IFACE"
    killswitch_on
    notify "vpn" "$IFACE up"
    ;;
  down)
    killswitch_off
    wg-quick down "$IFACE" 2>/dev/null || true
    notify "vpn" "$IFACE down"
    ;;
  status)
    if wg show "$IFACE" >/dev/null 2>&1; then
      echo "vpn: up ($(wg show "$IFACE" | awk '/endpoint/{print $2}'))"
    else
      echo "vpn: down"
    fi
    ;;
  *) echo "usage: $0 {up|down|status}" ;;
esac