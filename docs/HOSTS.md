# Хосты

Как из `hosts/`, `home/` и `modules/` собирается одна машина.

## Структура

```
hosts/<name>/          — NixOS-конфиг
  default.nix          — точка входа, импортит модули
  disko.nix            — опционально, декларативная разметка
  hardware-configuration.nix        — генерируется, в .gitignore
  hardware-configuration.nix.sample — образец для справки

home/<name>/           — home-manager-конфиг
  home.nix             — пакеты пользователя, дотфайлы, shell

modules/nixos/         — системные модули, переиспользуются
  services/*.nix
modules/home/          — пользовательские модули
```

Имя хоста в `hosts/<name>/` должно совпадать с именем в `home/<name>/`.
`flake.nix` автоматически находит все подпапки в `hosts/`, у которых есть
`default.nix`.

## Как собирается

1. `flake.nix` перебирает папки в `hosts/`.
2. Для каждой вызывает `nixosSystem` со `specialArgs = { inputs, overlays }`.
3. Импортирует `hosts/<name>/default.nix` — тот подключает `modules/nixos`.
4. Подключает `home-manager.nixosModules.home-manager` и назначает
   пользователю `home/<name>/home.nix`.
5. `home.nix` раскладывает файлы из `config/` и `scripts/` в домашнюю
   директорию через `home.file`.

## Что идёт куда

| Слой | Файл | Отвечает за |
|---|---|---|
| Система | `hosts/<name>/default.nix` | загрузчик, сеть, locale, GPU, юзеры |
| Системные сервисы | `modules/nixos/services/*.nix` | tor, vpn, browsers, login, lock, virtualisation |
| Пользователь | `home/<name>/home.nix` | пакеты, дотфайлы, shell, GTK-тема |
| Home-сервисы | `modules/home/*.nix` | то, что живёт в сессии пользователя |
| Пакеты | `pkgs/<pkg>/` | свои сборки, которых нет в nixpkgs |

## Добавить новый хост

```sh
# 1. Скопировать структуру
cp -r hosts/niri hosts/<new>
cp -r home/niri  home/<new>

# 2. Править под новое железо
$EDITOR hosts/<new>/default.nix   # hostName, GPU-секция, юзеры
$EDITOR home/<new>/home.nix       # home.username, homeDirectory

# 3. Сборка
sudo nixos-rebuild switch --flake .#<new>
```

`flake.nix` менять не надо — он найдёт папку сам.

## Что специфично для хоста

Почти всегда нужно править:

- `networking.hostName` — имя машины
- `hardware.graphics` / `hardware.nvidia` — раскомментировать нужное
- `boot.loader.*` — systemd-boot или GRUB
- `fileSystems.*` — приходят из `hardware-configuration.nix`
- `services.anirevpn.endpoint` — если VPN, для каждой машины свой
- `users.users.<name>` — имя пользователя

Всё остальное (waybar, niri, mako, fuzzel, скрипты) берётся из `config/`
и `scripts/` и одинаково на всех машинах.

## Импорт hardware-configuration.nix

Файл генерируется при установке и **не коммитится** (содержит UUID дисков).
Импортируется опционально, чтобы `nix flake check` работал до установки:

```nix
imports = [
  ../../modules/nixos
] ++ lib.optionals (builtins.pathExists ./hardware-configuration.nix) [
  ./hardware-configuration.nix
];
```

## Модули

Если что-то нужно на нескольких хостах — вынести в `modules/nixos/`.

Пример — `modules/nixos/services/browsers.nix`:

```nix
options.services.browsers = {
  enable = lib.mkEnableOption "browsers";
  default = lib.mkOption {
    type = lib.types.enum [ "helium" "librewolf" ];
    default = "helium";
  };
};

config = lib.mkIf cfg.enable { … };
```

Хост включает через `services.browsers.enable = true;`. Опции описывают
поведение, реализация прячется внутри модуля.
