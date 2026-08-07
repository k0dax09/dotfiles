# NixOS module: Tor client.
#
# Thin wrapper over nixpkgs `services.tor` in *pure client* mode (SOCKS proxy,
# NO relay, NO exit traffic). The actual underscored runtime config is generated
# by nixpkgs from `services.tor.settings`; `config/tor/torrc` is kept as a
# human-readable reference mirroring these same values.
#
# Usage (via modules/nixos aggregator → in hosts/<host>/default.nix):
#   services.torclient = {
#     enable = true;
#     socksPort = 9050;
#     controlPort = 9051;            # null → no control port
#   };

{ config, lib, pkgs, ... }:

let
  cfg = config.services.torclient;
  inherit (lib) mkOption mkIf;
in
{
  options.services.torclient = {
    enable = lib.mkEnableOption "Tor client (SOCKS proxy)";
    socksPort = mkOption {
      type = lib.types.port;
      default = 9050;
      description = "Local SOCKS proxy port Tor listens on.";
    };
    controlPort = mkOption {
      type = lib.types.nullOr lib.types.port;
      default = 9051;
      description = "Local ControlPort for nyx/control tools. null to disable.";
    };
  };

  config = mkIf cfg.enable {
    services.tor = {
      enable = true;
      # Pure client: no relay, no exit traffic.
      settings = {
        SocksPort = [ "127.0.0.1:${toString cfg.socksPort}" ];
      } // lib.optionalAttrs (cfg.controlPort != null) {
        ControlPort = [ "127.0.0.1:${toString cfg.controlPort}" ];
      };
    };

    environment.systemPackages = with pkgs; [
      tor               # the daemon (also pulled by services.tor)
      torsocks          # wrap any binary: `torsocks curl ...`
      nyx               # terminal Tor monitor (uses ControlPort)
    ];
  };
}