{ pkgs, config, ... }:

{
  imports = [ ../../modules/home ];

  home.username = "user";
  home.homeDirectory = "/home/user";
  home.stateVersion = "24.11";

  home.sessionPath = [ "~/.local/bin" ];
  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORM = "wayland";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    DOTFILES_DIR = "$HOME/Dotfiles";
  };

  home.packages = with pkgs; [
    # Terminal & editor
    alacritty
    vim
    neovim
    tmux

    # Core wayland session
    waybar
    fuzzel
    wlogout
    swaybg
    mako
    wl-clipboard

    # Screenshots / recording
    grim
    slurp
    swappy
    wf-recorder

    # Password manager
    keepassxc

    # File manager
    nemo-with-extensions

    # GTK theme pieces
    papirus-icon-theme
    capitaine-cursors

    # Graphics / palette
    (python3.withPackages (ps: with ps; [ pillow ]))
    libnotify

    # Media / audio / input
    playerctl
    brightnessctl
    gammastep
    pavucontrol             # GUI настройки звука
    pulseaudio              # pactl fallback

    # Network / bluetooth tooling
    bluez
    bluez-tools
    blueman                 # GUI bluetooth
    networkmanagerapplet    # nm-applet в трее
    cliphist

    # ─── Beauty extras ────────────────────────────────
    swayosd                 # правильный OSD для громкости/яркости
    polkit_gnome            # polkit-агент (иначе poweroff из wlogout падает)
    cava                    # аудио-визуализатор
    playerctl
    brightnessctl

    # Утилиты
    jq
    yq
    xdg-utils
    wlr-randr               # рулить мониторами без xrandr
  ];

  # ─── Dotfiles ─────────────────────────────────────
  home.file.".config/niri"                  = { source = ../../config/niri; recursive = true; };
  home.file.".config/waybar/config.jsonc"   = { source = ../../config/waybar/config.jsonc; };
  home.file.".config/waybar/style.css"      = { source = ../../config/waybar/style.css; };
  home.file.".config/fuzzel/fuzzel.ini"     = { source = ../../config/fuzzel/fuzzel.ini; };
  home.file.".config/wlogout/layout"        = { source = ../../config/wlogout/layout; };
  home.file.".config/wlogout/style.css"     = { source = ../../config/wlogout/style.css; };
  home.file.".config/mako/config"           = { source = ../../config/mako/config; };
  home.file.".config/nvim"                  = { source = ../../config/nvim; recursive = true; };
  home.file.".config/tmux/tmux.conf"        = { source = ../../config/tmux/tmux.conf; };
  home.file.".config/alacritty/alacritty.toml" = { source = ../../config/alacritty/alacritty.toml; };
  home.file.".config/alacritty/colors.toml"    = { source = ../../config/alacritty/colors.toml; };
  home.file.".config/gtk-3.0/gtk.css"       = { source = ../../config/gtk-3.0/gtk.css; };
  home.file.".config/gtk-4.0/gtk.css"       = { source = ../../config/gtk-4.0/gtk.css; };

  # cava — конфиг для визуализатора
  home.file.".config/cava/config".text = ''
    [general]
    bars = 48
    framerate = 60
    autosens = 1

    [input]
    method = pulse
    source = auto

    [output]
    method = ncurses
    channels = mono

    [color]
    background = '#00000000'
    foreground = '#c0caf5'

    [smoothing]
    monstercat = 0
    waves = 0
    noise_reduction = 0.77
  '';

  home.file.".local/bin" = { source = ../../scripts; recursive = true; };

  home.file.".gtkrc-2.0" = { text = ''
    gtk-theme-name="Adwaita-dark"
    gtk-icon-theme-name="Papirus-Dark"
    gtk-cursor-theme-name="capitaine-cursors"
    gtk-font-name="JetBrains Mono Nerd Font 11"
  ''; };

  gtk = {
    enable = true;
    theme = { name = "adw-gtk3-dark"; package = pkgs.adw-gtk3; };
    iconTheme = { name = "Papirus-Dark"; package = pkgs.papirus-icon-theme; };
    cursorTheme = { name = "capitaine-cursors"; package = pkgs.capitaine-cursors; };
    font = { name = "JetBrains Mono Nerd Font"; size = 11; };
  };

  services.mako.enable = true;

  programs.git = {
    enable = true;
    userName = "user";
    userEmail = "user@example.com";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    initExtra = builtins.readFile ../../config/zsh/zshrc;
  };

  programs.bash.enable = true;
}
