# NixOS configuration for the niri workstation.
#
# Build with:  sudo nixos-rebuild switch --flake .#niri
#
# NOTE: this is a full reference config. Before using it on a real machine:
#   1. generate hardware-configuration.nix with `nixos-generate-config --root /mnt`
#      and uncomment its import below,
#   2. set the correct hostName, user name and locale,
#   3. enable the GPU section that matches your hardware (AMD/Intel/NVIDIA).

{
  inputs,
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    # Generate with `nixos-generate-config --root /mnt` (run on install), or
    # adapt hosts/niri/hardware-configuration.nix.sample → save as
    # ./hardware-configuration.nix (not .sample) and uncomment:
    # ./hardware-configuration.nix

    # All system modules (services, etc.) come from the aggregator.
    ../../modules/nixos
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # BOOT
  # ═══════════════════════════════════════════════════════════════════════════
  # systemd-boot (UEFI)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Alternative: GRUB for BIOS/Legacy
  # boot.loader.grub = {
  #   enable = true;
  #   device = "/dev/sda";   # whole disk
  # };

  # Kernel tweaks (optional)
  boot.kernelParams = [ "quiet" ];
  boot.tmp.useTmpfs = true;            # keep /tmp in RAM (faster, ephemeral)
  boot.tmp.cleanOnBoot = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # HOSTNAME / NETWORK
  # ═══════════════════════════════════════════════════════════════════════════
  networking.hostName = "niri";
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false; # NM owns wifi, not wpa_supplicant

  # ────────────── FIREWALL ──────────────
  networking.firewall.enable = true;   # on by default; keep it on
  networking.firewall.allowedTCPPorts = [
    22      # ssh
    # 631    # cups printing
    # 51413  # transmission
  ];
  networking.firewall.allowedUDPPorts = [
    # 51820  # wireguard
  ];

  # ────────────── WireGuard (example) ──────────────
  # networking.wireguard.interfaces.wg0 = {
  #   privateKeyFile = "/secrets/wg0.key";
  #   peers = [{
  #     publicKey = "PUBKEY=";
  #     allowedIPs = [ "10.0.0.0/24" ];
  #     endpoint = "vpn.example.com:51820";
  #   }];
  # };

  # ═══════════════════════════════════════════════════════════════════════════
  # PRIVACY / ANONYMITY
  # ═══════════════════════════════════════════════════════════════════════════
  #
  # ── DNS everywhere: systemd-resolved + DoT + DNSSEC ──────────────────
  # DNS-over-TLS to Cloudflare + Quad9 (swap endpoints as you like):
  networking.nameservers = [
    "1.1.1.1#cloudflare-dns.com"
    "9.9.9.9#dns.quad9.net"
  ];
  networking.search = [ ];            # no local domain leak
  services.resolved = {
    enable = true;
    dnssec = "yes";
    dnsoverTls = "yes";               # TLS wherever the server supports it
    fallbackDns = [ "1.1.1.1" "9.9.9.9" ];
  };
  # Hand NetworkManager's DNS over to systemd-resolved:
  networking.networkmanager.dns = "default";

  # ── MAC address randomization ────────────────────────────────────────
  networking.networkmanager.wifi.macAddress = "random";
  networking.networkmanager.wifi.scanRandMacAddress = true;
  networking.networkmanager.ethernet.macAddress = "random";

  # ── Kill telemetry / phone-home ──────────────────────────────────────
  nix.channel.enable = false;                       # no auto nixos.org channel check
  system.autoUpgrade.enable = false;
  nix.settings.auto-optimise-store = true;

  # ── Block ad/tracker hosts (paste a curated list, e.g. StevenBlack) ───
  # networking.extraHosts = ''
  #   0.0.0.0 doubleclick.net
  #   0.0.0.0 google-analytics.com
  # '';

  # ── Bound the journal, no remote forwarding ───────────────────────────
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1month
  '';

  # ═══════════════════════════════════════════════════════════════════════════
  # TOR → managed by modules/nixos/services/tor.nix
  # ═══════════════════════════════════════════════════════════════════════════
  # Local SOCKS proxy (127.0.0.1:9050). Route a command with `torsocks`.
  # NOTE: tor is passwordless-auth; it replaces your identity, not everything.
  services.torclient = {
    enable = true;
    socksPort = 9050;
    controlPort = 9051;            # for nyx monitor
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # MINI-VPN → managed by modules/nixos/services/anirevpn.nix
  # ═══════════════════════════════════════════════════════════════════════════
  # Fill in YOUR server/uuid in config/proxy/sing-box.json, then rebuild.
  # Control from niri with Mod+Alt+V (scripts/proxy.sh).
  services.anirevpn = {
    enable = true;
    core = "sing-box";            # "sing-box" | "xray"
    autoStart = true;             # main VPN → start at boot
    killSwitch = true;            # fail-closed nftables (no leaks)
    endpoint = "vpn.example.com:443";  # YOUR proxy server (kill-switch allow)
    configFile = ../config/proxy/sing-box.json;   # or xray.json
  };
  # ═══════════════════════════════════════════════════════════════════════════
  # AUDIO (PipeWire)
  # ═══════════════════════════════════════════════════════════════════════════
  security.rtkit.enable = true;         # realtime audio permissions
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;                # PulseAudio compatibility
    jack.enable = true;                 # JACK apps
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # BLUETOOTH
  # ═══════════════════════════════════════════════════════════════════════════
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;       # bluetoothctl + applet for the tray

  # ═══════════════════════════════════════════════════════════════════════════
  # GRAPHICS
  # Pick the GPU section that matches your hardware.
  # ═══════════════════════════════════════════════════════════════════════════
  hardware.graphics.enable = true;      # udev rules for DRM
  hardware.graphics.enable32Bit = true; # 32-bit (games)

  # AMD
  # hardware.amdgpu.initrd.enable = true;

  # NVIDIA
  # hardware.graphics.enable = true;
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   open = false;
  #   nvidiaSettings = true;
  #   package = config.boot.kernelPackages.nvidiaPackages.stable;
  # };

  # Intel
  # hardware.graphics = { enable = true; };
  # services.xserver.videoDrivers = [ "intel" ];

  # ═══════════════════════════════════════════════════════════════════════════
  # LOCALE / TIME / LANGUAGE
  # ═══════════════════════════════════════════════════════════════════════════
  i18n.defaultLocale = "ru_RU.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "ru_RU.UTF-8/UTF-8" ];
  # Language packs (used by some apps; set LC_MESSAGES to en for English UI):
  i18n.extraLocaleSettings = {
    LC_TIME = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MESSAGES = "en_US.UTF-8"; # интерфейс — на английском
  };

  time.timeZone = "Europe/Moscow";

  # ═══════════════════════════════════════════════════════════════════════════
  # KEYBOARD LAYOUTS
  # ═══════════════════════════════════════════════════════════════════════════
  # Console (tty) layout — used outside the GUI:
  console.keyMap = "us-russian";

  # X/Wayland XKB layouts (applies to XWayland and X apps; niri manages its own
  # layout via config/niri/cfg/input.kdl). Options: us,ru + Alt+Shift toggle.
  services.xserver.xkb.layout = "us,ru";
  services.xserver.xkb.variant = "";
  services.xserver.xkb.options = "grp:alt_shift_toggle";

  # ═══════════════════════════════════════════════════════════════════════════
  # DISK ENCRYPTION (LUKS) — root/boot encryption example
  # ═══════════════════════════════════════════════════════════════════════════
  # For this to work, your /etc/nixos/hardware-configuration.nix (or the file
  # generated by `nixos-generate-config`) must declare the encrypted root with
  #   fileSystems."/" = { device = "/dev/mapper/luksroot"; ... };
  # and a corresponding boot.initrd.luks device. Fill in your real UUID below.
  #
  # boot.initrd.luks.devices."luksroot" = {
  #   device = "/dev/disk/by-uuid/01234567-89ab-cdef-0123-456789abcdef";
  #   preLVM = true;       # if the encrypted device sits under LVM
  #   allowDiscards = true; # TRIM for SSDs (breaks if dm-crypt lacks support)
  # };
  #
  # Optional: auto-open an encrypted swap or LUKS on the same key:
  # boot.initrd.luks.devices."swap" = {
  #   device = "/dev/disk/by-uuid/...";
  #   keyFile = "/dev/mapper/luksroot"; # reuse root key
  #   allowDiscards = true;
  # };


  # ═══════════════════════════════════════════════════════════════════════════
  # USERS
  # ═══════════════════════════════════════════════════════════════════════════
  users.mutableUsers = true;            # set your password with `passwd`
  users.users.user = {
    isNormalUser = true;
    description = "niri user";
    extraGroups = [
      "wheel"           # sudo
      "networkmanager"  # manage wifi via nmcli
      "audio"
      "video"
      "bluetooth"
      "docker"
    ];
    # Use `initialPassword` for first boot, then set a real password:
    initialPassword = "changeme";
  };

  # Passwordless sudo for the wheel group (convenient; remove for security):
  security.sudo.extraRules = [
    { groups = [ "wheel" ]; commands = [ { command = "ALL"; options = [ "NOPASSWD" ]; } ]; }
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # NIX OPTIONS
  # ═══════════════════════════════════════════════════════════════════════════
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.settings.trusted-users = [ "root" "@wheel" ];
  # nix.settings.substituters = [ "https://cache.nixos.org" "https://hyprland.cachix.org" ];
  # nix.settings.trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMio4JMuypg8cGi6PVaw=" ];

  # Automatic system updates (off by default; enable if you want)
  # system.autoUpgrade.enable = true;
  # system.autoUpgrade.channel = "https://nixos.org/channels/nixos-unstable";

  # ═══════════════════════════════════════════════════════════════════════════
  # PROGRAM / SESSION
  # ═══════════════════════════════════════════════════════════════════════════
  # niri session is launched by the login module (modules/nixos/services/login.nix)
  # via greetd → niri-session, so programs.niri.enable is NOT set here (avoids
  # starting two niri instances).
  # programs.zsh.enable = true;
  # programs.git.enable = true;

  # ── Login screen (greetd) + screen lock (swaylock/hypridle) ───────────
  services.login = {
    enable = true;
    autoLogin = false;      # set true to skip the login screen
    autoLoginUser = "user";
  };
  services.lock = {
    enable = true;
    screenOffAfter = 45;    # seconds idle → screens off
    lockAfter = 12;         # minutes idle → lock (0 = never)
  };

  # ── Browser(s): Helium (default), LibreWolf optional ───────────────────
  services.browsers = {
    enable = true;
    default = "helium";   # helium | librewolf
    doh = true;
    blockTrackers = true;
  };

  # ── Virtualisation: virt-manager / QEMU / KVM ─────────────────────────
  services.virtualisation = {
    enable = true;
    user = "user";
    ovmf = true;   # UEFI firmware for VMs
    swtpm = true;  # virtual TPM
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM SERVICES
  # ═══════════════════════════════════════════════════════════════════════════
  services.dbus.enable = true;          # session bus (usually enabled anyway)
  services.udisks2.enable = true;       # automounting USB drives
  services.gvfs.enable = true;          # file manager integration (trash, mounts)
  services.upower.enable = true;        # battery monitoring for waybar
  services.tlp.enable = lib.mkForce false; # power management (enable on laptops)
  # services.tlp = { enable = true; };  # alternative to power-profiles-daemon
  # services.thermald.enable = true;    # CPU temperature management

  # Enables docker (optional)
  # virtualisation.docker.enable = true;
  # users.users.user.extraGroups = [ "docker" ];

  # ═══════════════════════════════════════════════════════════════════════════
  # FONTS
  # ═══════════════════════════════════════════════════════════════════════════
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" "CaskaydiaCove" ]; })
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    font-awesome
    papirus-icon-theme
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM PACKAGES (all users)
  # ═══════════════════════════════════════════════════════════════════════════
  environment.systemPackages = with pkgs; [
    # Core / terminal
    coreutils
    ripgrep
    fd
    fzf
    git
    curl
    wget
    htop
    btop
    tmux
    neovim
    tree

    # Wayland / XDG tools
    wl-clipboard
    wlroots
    grim
    slurp
    swappy
    wl-mirror
    swaylock
    brightnessctl

    # Screenshots / recording
    wf-recorder
    # satty   # annotation (add if desired)

    # Misc helpers
    jq
    yq
    xdg-utils
    dbus
    libnotify
    networkmanagerapplet   # nm-applet tray
    wireguard-tools        # wg / wg-quick for vpn.sh
    nftables               # kill-switch backend for vpn.sh
    # sing-box / xray / tun2socks are pulled in by modules/nixos/services/anirevpn.nix
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # SECURITY / LOCKDOWN (optional hardening)
  # ═══════════════════════════════════════════════════════════════════════════
  security.protectKernelImage = true;
  # security.lockKernelModules = true;   # may break some drivers
  # boot.blacklistedKernelModules = [ "kvm-intel" ]; # example

  # ═══════════════════════════════════════════════════════════════════════════
  # MISCELLANEOUS
  # ═══════════════════════════════════════════════════════════════════════════
  services.xserver.enable = true;       # needed by some tools; niri is wayland
  services.xserver.displayManager.gdm.enable = lib.mkForce false;

  # Don't forget to enable `hardware-configuration.nix`!
  system.stateVersion = "24.11";
}