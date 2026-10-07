# config/

Конфиги приложений. Каждая папка симлинкается в `~/.config/<name>/`
при установке (NixOS) или через `bootstrap.sh links` (без Nix).

Часть файлов помечена как **генерируемые** — их перезаписывает
`scripts/colorscheme.py` при смене обоев. См. [THEMING.md](THEMING.md).

## niri — композитор

Точка входа `config/niri/config.kdl`, остальное — модули в `cfg/`.

| Файл | Отвечает за |
|---|---|
| `cfg/animation.kdl` | Анимации: spring-параметры, длительности, кривые |
| `cfg/autostart.kdl` | Что запускается при старте сессии |
| `cfg/colors.kdl` | Focus-ring, border окон · **генерируемый** |
| `cfg/cursor.kdl` | Тема и размер курсора |
| `cfg/display.kdl` | Мониторы: режим, scale, положение |
| `cfg/input.kdl` | Клавиатура, тачпад, мышь |
| `cfg/keybinds.kdl` | Горячие клавиши |
| `cfg/layout.kdl` | Gaps, ширина колонок, центрирование |
| `cfg/misc.kdl` | Environment-переменные, blur, путь скриншотов |
| `cfg/rules.kdl` | Window-rules и layer-rules |

Биндинги: `Mod` = Super. Группы — приложения (`Mod+Return`, `Mod+B`,
`Mod+D`), окна (`Mod+Q`, `Mod+F`, `Mod+T`), фокус (`Mod+H/J/K/L`),
workspace (`Mod+1..9`), медиа (`XF86Audio*`), скриншоты (`Print`,
`Mod+Shift+S`). Полный список — в `keybinds.kdl`.

## waybar — панель

- `config/waybar/config.jsonc` — модули и их настройки.
- `config/waybar/style.css` — вид (пилюли, скругления) · **генерируемый**.

Секции: `modules-left` (workspaces, temp, ram, cpu), `modules-center`
(clock), `modules-right` (media, bluetooth, pulseaudio, network, vpn,
backlight, layout, power, tray).

## mako — уведомления

`config/mako/config`. Шрифт, размеры, скругления, `urgency=low/normal/critical`.
Поднимается сервисом `services.mako.enable`. · **генерируемый**.

## fuzzel — лаунчер и dmenu

`config/fuzzel/fuzzel.ini`. Используется как launcher (`Mod+D`) и как
dmenu-меню во всех скриптах (`ctrl.sh`, `wifi.sh`, `bluetooth.sh`, …).
· **генерируемый**.

## wlogout — power menu

- `config/wlogout/layout` — кнопки (poweroff, reboot, lock, logout, suspend).
- `config/wlogout/style.css` — вид · **генерируемый**.

## alacritty — терминал

- `config/alacritty/alacritty.toml` — шрифт, окно, копирование/вставка, keybindings.
- `config/alacritty/colors.toml` — палитра · **генерируемый**.

## GTK

- `config/gtk-3.0/gtk.css` — accent-overlay для GTK3.
- `config/gtk-4.0/gtk.css` — то же для GTK4.

Оба файла — результат работы `colorscheme.py`.

## tmux

`config/tmux/tmux.conf`. Prefix `C-b`, `|` и `-` для сплитов, vi-режим
в copy-mode, yank в `wl-copy`, статусбар в цветах палитры.

## nvim

`config/nvim/init.lua`. Без плагинов. Палитра tokyonight-storm
захардкожена в `nvim_set_hl`.

## zsh

`config/zsh/zshrc`. Prompt, история (shared, без дублей), алиасы,
`EDITOR=nvim`, SSH-agent.

## proxy

- `config/proxy/sing-box.json` — конфиг TUN-прокси. Используется модулем
  `services.anirevpn`. Сервер/UUID заполнить перед первым запуском.
- `config/proxy/xray.json` — альтернатива на xray-core.

## tor

`config/tor/torrc` — reference. Реальный `torrc` генерит NixOS из
`services.torclient` в `modules/nixos/services/tor.nix`.

## templates/

Шаблоны для `colorscheme.py`. Содержат токены `@{bg}`, `@{accent}` и т. д.
Скрипт читает шаблон, подставляет цвета, пишет результат в `config/<app>/`.
Соответствие «шаблон → выходной файл» — в `colorscheme.py`, словарь `OUTPUTS`.
