# NixOS module: screen locker (swaylock) + auto-lock on idle (hypridle).
#
# Usage in hosts/<host>/default.nix (via modules/nixos aggregator):
#   imports = [ ./modules/nixos/services/lock.nix ];
#   services.lock = {
#     enable = true;
#     screenOffAfter = 45;   # seconds of idle before screens off
#     lockAfter = 12;        # minutes idle before locking
#   };
#
# The lock command is scripts/lock.sh: swaylock blurred over the current
# wallpaper. Bind it manually too: Mod+Alt+L → lock.sh

{ config, lib, pkgs, ... }:

let
  cfg = config.services.lock;
  inherit (lib) mkEnableOption mkOption types;

  # Build the lock script as a PATH-aware executable for both hypridle and niri.
  lockCmd = pkgs.writeShellApplication {
    name = "niri-lock";
    runtimeInputs = [ pkgs.swaylock ];
    text = builtins.readFile ../../scripts/lock.sh;
  };
in
{
  options.services.lock = {
    enable = mkEnableOption "swaylock + hypridle screen locking";
    screenOffAfter = mkOption {
      type = types.ints.positive;
      default = 45;
      description = "Seconds of idle before the monitors are powered off.";
    };
    lockAfter = mkOption {
      type = types.int;
      default = 12;
      description = "Minutes of idle before the screen locks (0 = never).";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ swaylock ];

    # Idle → lock + power-off monitors.
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "pidof swaylock || ${lockCmd}";
          unlock_cmd = "pkill -USR1 swaylock";
          before_sleep_cmd = "${lockCmd}";
          after_sleep_cmd = "niri msg action power-on-monitors";
        };
        listener = [
          {
            timeout = cfg.screenOffAfter;
            on-timeout = "niri msg action power-off-monitors";
          }
        ] ++ lib.optional (cfg.lockAfter > 0) {
          timeout = cfg.lockAfter * 60;
          on-timeout = "${lockCmd}";
        };
      };
    };
  };
}