#!/usr/bin/env bash
#
# bootstrap.sh — one-liner dotfiles installer.
#
#   Install on a fresh machine (NixOS or any Linux):
#     bash <(curl -fsSL https://raw.githubusercontent.com/k0dax09/dotfiles/main/bootstrap.sh)
#
# What it does:
#   1. Clones (or updates) k0dax09/dotfiles into ~/Dotfiles
#   2. Symlinks every dir in config/ into ~/.config/ (with backup of conflicts)
#   3. Links dotfiles that live in $HOME (zsh, etc.)
#   4. Installs scripts/ (including lib.sh) into ~/.local/bin and adds it to PATH
#   5. On NixOS: runs ./scripts/install.sh all (nixos-rebuild + home-manager)
#
set -euo pipefail

REPO_URL="https://github.com/k0dax09/dotfiles.git"
BRANCH="main"
REPO_DIR="${DOTFILES_DIR:-$HOME/Dotfiles}"

log()  { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"; }

# ─────────── 1. Clone / update the repo ───────────
fetch_repo() {
  log "Fetching dotfiles into $REPO_DIR"
  if [ -d "$REPO_DIR/.git" ]; then
    git -C "$REPO_DIR" fetch --quiet origin "$BRANCH"
    if git -C "$REPO_DIR" diff --quiet "$BRANCH" "origin/$BRANCH"; then
      log "Already up to date."
    else
      git -C "$REPO_DIR" reset --hard --quiet "origin/$BRANCH"
      log "Updated to latest."
    fi
  else
    git clone --quiet --depth 1 --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
    log "Cloned."
  fi
}

# ─────────── 2. Symlink config/ → ~/.config ───────────
link_config() {
  local src="$REPO_DIR/config"
  local dst="$HOME/.config"
  mkdir -p "$dst"

  for appdir in "$src"/*/; do
    [ -d "$appdir" ] || continue
    local name; name="$(basename "$appdir")"
    # Skip template-only dirs that have no direct live target.
    [ "$name" = "templates" ] && continue

    local target="$dst/$name"
    if [ -e "$target" ] || [ -L "$target" ]; then
      if [ -L "$target" ]; then
        rm -f "$target"
      elif [ -d "$target" ]; then
        local backup="${target}.bak.$(date +%s)"
        warn "existing dir $target -> moving to $backup"
        mv "$target" "$backup"
      else
        local backup="${target}.bak.$(date +%s)"
        warn "existing file $target -> moving to $backup"
        mv "$target" "$backup"
      fi
    fi

    ln -sfn "$appdir" "$target"
    log "linked $name -> ~/.config/$name"
  done
}

# ─────────── 3. Dotfiles that live in $HOME ───────────
link_home_dotfiles() {
  local pairs=(
    "config/zsh/zshrc:.zshrc"
  )
  for pair in "${pairs[@]}"; do
    local src="${pair%%:*}"
    local dotname="${pair##*:}"
    local target="$HOME/$dotname"
    # Каталог, куда кладём ссылку, может быть не создан (например для .config/…),
    # а $HOME есть всегда — но mkdir -p на $HOME безвреден.
    mkdir -p "$(dirname "$target")"
    ln -sfn "$REPO_DIR/$src" "$target"
    log "linked $dotname -> ~/$dotname"
  done
}

# ─────────── 4. Scripts (и lib.sh) → ~/.local/bin ───────────
install_scripts() {
  local bindir="${XDG_BIN_HOME:-$HOME/.local/bin}"
  mkdir -p "$bindir"
  for s in "$REPO_DIR"/scripts/*.sh "$REPO_DIR"/scripts/*.py; do
    [ -f "$s" ] || continue
    local name; name="$(basename "$s")"
    cp -f "$s" "$bindir/$name"
    chmod +x "$bindir/$name"
  done
  log "scripts installed to $bindir"

  if ! printf '%s' "$PATH" | grep -q "$bindir"; then
    local rc="$HOME/.bashrc"
    if [ -f "$HOME/.zshrc" ] && ! grep -q "$bindir" "$HOME/.zshrc"; then
      printf '\n# dotfiles\nexport PATH="$PATH:%s"\n' "$bindir" >> "$HOME/.zshrc"
      rc="$HOME/.zshrc"
    elif ! grep -q "$bindir" "$rc" 2>/dev/null; then
      printf '\n# dotfiles\nexport PATH="$PATH:%s"\n' "$bindir" >> "$rc"
    fi
    log "added $bindir to PATH in $rc"
  fi
}

# ─────────── 5. NixOS full rebuild ───────────
build_nixos() {
  if [ -f /etc/NIXOS ] && [ -x "$REPO_DIR/scripts/install.sh" ]; then
    log "NixOS detected — running full install (nixos-rebuild + home-manager)."
    bash "$REPO_DIR/scripts/install.sh" all
  else
    warn "Not NixOS or install.sh missing — skipped NixOS rebuild."
  fi
}

main() {
  need_cmd git

  fetch_repo
  link_config
  link_home_dotfiles
  install_scripts

  case "${1:-all}" in
    links)  : ;;
    system) build_nixos ;;
    all)    build_nixos ;;
    *)      die "usage: $0 {all|links|system}" ;;
  esac

  log "Done. Dotfiles live in $REPO_DIR"
}

main "$@"
