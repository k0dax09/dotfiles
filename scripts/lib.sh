# lib.sh — shared helpers for niri dotfiles scripts.
# Source:  . "$(dirname "$0")/lib.sh"
#
# Намеренно НЕ ставим set -euo pipefail — это ответственность вызывающего скрипта.

# ── Разрешение пути до репозитория ─────────────────────────────────────────
# Ищем вверх от расположения lib.sh маркер (flake.nix + scripts/).
# Это работает и когда lib.sh лежит в репо, и когда он скопирован в
# ~/.local/bin (тогда найден не будет — тогда используем DOTFILES_DIR
# или $HOME/Dotfiles).
_resolve_repo() {
  if [ -n "${DOTFILES_DIR:-}" ] && [ -d "$DOTFILES_DIR" ]; then
    printf '%s\n' "$DOTFILES_DIR"; return
  fi
  local d; d="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
  while [ "$d" != "/" ]; do
    if [ -f "$d/flake.nix" ] && [ -d "$d/scripts" ]; then
      printf '%s\n' "$d"; return
    fi
    d="$(dirname "$d")"
  done
  printf '%s\n' "${HOME}/Dotfiles"
}
REPO_DIR="$(_resolve_repo)"; export REPO_DIR

XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
CACHE_DIR="$XDG_CACHE_HOME/dotfiles"
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
CURRENT_WALL="$CACHE_DIR/wallpaper"
BASE_WALLPAPERS="$REPO_DIR/wallpapers"

FUZZEL_BIN="${FUZZEL_BIN:-fuzzel}"
NOTIFY_BIN="${NOTIFY_BIN:-notify-send}"

mkdir -p "$CACHE_DIR"
[ -d "$WALLPAPER_DIR" ] || mkdir -p "$WALLPAPER_DIR"

# ----------- UI helpers -----------
menu()   { "$FUZZEL_BIN" --dmenu --prompt "$1"; }
notify() { "$NOTIFY_BIN" "$1" "$2"; }

# ----------- Paths -----------
out() { echo "$CACHE_DIR/apps/$1/$2"; }
