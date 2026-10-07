# Dotfiles

Мой набор конфигов для Linux. Композитор [niri](https://github.com/YaLTeR/niri),
единая цветовая палитра из обоев, декларативная установка через NixOS + home-manager.

## Что внутри

- `config/` — конфиги приложений (niri, waybar, mako, fuzzel, alacritty, tmux, nvim и др.)
- `scripts/` — исполняемые скрипты (меню, скриншоты, запись, обои, OSD)
- `hosts/` — NixOS-конфиги для разных машин
- `home/` — home-manager-конфиги
- `modules/` — переиспользуемые модули (tor, browsers, lock, virtualisation и др.)

Подробнее — в [docs/](docs/).

## Установка

**NixOS.** Через `nixos-install --flake`. См. [docs/INSTALL.md](docs/INSTALL.md).

**Другие дистрибутивы.** Из репозитория берутся только конфиги и скрипты,
пакеты ставятся штатным менеджером:

```sh
git clone https://github.com/k0dax09/dotfiles.git ~/Dotfiles
cd ~/Dotfiles
bash bootstrap.sh links
```

Nix-файлы (`flake.nix`, `hosts/`, `home/`, `modules/`) при этом игнорируются.

## Документация

- [docs/OVERVIEW.md](docs/OVERVIEW.md) — структура и логика
- [docs/CONFIG.md](docs/CONFIG.md) — конфиги приложений
- [docs/SCRIPTS.md](docs/SCRIPTS.md) — скрипты и хоткеи
- [docs/THEMING.md](docs/THEMING.md) — палитра и шаблоны
- [docs/HOSTS.md](docs/HOSTS.md) — как собирается конфиг хоста
