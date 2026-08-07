# Home-manager config: user-level packages + dotfile management.
# Niri, waybar, fuzzel, wlogout and helpers — all pulled from this repo.
{ pkgs, config, ... }:

{
  imports = [
    ../../modules/home          # shared home-modules aggregator
  ];

  home.username = "user";
  home.homeDirectory = "/home/user";
  home.stateVersion = "24.11";

  # PATH additions so scripts (wallpaper.sh, ctrl.sh, ...) are reachable.
  home.sessionPath = [ "~/.local/bin" ];

  # Make sure the shell knows this is a niri/wayland session.
  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    QT_QPA_PLATFORM = "wayland";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
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
    swaybg            # wallpaper
    mako              # notifications
    wl-clipboard      # wl-copy / wl-paste (cliphist)

    # Screenshots / recording
    grim
    slurp
    swappy
    wf-recorder

    # Password manager
    keepassxc

    # File manager (nemo + extensions)
    nemo-with-extensions   # openwith, gtk4, image-converter, preview, media-tags...

    # GTK theme pieces (icon/cursor; accent overlay ships via colorscheme)
    papirus-icon-theme
    capitaine-cursors

    # Graphics / palette
    (python3.withPackages (ps: with ps; [ pillow ])) # colorscheme.py
    libnotify         # notify-send

    # Media / audio / input
    playerctl
    wpctl
    brightnessctl
    gammastep         # nightlight

    # Network / bluetooth tooling
    bluez             # bluetoothctl
    cliphist          # clipboard history

    # Utils
    jq
    yq
  ];

  # ---- Dotfiles: symlink repo files into $HOME/.config ----
  home.file.".config/niri" = {
    source = ../config/niri;
    recursive = true;
  };

  home.file.".config/waybar/config.jsonc" = { source = ../config/waybar/config.jsonc; };
  home.file.".config/waybar/style.css"    = { source = ../config/waybar/style.css; };

  home.file.".config/fuzzel/fuzzel.ini"   = { source = ../config/fuzzel/fuzzel.ini; };

  home.file.".config/wlogout/layout"      = { source = ../config/wlogout/layout; };
  home.file.".config/wlogout/style.css"   = { source = ../config/wlogout/style.css; };

  home.file.".config/mako/config"         = { source = ../config/mako/config; };

  home.file.".config/nvim" = {
    source = ../config/nvim;
    recursive = true;
  };
  home.file.".config/tmux/tmux.conf" = { source = ../config/tmux/tmux.conf; };

  # GTK theme overlay (accent from wallpaper palette)
  home.file.".config/gtk-3.0/gtk.css" = { source = ../config/gtk-3.0/gtk.css; };
  home.file.".config/gtk-4.0/gtk.css" = { source = ../config/gtk-4.0/gtk.css; };
  home.file.".gtkrc-2.0" = { text = ''
    gtk-theme-name="Adwaita-dark"
    gtk-icon-theme-name="Papirus-Dark"
    gtk-cursor-theme-name="capitaine-cursors"
    gtk-font-name="JetBrains Mono Nerd Font 11"
  ''; };

  # Base GTK theme + icons + cursor for all GTK apps (nemo, dialogs, ...).
  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "capitaine-cursors";
      package = pkgs.capitaine-cursors;
    };
    font = {
      name = "JetBrains Mono Nerd Font";
      size = 11;
    };
  };

  home.file.".config/alacritty/alacritty.toml" = { source = ../config/alacritty/alacritty.toml; };
  # colors.toml is generated from the wallpaper; provide a valid default first.
  home.file.".config/alacritty/colors.toml"   = { source = ../config/alacritty/colors.toml; };

  # ---- Scripts into ~/.local/bin (so bindings can call them bare) ----
  home.file.".local/bin" = {
    source = ../scripts;
    recursive = true;
  };
  home.file.".local/bin/lib.sh" = { source = ../lib/lib.sh; };

  # ---- Services ----
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
    # Load the dotfile zshrc (prompt, history, aliases) into the HM-generated one.
    initExtra = builtins.readFile ../config/zsh/zshrc;
  };

  programs.bash.enable = true;
}