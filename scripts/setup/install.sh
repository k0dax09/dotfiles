#!/usr/bin/env bash
#
# install.sh — full dotfiles + NixOS setup for a fresh machine.
# Run from the repo root:  ./scripts/setup/install.sh
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

log()  { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

HOST="niri"

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "missing: $1"; }
need_cmd git
need_cmd nix

build_nixos() {
  log "Rebuilding NixOS configuration ($HOST)..."
  sudo nixos-rebuild switch --flake "$REPO_DIR#$HOST"
}

build_home() {
  log "Rebuilding home-manager..."
  if command -v home-manager >/dev/null 2>&1; then
    home-manager switch --flake "$REPO_DIR#$HOST"
  else
    nix run nixpkgs#home-manager -- switch --flake "$REPO_DIR#$HOST"
  fi
}

link_config() {
  log "Symlinking configs into \$HOME..."
  local src="$REPO_DIR/config"
  for dir in "$src"/*/; do
    local name; name="$(basename "$dir")"
    [ "$name" = "templates" ] && continue
    mkdir -p "$HOME/.config/$name"
    for f in "$dir"*; do
      ln -sfn "$f" "$HOME/.config/$name/$(basename "$f")"
    done
  done
}

main() {
  case "${1:-all}" in
    system) build_nixos ;;
    home)   build_home ;;
    links)  link_config ;;
    all)
      build_nixos
      build_home
      link_config
      ;;
    *) die "usage: $0 {system|home|links|all}" ;;
  esac
  log "Done."
}

main "$@"
