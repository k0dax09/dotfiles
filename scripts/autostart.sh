#!/usr/bin/env bash
#
# autostart.sh — apps spawned at niri session start (see config/niri/cfg/autostart.kdl).
# Installed to ~/.local/bin and invoked once per session.
set -euo pipefail

# Wallpaper + palette (restore last one).
if [ -f "$HOME/.cache/dotfiles/wallpaper" ]; then
  swaybg -c "$HOME/.cache/dotfiles/wallpaper" -m fill &
fi

# Clipboard history daemon (cliphist).
clip.sh store &

# Password manager (tray, unlocked on demand).
keepassxc --minimized --tray-start-hidden &

# Status / tray / notification apps:
# waybar is already spawned by niri (spawn-at-startup); add trays here:
# nm-applet &     # networkmanager tray
# blueman-applet & # bluetooth tray

# Blue-light filter placeholder (toggle with ctrl.sh):
# gammastep -O 4500 &

# Compositor-adjacent helpers (optional):
# hypridle &   # idle / dpms
