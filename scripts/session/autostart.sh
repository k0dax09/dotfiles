#!/usr/bin/env bash
#
# autostart.sh — apps spawned at niri session start.
set -euo pipefail

# ── Обои ────────────────────────────────────────────
if [ -f "$HOME/.cache/dotfiles/wallpaper" ]; then
  swaybg -i "$HOME/.cache/dotfiles/wallpaper" -m fill &
fi

# ── Clipboard history ───────────────────────────────
clip.sh store &

# ── Password manager ────────────────────────────────
keepassxc --minimized --tray-start-hidden &

# ── Трей-апплеты ────────────────────────────────────
nm-applet --indicator &
blueman-applet &

# ── Polkit-агент (для GUI-запросов пароля) ──────────
POLKIT_AGENT=""
for candidate in \
  /run/current-system/sw/libexec/polkit-gnome-authentication-agent-1 \
  /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 \
  /usr/libexec/polkit-gnome-authentication-agent-1
do
  [ -x "$candidate" ] && { POLKIT_AGENT="$candidate"; break; }
done
if [ -n "$POLKIT_AGENT" ]; then
  "$POLKIT_AGENT" &
fi

# ── swayosd (красивый OSD) ──────────────────────────
if command -v swayosd-server >/dev/null 2>&1; then
  swayosd-server &
fi

# eww daemon
if command -v eww >/dev/null 2>&1; then
  eww daemon &
  sleep 0.5
fi

# ── Опционально: ночной фильтр ──────────────────────
# gammastep -O 4500 &

# ── Опционально: idle-лок (управляется сервисом) ────
# hypridle &
