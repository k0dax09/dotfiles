#!/usr/bin/env bash
#
# vm.sh — boot a NixOS VM (x86_64) with the dotfiles repo shared from the host.
#
# Modes:
#   ./scripts/dev/vm.sh boot [iso]     Boot installer ISO with repo shared
#   ./scripts/dev/vm.sh install [iso]  Same as boot + install hints
#   ./scripts/dev/vm.sh run            Build flake config as runnable VM
#   ./scripts/dev/vm.sh download       Download NixOS ISO
#   ./scripts/dev/vm.sh disk           Create qcow2 disk
#
# Env:
#   ISO= VM_RAM= VM_CPUS= VM_SSH_PORT= VM_HEADLESS=1
#   VM_SHARE_DIR=      VM_SHARE_RW=1
#   VM_DISK=           VM_DISK_SIZE=30G
#   QEMU_BIN=
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
log()  { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

reject_if_comment() {
  case "${1:-}" in
    ''|'#'*|'//'*)
      if [ -n "${1:-}" ]; then
        die "argument '$1' looks like a comment, not an ISO path."
      fi ;;
  esac
}

ISO="${ISO:-}"
RAM="${VM_RAM:-4096}"
CPUS="${VM_CPUS:-4}"
SSH_PORT="${VM_SSH_PORT:-2222}"
SHARE_DIR="${VM_SHARE_DIR:-$REPO_DIR}"
SHARE_TAG="host0"
SHARE_RW="${VM_SHARE_RW:-0}"
HEADLESS="${VM_HEADLESS:-0}"
QEMU_BIN="${QEMU_BIN:-qemu-system-x86_64}"
DISK="${VM_DISK:-}"
DISK_SIZE="${VM_DISK_SIZE:-30G}"
ISO_DIR="${VM_ISO_DIR:-$REPO_DIR/private/vm}"
ISO_NAME="${VM_ISO_NAME:-nixos-minimal-x86_64-linux.iso}"
ISO_URL="${VM_ISO_URL:-https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso}"

need() { command -v "$1" >/dev/null 2>&1 || die "missing: $1"; }
pick_qemu() { need "$QEMU_BIN" || die "install qemu (qemu-system-x86_64)"; }

maybe_disk() {
  if [ -n "$DISK" ]; then
    if [ ! -f "$DISK" ]; then
      warn "disk not found: $DISK → creating $DISK_SIZE qcow2"
      mkdir -p "$(dirname "$DISK")"
      qemu-img create -f qcow2 "$DISK" "$DISK_SIZE"
    fi
    log "disk: $DISK"
    DISK_ARGS=( -drive "file=$DISK,if=virtio,format=qcow2,cache=writeback,discard=unmap" )
  else
    DISK_ARGS=()
  fi
}

download_iso() {
  local dest="$ISO_DIR/$ISO_NAME"
  if [ -f "$dest" ]; then ISO="$dest"; log "ISO (cached): $dest"; return 0; fi
  case "${VM_ISO_DOWNLOAD:-ask}" in
    no|0) return 1 ;;
    yes|1|"") ;;
  esac
  if [ "${VM_ISO_DOWNLOAD:-ask}" = "ask" ]; then
    printf '[?] Download NixOS ISO (~2 GB) from %s ? [y/N] ' "$ISO_URL"
    read -r ans </dev/tty || ans=n
    case "$ans" in y|Y|yes) ;; *) return 1 ;; esac
  fi
  mkdir -p "$ISO_DIR"
  log "downloading $ISO_URL"
  if command -v curl >/dev/null 2>&1; then
    curl -L --fail --progress-bar -o "$dest.part" "$ISO_URL" && mv "$dest.part" "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget --progress=bar -O "$dest.part" "$ISO_URL" && mv "$dest.part" "$dest"
  else
    die "curl or wget required"
  fi
  ISO="$dest"
  log "saved: $dest"
}

