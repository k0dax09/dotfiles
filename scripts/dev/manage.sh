#!/usr/bin/env bash
#
# manage.sh — quick daily driver helpers.
#   ./scripts/dev/manage.sh switch      # rebuild NixOS + home-manager
#   ./scripts/dev/manage.sh home        # only home-manager (fast)
#   ./scripts/dev/manage.sh links       # re-symlink configs only
#   ./scripts/dev/manage.sh status      # show branch / dirty state
#   ./scripts/dev/manage.sh format      # nixfmt all .nix files
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

log() { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }

do_switch() {
  log "Rebuilding home-manager..."
  home-manager switch --flake "$REPO_DIR#niri"
  log "Rebuilding NixOS ($(hostname))..."
  sudo nixos-rebuild switch --flake "$REPO_DIR"
  log "Reloading niri..."
  niri msg action quit 2>/dev/null || true
}

case "${1:-}" in
  switch) do_switch ;;
  system) sudo nixos-rebuild switch --flake "$REPO_DIR" ;;
  home)   home-manager switch --flake "$REPO_DIR#niri" ;;
  links)  bash "$REPO_DIR/scripts/setup/install.sh" links ;;
  status)
    git -C "$REPO_DIR" branch --show-current
    git -C "$REPO_DIR" status --short
    ;;
  format) nix fmt -- "$REPO_DIR" ;;
  *) echo "usage: $0 {switch|system|home|links|status|format}" ;;
esac
