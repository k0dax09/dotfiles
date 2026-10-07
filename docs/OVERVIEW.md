# Architecture

## Верхний уровень

```
flake.nix              — входная точка
bootstrap.sh           — установка без Nix
README.md, ROADMAP.md  — общее

config/                — конфиги приложений (→ ~/.config)
home/                  — home-manager по хостам
hosts/                 — NixOS по хостам
modules/               — переиспользуемые модули
lib/                   — устарело, переезжает в scripts/
scripts/               — исполняемые скрипты (→ ~/.local/bin)
pkgs/                  — локальные пакеты
wallpapers/            — дефолтные обои
nixos/                 — (для будущего) модули installer-ISO
installer/             — (для будущего) скрипты installer-ISO
```

## config/

Плоские папки по имени. Симлинкаются в `~/.config/<app>/`:

```
config/niri/           — композитор
config/waybar/         — панель
config/mako/           — уведомления
config/fuzzel/         — лаунчер
config/wlogout/        — power menu
config/alacritty/      — терминал
config/gtk-3.0/        — GTK3 accent overlay
config/gtk-4.0/        — GTK4 accent overlay
config/tmux/           — tmux
config/nvim/           — neovim
config/zsh/            — zsh
config/proxy/          — sing-box / xray
config/tor/            — tor reference
config/templates/      — шаблоны для colorscheme.py
```

**Шаблоны.** В `config/templates/` — версии с токенами `@{bg}`, `@{accent}`.
`scripts/colorscheme.py` берёт шаблон + обои → пишет живой конфиг.

## hosts/

```
hosts/niri/
  default.nix
  disko.nix
  hardware-configuration.nix        — генерится, в .gitignore
  hardware-configuration.nix.sample
hosts/mini/            — планируется
hosts/brother/         — планируется
```

## home/

```
home/niri/home.nix
home/mini/home.nix
home/brother/home.nix
```

## modules/

```
modules/home/default.nix
modules/nixos/default.nix
modules/nixos/services/
  anirevpn.nix
  browsers.nix
  lock.nix
  login.nix
  tor.nix
  virtualisation.nix
```

## scripts/

Копируются в `~/.local/bin/` (NixOS) или симлинкаются (bootstrap).

- Сессия: `autostart.sh`, `firstrun.sh`
- Обои и цвета: `wallpaper.sh`, `colorscheme.py`, `gen-wallpapers.py`
- Меню (fuzzel): `ctrl.sh`, `wifi.sh`, `bluetooth.sh`, `media.sh`, `ws.sh`, `clip.sh`
- Системные: `osd.sh`, `lock.sh`, `nightlight.sh`, `waybar-toggle.sh`
- Скриншоты и запись: `shot.sh`, `rec.sh`
- Сеть: `proxy.sh`, `vpn.sh`
- Управление: `install.sh`, `manage.sh`, `vm.sh`
- Хелпер: `lib.sh`

## Соглашения

1. `config/` — плоские приложения.
2. `hosts/<name>/default.nix` — специфика железа.
3. `home/<name>/home.nix` — специфика пользователя.
4. `scripts/*.sh` — shebang, `set -euo pipefail`, `. "$(dirname "$0")/lib.sh"`.
5. Не хардкодить пути. `lib.sh` даёт `$REPO_DIR`, `$CACHE_DIR`, `$WALLPAPER_DIR`.
