# NixOS module: graphical login screen (greetd + tuigreet).
#
# Usage in hosts/<host>/default.nix (via modules/nixos aggregator):
#   imports = [ ./modules/nixos/services/login.nix ];
#   services.login = {
#     enable = true;
#     autoLogin = false;
#     autoLoginUser = "user";
#   };
#
# Note: greetd launches the session via `niri-session`. If you also have
# `programs.niri.enable = true`, it may set greetd's default session too — if
# `nixos-rebuild` complains about a conflicting definition, drop
# `programs.niri.enable` (the session is fully managed here).

{ config, lib, pkgs, ... }:

let
  cfg = config.services.login;
  inherit (lib) mkEnableOption mkOption types;
  niriSession = "${pkgs.niri}/bin/niri-session";
in
{
  options.services.login = {
    enable = mkEnableOption "greetd login screen";
    autoLogin = mkOption {
      type = types.bool;
      default = false;
      description = "Skip the login screen and boot straight into the session.";
    };
    autoLoginUser = mkOption {
      type = types.str;
      default = "user";
      description = "User to auto-login when autoLogin is enabled.";
    };
  };

  config = lib.mkIf cfg.enable {
    # A dedicated, unprivileged user to run the greeter itself.
    users.users.greeter = {
      isNormalUser = true;
      description = "greetd greeter user";
      group = "greeter";
    };
    users.groups.greeter = { };

    services.greetd = {
      enable = true;
      settings = {
        # Auto-login straight into niri (used on boot when autoLogin).
        initial_session = lib.mkIf cfg.autoLogin {
          user = cfg.autoLoginUser;
          command = niriSession;
        };
        # Greeter shown on logout / when autoLogin is off.
        default_session = {
          user = "greeter";
          command = lib.mkIf cfg.autoLogin
            niriSession
            (lib.concatStringsSep " " [
              "${pkgs.greetd.tuigreet}/bin/tuigreet"
              "--time"
              "--remember"
              "--cmd ${niriSession}"
            ]);
        };
      };
    };
  };
}