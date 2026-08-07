# NixOS module: virtualisation — libvirt, virt-manager, QEMU/KVM.
#
# Usage in configuration.nix (or any host default.nix):
#   services.virtualisation = {
#     enable = true;
#     user = "user";        # who gets the libvirtd group
#     ovmf = true;          # UEFI firmware for VMs
#     swtpm = true;         # virtual TPM
#   };

{ config, lib, pkgs, ... }:

let
  cfg = config.services.virtualisation;
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.services.virtualisation = {
    enable = mkEnableOption "libvirt/QEMU/KVM virtualisation stack";
    user = mkOption {
      type = types.str;
      default = "user";
      description = "Username to grant access to libvirtd.";
    };
    ovmf = mkOption {
      type = types.bool;
      default = true;
      description = "Enable OVMF (UEFI) firmware support for VMs.";
    };
    swtpm = mkOption {
      type = types.bool;
      default = true;
      description = "Enable a virtual TPM (swtpm) for VMs.";
    };
  };

  config = lib.mkIf cfg.enable {
    # ── libvirtd daemon + QEMU ───────────────────────────────────────────
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAs = "root";                     # allow VMs to boot disks
        ovmf = { enable = cfg.ovmf; packages = [ pkgs.OVMF ]; };
        swtpm.enable = cfg.swtpm;
      };
      onShutdown = "shutdown";              # shut down VMs with the host
    };

    # ── Access: add the user to the libvirtd group ───────────────────────
    users.users.${cfg.user}.extraGroups = [ "libvirtd" ];

    # ── Tools ────────────────────────────────────────────────────────────
    environment.systemPackages = with pkgs; [
      virt-manager       # GUI manager
      virt-viewer        # SPICE/VNC viewer
      libvirt            # virsh CLI
      libvirt-glib
      spice-gtk          # SPICE client libs
      qemu_kvm
      swtpm
    ];

    # ── Kernel KVM support (choose the one matching your CPU) ─────────────
    # boot.kernelModules = [ "kvm_amd" ];   # AMD
    # boot.kernelModules = [ "kvm_intel" ]; # Intel

    # ── Default network on boot (virbr0) ─────────────────────────────────
    virtualisation.libvirtd.allowedBridges = [ "virbr0" ];
  };
}