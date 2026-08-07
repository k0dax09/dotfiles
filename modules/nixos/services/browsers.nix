# NixOS module: browsers — Helium as default, LibreWolf optional.
#
# Usage in hosts/<host>/default.nix (via modules/nixos aggregator):
#   imports = [ ./modules/nixos/services/browsers.nix ];
#   services.browsers = {
#     enable = true;
#     default = "helium";              # "helium" | "librewolf"
#     doh = true;
#     blockTrackers = true;
#   };

{ config, lib, pkgs, ... }:

let
  cfg = config.services.browsers;
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.services.browsers = {
    enable = mkEnableOption "browsers";
    default = mkOption {
      type = types.enum [ "helium" "librewolf" ];
      default = "helium";
      description = "Browser to install and expose as default (Mod+B).";
    };
    doh = mkOption {
      type = types.bool;
      default = true;
      description = "Force DNS-over-HTTPS in the browser.";
    };
    blockTrackers = mkOption {
      type = types.bool;
      default = true;
      description = "Enable strict tracking/fingerprint protection.";
    };
  };

  config = lib.mkIf cfg.enable {
    # ── Helium: default, hardened by design ──────────────────────────────
    environment.systemPackages = with pkgs; [
      (lib.mkIf (cfg.default == "helium") helium)
    ];

    # ── LibreWolf (optional, Firefox-based): deep policy hardening ───────
    programs.librewolf = lib.mkIf (cfg.default == "librewolf") {
      enable = true;
      policies = {
        DisableAppUpdate = true;
        NoDefaultBookmarks = true;
        DontCheckDefaultBrowser = true;
        SearchBar.DefaultSearchEngine = "DuckDuckGo";
        SearchBar.DefaultSearchEngine.Url = "https://duckduckgo.com/?q=";
        EnableTrackingProtection = { Value = true; Locked = true; };
        DNSOverHTTPS = {
          Enabled = cfg.doh;
          Locked = true;
          Fallback = false;
          ProviderURL = "https://cloudflare-dns.com/dns-query";
        };
        Preferences = {
          "privacy.fingerprinting_protection" = cfg.blockTrackers;
          "privacy.trackingprotection.enabled" = true;
          "privacy.resistFingerprinting" = true;
          "network.http.referer.XOriginTrimmingPolicy" = 2;
        };
      };
    };
  };
}