find_iso() {
  reject_if_comment "${1:-}"
  [ -n "${1:-}" ] && ISO="$1"
  if [ -n "$ISO" ] && [ -f "$ISO" ]; then log "ISO: $ISO"; return; fi

  # 1. в корне репо
  for f in "$REPO_DIR"/*.iso; do
    [ -e "$f" ] || continue
    case "$f" in *x86_64*|*amd64*) ISO="$f"; break ;; esac
  done
  [ -z "$ISO" ] && for f in "$REPO_DIR"/*.iso; do [ -e "$f" ] && { ISO="$f"; break; }; done
  [ -n "$ISO" ] && { log "ISO: $ISO"; return; }

  # 2. в private/vm/
  for f in "$REPO_DIR"/private/vm/*.iso; do
    [ -e "$f" ] || continue
    case "$f" in *x86_64*|*amd64*) ISO="$f"; break ;; esac
  done
  [ -z "$ISO" ] && for f in "$REPO_DIR"/private/vm/*.iso; do [ -e "$f" ] && { ISO="$f"; break; }; done
  [ -n "$ISO" ] && { log "ISO: $ISO"; return; }

  # 3. кеш / скачать
  download_iso && return
  die "no ISO found. Pass one: $0 boot /path/to/nixos.iso"
}

pick_accel() {
  if [ -w /dev/kvm ]; then ACCEL=kvm; CPU=host; log "accel: kvm"
  else ACCEL=tcg; CPU=max; warn "accel: tcg (no /dev/kvm)"; fi
}

find_firmware() {
  FIRMWARE=()
  local code vars
  for pair in \
    "/usr/share/edk2/x64/OVMF_CODE.4m.fd /usr/share/edk2/x64/OVMF_VARS.4m.fd" \
    "/usr/share/OVMF/OVMF_CODE.fd /usr/share/OVMF/OVMF_VARS.fd" \
    "/usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_VARS_4M.fd" \
    "/usr/share/ovmf/x64/OVMF_CODE.fd /usr/share/ovmf/x64/OVMF_VARS.fd" \
    "/usr/share/edk2/x64/OVMF_CODE.fd /usr/share/edk2/x64/OVMF_VARS.fd" \
    "/run/current-system/sw/share/OVMF/OVMF_CODE.fd /run/current-system/sw/share/OVMF/OVMF_VARS.fd"
  do
    code="${pair%% *}"; vars="${pair##* }"
    if [ -f "$code" ] && [ -f "$vars" ]; then
      local vars_copy="${HOME}/.cache/dotfiles/vm-OVMF_VARS.fd"
      mkdir -p "$(dirname "$vars_copy")"
      cp -f "$vars" "$vars_copy"
      FIRMWARE=( -drive "if=pflash,format=raw,readonly=on,file=$code" \
                 -drive "if=pflash,format=raw,file=$vars_copy" )
      log "firmware (UEFI): $code"
      return
    fi
  done
  warn "OVMF not found — booting legacy BIOS"
}

pick_display() {
  DISP=( -display none -serial mon:stdio )
  if [ "$HEADLESS" = "1" ]; then log "display: headless (serial)"; return; fi
  local supported; supported="$("$QEMU_BIN" -display help 2>&1 || true)"
  has() { printf '%s\n' "$supported" | grep -qw "$1"; }
  if [ -n "${WAYLAND_DISPLAY:-}" ] && has wayland; then
    DISP=( -display wayland,gl=on ); log "display: wayland"
  elif [ -n "${DISPLAY:-}" ] && has gtk; then
    DISP=( -display gtk,gl=on );     log "display: gtk"
  elif [ -n "${DISPLAY:-}" ] && has sdl; then
    DISP=( -display sdl );           log "display: sdl"
  elif has gtk; then
    DISP=( -display gtk,gl=on );     log "display: gtk"
  else
    DISP=( -vnc :0 -display none -serial mon:stdio )
    warn "no GUI backend; VNC on localhost:5900"
  fi
}

boot_iso() {
  log "booting ISO with repo share: $SHARE_DIR → 9p tag '$SHARE_TAG' (rw=$SHARE_RW)"
  log "SSH forward: ssh -p $SSH_PORT root@localhost"

  local GPU=() DEV=() NETDEV=()
  has_device() { "$QEMU_BIN" -device "$1",help >/dev/null 2>&1; }
  has_device virtio-gpu-pci      && GPU=( -device virtio-gpu-pci )
  has_device qemu-xhci           && DEV+=( -device qemu-xhci )
  has_device virtio-keyboard-pci && DEV+=( -device virtio-keyboard-pci )
  has_device virtio-tablet-pci   && DEV+=( -device virtio-tablet-pci )

  if has_device virtio-net-pci; then
    NETDEV=( -device virtio-net-pci,netdev=net0 )
  elif has_device e1000e; then
    NETDEV=( -device e1000e,netdev=net0 )
  else
    NETDEV=( -device e1000,netdev=net0 )
  fi

  local rw_flag="on"
  [ "$SHARE_RW" = "1" ] && rw_flag="off"

  exec "$QEMU_BIN" \
    -machine type=q35 -accel "$ACCEL" -cpu "$CPU" \
    -m "$RAM" -smp "$CPUS" \
    "${FIRMWARE[@]}" \
    "${DISK_ARGS[@]}" \
    -drive "file=$ISO,media=cdrom,readonly=on" \
    -boot order=d,menu=on \
    "${GPU[@]}" "${DEV[@]}" \
    -netdev "user,id=net0,hostfwd=tcp::${SSH_PORT}-:22" \
    "${NETDEV[@]}" \
    -virtfs "local,path=$SHARE_DIR,mount_tag=$SHARE_TAG,security_model=none,readonly=$rw_flag" \
    "${DISP[@]}"
}

run_flake_vm() {
  need nix
  log "building VM from flake…"
  ( cd "$REPO_DIR" && nix run nixpkgs#nixos-rebuild -- build-vm --flake ".#niri" )
  [ -x "$REPO_DIR/result/bin/run-niri-vm" ] || die "result/bin/run-niri-vm not built"
  exec "$REPO_DIR/result/bin/run-niri-vm"
}

create_disk() {
  need qemu-img
  DISK="${DISK:-$REPO_DIR/private/vm/nixos.qcow2}"
  mkdir -p "$(dirname "$DISK")"
  if [ -f "$DISK" ]; then
    log "already exists: $DISK ($(du -h "$DISK" | cut -f1))"
  else
    qemu-img create -f qcow2 "$DISK" "$DISK_SIZE"
    log "created: $DISK ($DISK_SIZE)"
  fi
  log "use with: VM_DISK=$DISK $0 boot"
}

usage() {
  cat <<EOF
usage: $0 {boot|install|run|download|disk} [iso]

  boot [iso]      boot installer ISO (repo shared via 9p)
  install [iso]   same as boot + install hints
  run             build flake config as runnable VM (needs nix)
  download        download NixOS ISO
  disk            create qcow2 disk

env:
  ISO= VM_RAM= VM_CPUS= VM_SSH_PORT= VM_HEADLESS=1
  VM_SHARE_DIR= VM_SHARE_RW=1
  VM_DISK=/path/disk.qcow2 VM_DISK_SIZE=30G
  QEMU_BIN=

inside the VM:
  sudo -i
  mkdir -p /mnt/host
  mount -t 9p -o trans=virtio,version=9p2000.L $SHARE_TAG /mnt/host

from the host:
  ssh -p $SSH_PORT root@localhost
EOF
}

main() {
  case "${1:-boot}" in
    boot)
      reject_if_comment "${2:-}"
      pick_qemu; find_iso "${2:-}"; pick_accel; find_firmware
      maybe_disk; pick_display; boot_iso
      ;;
    install)
      reject_if_comment "${2:-}"
      pick_qemu; find_iso "${2:-}"; pick_accel; find_firmware
      maybe_disk; pick_display
      log "install hints:"
      log "  1) mount -t 9p -o trans=virtio,version=9p2000.L $SHARE_TAG /mnt/host"
      log "  2) see private/VM.md"
      boot_iso
      ;;
    run)      run_flake_vm ;;
    download) VM_ISO_DOWNLOAD=yes download_iso && log "done: $ISO" ;;
    disk)     create_disk ;;
    -h|--help|help|"") usage ;;
    *) usage; exit 1 ;;
  esac
}

main "$@"
