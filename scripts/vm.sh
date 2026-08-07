#!/usr/bin/env bash
# vm.sh — boot a NixOS VM (x86_64) from an ISO with zero manual QEMU setup.
#
#   ./scripts/vm.sh [path/to/*.iso]
#
# 1) Checks the toolchain: qemu-system-x86_64, virt-manager, KVM.
# 2) Picks KVM (fast) when available, else falls back to TCG.
# 3) Selects UEFI firmware (OVMF).
# 4) Boots the ISO from a cdrom with a virtual GPU, USB input and user-net.
# Pass an ISO to override the automatic lookup in <repo>/*.iso.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
log()  { printf '\033[1;32m[+]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

# ── 1. Toolchain check ───────────────────────────────────────────────────
log "=== Toolchain check (x86_64) ==="

command -v virt-manager >/dev/null 2>&1 \
  && log "virt-manager ........ found (not used; direct QEMU)" \
  || warn "virt-manager ........ missing (optional GUI only)"

QEMU="$(command -v qemu-system-x86_64 || true)"
if [ -n "$QEMU" ]; then
  log "qemu-system-x86_64 .. found ($QEMU)"
else
  die "qemu-system-x86_64 not found.
  NixOS:   nix shell nixpkgs#qemu       (or add qemu to systemPackages)
  APT:     sudo apt install qemu-system-x86
  Pacman:  sudo pacman -S qemu-full"
fi

if [ -w /dev/kvm ]; then
  log "KVM (/dev/kvm) ....... available → hardware acceleration"
  ACCEL="kvm"; CPU="host"
else
  warn "KVM ................... unavailable → falling back to TCG emulation"
  ACCEL="tcg"; CPU="max"
fi

# ── 2. ISO ───────────────────────────────────────────────────────────────
ISO=""
if [ $# -gt 0 ]; then
  ISO="$1"
else
  for f in "$REPO_DIR"/*.iso; do
    [ -e "$f" ] || continue
    case "$f" in *x86_64*|*amd64*) ISO="$f"; break ;; esac
  done
  if [ -z "$ISO" ]; then
    for f in "$REPO_DIR"/*.iso; do [ -e "$f" ] && { ISO="$f"; break; }; done
  fi
fi
[ -z "$ISO" ] && die "No *.iso in '$REPO_DIR'. Pass one:
  ./scripts/vm.sh /path/to/nixos-minimal-x86_64-linux.iso"
log "ISO ..................... $ISO"

# ── 3. UEFI firmware (OVMF) ──────────────────────────────────────────────
FIRMWARE=""
for c in \
  /usr/share/OVMF/OVMF_CODE.fd \
  /usr/share/ovmf/x64/OVMF_CODE.fd \
  /run/current-system/sw/share/OVMF/OVMF_CODE.fd \
  /nix/store/*/share/OVMF/OVMF_CODE.fd; do
  [ -f "$c" ] && { FIRMWARE="$c"; break; }
done
if [ -n "$FIRMWARE" ]; then
  log "UEFI firmware .......... $FIRMWARE"
else
  warn "OVMF firmware not found; booting without it may fail."
  warn "  NixOS: nix shell nixpkgs#OVMF"
fi

# ── 4. Resources / display ───────────────────────────────────────────────
RAM="${VM_RAM:-4096}"
CPUS="${VM_CPUS:-4}"

# Ask QEMU which display backends it supports (some builds lack `wayland`/`sdl`).
SUPPORTED="$("$QEMU" -display help 2>&1)"
has_display() { printf '%s\n' "$SUPPORTED" | grep -qw "$1"; }

# Pick the first usable GUI backend, honouring the session we're in.
DISP=( -display none -serial mon:stdio )   # safe headless fallback
if [ -n "${DISPLAY:-}" ] && has_display gtk; then
  DISP=( -display gtk,gl=on )
elif [ -n "${WAYLAND_DISPLAY:-}" ] && has_display wayland; then
  DISP=( -display wayland,gl=on )
elif [ -n "${DISPLAY:-}" ] && has_display sdl; then
  DISP=( -display sdl )
elif has_display gtk; then
  DISP=( -display gtk,gl=on )
fi
if [ "${DISP[0]}" = "-display" ] && [ "${DISP[1]}" = "none" ]; then
  warn "No GUI display backend available → running headless (serial console)."
  warn "To get a window: run inside a graphical session, or use  -vnc :1  manually."
fi

# ── 5. Boot ──────────────────────────────────────────────────────────────
log "Booting x86_64 VM: $ISO  (${RAM}MB / ${CPUS} vCPU, accel: ${ACCEL})"

# Only add -device entries QEMU actually knows (builds differ).
has_device() { "$QEMU" -device "$1",help >/dev/null 2>&1; }
GPU=()
has_device virtio-gpu-pci && GPU=( -device virtio-gpu-pci,id=gpu )
DEV=()
has_device qemu-xhci   && DEV+=( -device qemu-xhci,id=xhci )
has_device virtio-keyboard-pci && DEV+=( -device virtio-keyboard-pci )
has_device virtio-tablet-pci   && DEV+=( -device virtio-tablet-pci )

NETDEV=()
if has_device virtio-net-pci; then
  NETDEV=( -device virtio-net-pci,netdev=net0 )
elif has_device e1000e; then
  NETDEV=( -device e1000e,netdev=net0 )
else
  NETDEV=( -device e1000,netdev=net0 )
  warn "Only old e1000 NIC available — networking will be slower."
fi

exec "$QEMU" \
  -machine type=q35 -accel "$ACCEL" \
  -cpu "$CPU" -m "$RAM" -smp "$CPUS" \
  ${FIRMWARE:+-bios "$FIRMWARE"} \
  -cdrom "$ISO" \
  -boot order=d,menu=on \
  "${GPU[@]}" \
  "${DEV[@]}" \
  -netdev user,id=net0 "${NETDEV[@]}" \
  "${DISP[@]}"