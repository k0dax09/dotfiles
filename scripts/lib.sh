# lib.sh — shared helpers for niri dotfiles scripts.
# Source:  . "$(dirname "$0")/lib.sh"
set -euo pipefail

XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
CACHE_DIR="$XDG_CACHE_HOME/dotfiles"
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
CURRENT_WALL="$CACHE_DIR/wallpaper"

# Base wallpapers bundled in the repo (see scripts/gen-wallpapers.py).
BASE_WALLPAPERS="$REPO_DIR/wallpapers"

FUZZEL_BIN="${FUZZEL_BIN:-fuzzel}"
NOTIFY_BIN="notify-send"

# Resolve the real repo location even when scripts are symlinked into PATH
# (e.g. ~/.local/bin). lib.sh lives at <repo>/lib/lib.sh.
_DOTFILES_LIB="$(readlink -f "${BASH_SOURCE[0]}")"
REPO_DIR="$(dirname "$(dirname "$_DOTFILES_LIB")")"
export REPO_DIR

mkdir -p "$CACHE_DIR"
[ -d "$WALLPAPER_DIR" ] || mkdir -p "$WALLPAPER_DIR"

# ----------- UI helpers -----------
# Pick one line from stdin via a fuzzel dmenu.
menu() { # menu <prompt> ; reads choices on stdin, echoes chosen (or exits 2)
  "$FUZZEL_BIN" --dmenu --prompt "$1"
}

notify() { # notify <summary> <body>
  "$NOTIFY_BIN" "$1" "$2"
}

# ----------- Paths -----------
out() { # out <app> <relative>  -> ~/.cache/dotfiles/<app>/<relative>
  echo "$CACHE_DIR/apps/$1/$2"
}