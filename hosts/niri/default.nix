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

    ../../modules/nixos
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # BOOT
  # ═══════════════════════════════════════════════════════════════════════════
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelParams = [ "quiet" ];
  boot.tmp.useTmpfs = true;
  boot.tmp.cleanOnBoot = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # HOSTNAME / NETWORK
  # ═══════════════════════════════════════════════════════════════════════════
  networking.hostName = "niri";
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [
    22
  ];
  networking.firewall.allowedUDPPorts = [
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # PRIVACY / ANONYMITY
  # ═══════════════════════════════════════════════════════════════════════════
  networking.nameservers = [
    "1.1.1.1#cloudflare-dns.com"
    "9.9.9.9#dns.quad9.net"
  ];
  networking.search = [ ];
  services.resolved = {
    enable = true;
    dnssec = "yes";
    dnsoverTls = "yes";
    fallbackDns = [ "1.1.1.1" "9.9.9.9" ];
  };
  networking.networkmanager.dns = "default";

  networking.networkmanager.wifi.macAddress = "random";
  networking.networkmanager.wifi.scanRandMacAddress = true;
  networking.networkmanager.ethernet.macAddress = "random";

  nix.channel.enable = false;
  system.autoUpgrade.enable = false;
  nix.settings.auto-optimise-store = true;

  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1month
  '';

  # ═══════════════════════════════════════════════════════════════════════════
  # TOR
  # ═══════════════════════════════════════════════════════════════════════════
  services.torclient = {
    enable = true;
    socksPort = 9050;
    controlPort = 9051;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # MINI-VPN
  # ═══════════════════════════════════════════════════════════════════════════
  services.anirevpn = {
    enable = true;
    core = "sing-box";
    autoStart = true;
    killSwitch = true;
    endpoint = "vpn.example.com:443";
    # ВАЖНО: путь резолвится от ЭТОГО файла (hosts/niri/) → ../../config
    configFile = ../../config/proxy/sing-box.json;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # AUDIO
  # ═══════════════════════════════════════════════════════════════════════════
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # BLUETOOTH
  # ═══════════════════════════════════════════════════════════════════════════
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # GRAPHICS
  # ═══════════════════════════════════════════════════════════════════════════
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  # AMD
  # hardware.amdgpu.initrd.enable = true;

  # NVIDIA
  # services.xserver.videoDrivers = [ "nvidia" ];
  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   open = false;
  #   nvidiaSettings = true;
  #   package = config.boot.kernelPackages.nvidiaPackages.stable;
  # };

  # ═══════════════════════════════════════════════════════════════════════════
  # LOCALE / TIME / LANGUAGE
  # ═══════════════════════════════════════════════════════════════════════════
  i18n.defaultLocale = "ru_RU.UTF-8";
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" "ru_RU.UTF-8/UTF-8" ];
  i18n.extraLocaleSettings = {
    LC_TIME = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MESSAGES = "en_US.UTF-8";
  };

  time.timeZone = "Europe/Moscow";

  # ═══════════════════════════════════════════════════════════════════════════
  # KEYBOARD LAYOUTS
  # ═══════════════════════════════════════════════════════════════════════════
  console.keyMap = "us-russian";

  services.xserver.xkb.layout = "us,ru";
  services.xserver.xkb.variant = "";
  services.xserver.xkb.options = "grp:alt_shift_toggle";

  # ═══════════════════════════════════════════════════════════════════════════
  # USERS
  # ═══════════════════════════════════════════════════════════════════════════
  users.mutableUsers = true;
  users.users.user = {
    isNormalUser = true;
    description = "niri user";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "bluetooth"
      "docker"
    ];
    initialPassword = "changeme";
  };

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

  # ═══════════════════════════════════════════════════════════════════════════
  # PROGRAM / SESSION
  # ═══════════════════════════════════════════════════════════════════════════
  services.login = {
    enable = true;
    autoLogin = false;
    autoLoginUser = "user";
  };
  services.lock = {
    enable = true;
    screenOffAfter = 45;
    lockAfter = 12;
  };

  services.browsers = {
    enable = true;
    default = "helium";
    doh = true;
    blockTrackers = true;
  };

  services.virtualisation = {
    enable = true;
    user = "user";
    ovmf = true;
    swtpm = true;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM SERVICES
  # ═══════════════════════════════════════════════════════════════════════════
  services.dbus.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.upower.enable = true;
  services.tlp.enable = lib.mkForce false;

  # ═══════════════════════════════════════════════════════════════════════════
  # FONTS
  # ═══════════════════════════════════════════════════════════════════════════
  # Если nixpkgs ещё старый — замени `nerd-fonts` на `nerdfonts`.
  fonts.packages = with pkgs; [
    (nerd-fonts.override { fonts = [ "JetBrainsMono" "FiraCode" "CaskaydiaCove" ]; })
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    font-awesome
    papirus-icon-theme
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # SYSTEM PACKAGES
  # ═══════════════════════════════════════════════════════════════════════════
  environment.systemPackages = with pkgs; [
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

    wl-clipboard
    grim
    slurp
    swappy
    wl-mirror
    swaylock
    brightnessctl

    wf-recorder

    jq
    yq
    xdg-utils
    dbus
    libnotify
    networkmanagerapplet
    wireguard-tools
    nftables
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # SECURITY
  # ═══════════════════════════════════════════════════════════════════════════
  security.protectKernelImage = true;

  # ═══════════════════════════════════════════════════════════════════════════
  # MISCELLANEOUS
  # ═══════════════════════════════════════════════════════════════════════════
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = lib.mkForce false;

  system.stateVersion = "24.11";
}
