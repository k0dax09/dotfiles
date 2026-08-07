# disko.nix — declarative disk partitioning (GPT + LUKS + btrfs subvolumes).
#
# Use on a THROWAWAY machine / first install:
#   sudo nix run github:nix-community/disko -- --mode disko-host ./disko.nix
# (or --mode destroy,format,mount to wipe the disk).
#
# Layout:
#   /dev/nvme0n1
#   ├─ p1  boot   ESP  1G   (vfat)            → /boot
#   └─ p2  root  100%  LUKS (luksroot)
#                      └─ btrfs subvolumes:
#                         @          → /
#                         @nix       → /nix
#                         @home      → /home
#                         @swap      → swapfile (8G)

{
  disko.devices = {
    disk.disk1 = {
      type = "disk";
      device = "/dev/nvme0n1";          # ← CHANGE to your disk node
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1G";
            type = "EF00";              # ESP (UEFI system partition)
            content = {
              type = "filesystem";
              filesystem = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "fmask=0077" "dmask=0077" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "luks";
              name = "luksroot";        # matches hardware-configuration.nix
              extraOpenArgs = [ "--allow-discards" ];
              settings.allowDiscards = true;
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];   # force format
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "subvol=@" "compress=zstd" "noatime" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "subvol=@nix" "compress=zstd" "noatime" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "subvol=@home" "compress=zstd" "noatime" ];
                  };
                  "@swap" = {
                    mountpoint = "/swap";
                    swap.swapfile.size = "8G";   # encrypted swap, auto enabled
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}