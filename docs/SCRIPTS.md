# scripts/

Исполняемые скрипты. Устанавливаются в `~/.local/bin/` (NixOS — через
home-manager, обычный Linux — через `bootstrap.sh`).

Общий хелпер — `lib.sh`. Даёт `$REPO_DIR`, `$CACHE_DIR`, `$WALLPAPER_DIR`,
функции `menu()` и `notify()`. Все скрипты сорсят его первой строкой
после shebang.

## Сессия

| Скрипт | Что делает |
|---|---|
| `autostart.sh` | Запускается один раз при старте niri. Обои, cliphist, трей-апплеты, polkit-agent, swayosd. |
| `firstrun.sh` | Разовый прогон после установки: папки, дефолтные обои, палитра. |

## Обои и цвета

| Скрипт | Что делает |
|---|---|
| `wallpaper.sh` | Меню выбора обоев (fuzzel). Применяет `swaybg`, запускает `colorscheme.py`. `wallpaper.sh <path>` — конкретный файл. |
| `colorscheme.py` | Читает обои, извлекает палитру, рендерит шаблоны в живые конфиги. |
| `gen-wallpapers.py` | Генерит дефолтные градиенты. Не требует Pillow. |

## Меню (fuzzel)

| Скрипт | Вызов | Что |
|---|---|---|
| `ctrl.sh` | `Mod+Shift+C` | Control center: volume, brightness, wifi, bt, nightlight |
| `wifi.sh` | `Mod+Shift+C` → wifi | Список сетей nmcli, подключение |
| `bluetooth.sh` | `Mod+Shift+C` → bt | Устройства, подключение |
| `media.sh` | `Mod+Ctrl+M` | play/pause/next/prev, громкость плеера |
| `ws.sh` | `Mod+Shift+O` | Прыжок на workspace 1..9 |
| `clip.sh` | `Mod+V` | История буфера (cliphist). `clip.sh store` — демон |

## Системные

| Скрипт | Что делает |
|---|---|
| `osd.sh` | OSD громкости/яркости. Использует `swayosd-client`, если есть. |
| `lock.sh` | swaylock с текущими обоями, blur. |
| `nightlight.sh` | Toggle gammastep. |
| `waybar-toggle.sh` | Спрятать/показать waybar. |

## Скриншоты и запись

| Скрипт | Что делает |
|---|---|
| `shot.sh` | `region` / `full` / `window`. Grim + slurp + swappy, в буфер. |
| `rec.sh` | Toggle записи wf-recorder. Сохраняет в `~/Videos/Recordings/`. |

## Сеть

| Скрипт | Что делает |
|---|---|
| `proxy.sh` | Toggle `anirevpn.service`. Статус, up, down. |
| `vpn.sh` | Toggle WireGuard `wg0` с nftables-killswitch. |

## Управление репо

| Скрипт | Что делает |
|---|---|
| `install.sh` | Установка на NixOS. `all` / `system` / `home` / `links`. |
| `manage.sh` | Ежедневные операции: `switch`, `home`, `status`, `format`. |
| `vm.sh` | QEMU-обёртка: `boot`, `install`, `run`, `disk`, `download`. |
| `layout.sh` | Текущая xkb-раскладка для waybar `custom/layout`. |

## lib.sh

Общий хелпер. Не запускается напрямую, сорсится:

```sh
. "$(dirname "$0")/lib.sh"
```

Даёт:

| Переменная | Что |
|---|---|
| `$REPO_DIR` | Путь до корня репозитория (по маркерам `flake.nix` + `scripts/`) |
| `$CACHE_DIR` | `~/.cache/dotfiles` — состояние (обои, pid) |
| `$WALLPAPER_DIR` | `~/Pictures/Wallpapers` |
| `$CURRENT_WALL` | Файл с путём до текущих обоев |
| `$FUZZEL_BIN` | Обычно `fuzzel` |
| `$NOTIFY_BIN` | Обычно `notify-send` |

| Функция | Что |
|---|---|
| `menu <prompt>` | Меню fuzzel. Читает со stdin, выводит выбранное в stdout |
| `notify <summary> <body>` | Уведомление через mako |
