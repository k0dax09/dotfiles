# NixOS module: mini-VPN (sing-box / xray-core, TUN, all traffic via proxy).
{ config, lib, pkgs, ... }:

let
  cfg = config.services.anirevpn;
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.services.anirevpn = {
    enable = mkEnableOption "mini-VPN (sing-box TUN)";
    core = mkOption {
      type = types.enum [ "sing-box" "xray" ];
      default = "sing-box";
      description = "Which proxy core to run.";
    };
    autoStart = mkOption {
      type = types.bool;
      default = true;
      description = "Start the proxy automatically at boot (main-VPN mode).";
    };
    endpoint = mkOption {
      type = types.str;
      default = "";
      description = ''Proxy server "host:port". Used to whitelist the bootstrap
        connection in the kill-switch so the proxy itself can reach the server.
        Empty = fall back to allowing common proxy ports on any host.'';
    };
    killSwitch = mkOption {
      type = types.bool;
      default = true;
      description = ''Fail-closed nftables kill-switch: all egress must go through
        the tunnel (or to the proxy endpoint), IPv6 is blocked to prevent leaks.
        Loaded at boot, stays on even if the proxy is stopped.'';
    };
    configFile = mkOption {
      type = types.path;
      description = "Path to the core config JSON.";
    };
  };

  config = lib.mkIf config.services.anirevpn.enable {
    environment.etc."anirevpn/config.json".source = cfg.configFile;

    environment.systemPackages = with pkgs; [
      sing-box
      xray
      tun2socks
      wireguard-tools
      nftables
    ];

    # ── Fail-closed kill-switch (nftables) ────────────────────────────────
    systemd.services.anirevpn-killswitch = lib.mkIf cfg.killSwitch {
      description = "anirevpn kill-switch (fail-closed firewall)";
      wantedBy = [ "multi-user.target" ];
      before = [ "anirevpn.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.writeShellScript "anirevpn-killswitch-start" ''
          set -e
          ENDPOINT=''${ANIREVPN_ENDPOINT:-}
          HOST=''${ENDPOINT%%:*}
          ${pkgs.nftables}/bin/nft flush table inet anirevpn_kill 2>/dev/null || true
          ${pkgs.nftables}/bin/nft add table inet anirevpn_kill
          ${pkgs.nftables}/bin/nft add chain inet anirevpn_kill out '{ type filter hook output priority -300; policy drop; }'
          ${pkgs.nftables}/bin/nft add chain inet anirevpn_kill in '{ type filter hook input priority -300; policy drop; }'
          ${pkgs.nftables}/bin/nft add rule inet anirevpn_kill in ct state established,related accept
          ${pkgs.nftables}/bin/nft add rule inet anirevpn_kill in iifname "lo" accept
          ${pkgs.nftables}/bin/nft add rule inet anirevpn_kill out ct state established,related accept
          ${pkgs.nftables}/bin/nft add rule inet anirevpn_kill out oifname "lo" accept
          ${pkgs.nftables}/bin/nft add rule inet anirevpn_kill out oifname "anirevpn0" accept
          if [ -n "$HOST" ]; then
            ${pkgs.nftables}/bin/nft add rule inet anirevpn_kill out ip daddr "$HOST" udp dport {443,80,51820} accept
            ${pkgs.nftables}/bin/nft add rule inet anirevpn_kill out ip daddr "$HOST" tcp dport {443,80} accept
          fi
        ''}";
        ExecStop = "${pkgs.nftables}/bin/nft flush table inet anirevpn_kill 2>/dev/null || true";
        Environment = "ANIREVPN_ENDPOINT=${cfg.endpoint}";
      };
    };

    # ── The actual proxy service ──────────────────────────────────────────
    # mkMerge — иначе два присваивания systemd.services.anirevpn конфликтуют.
    systemd.services.anirevpn = lib.mkMerge [
      (lib.mkIf (cfg.core == "sing-box") {
        description = "mini-VPN (sing-box TUN)";
        after = [ "network-online.target" "anirevpn-killswitch.service" ];
        wants = [ "network-online.target" ];
        wantedBy = lib.mkIf cfg.autoStart [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.sing-box}/bin/sing-box run -c /etc/anirevpn/config.json";
          Restart = "on-failure";
          RestartSec = 5;
          CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" "CAP_NET_BIND_SERVICE" ];
          AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
          NoNewPrivileges = true;
          PrivateTmp = true;
        };
      })

      (lib.mkIf (cfg.core == "xray") {
        description = "mini-VPN (xray-core + tun2socks)";
        after = [ "network-online.target" "anirevpn-killswitch.service" ];
        wants = [ "network-online.target" ];
        wantedBy = lib.mkIf cfg.autoStart [ "multi-user.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.writeShellScript "anirevpn-xray" ''
            ${pkgs.xray}/bin/xray run -c /etc/anirevpn/config.json &
            sleep 1
            exec ${pkgs.tun2socks}/bin/tun2socks \
              -device anirevpn0 -proxy socks5://127.0.0.1:10808 -tunudp
          ''}";
          Restart = "on-failure";
          RestartSec = 5;
          CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
          AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
        };
      })
    ];
  };
}
