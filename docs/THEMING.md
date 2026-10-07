# Тема

Вся система окрашивается в палитру, извлечённую из текущих обоев.
Один источник цвета → niri, waybar, mako, fuzzel, wlogout, alacritty,
GTK, tmux, nvim.

## Как это работает

```
wallpaper.jpg
     │
     ▼
scripts/colorscheme.py        ← извлекает палитру
     │
     ├── config/templates/*.css    → config/waybar/style.css
     ├── config/templates/*.ini    → config/fuzzel/fuzzel.ini
     ├── config/templates/*.toml   → config/alacritty/colors.toml
     ├── config/templates/mako     → config/mako/config
     ├── config/templates/gtk.css  → config/gtk-3.0/gtk.css + gtk-4.0
     ├── config/templates/wlogout  → config/wlogout/style.css
     └── config/templates/niri-…   → config/niri/cfg/colors.kdl
```

Приложения читают результат по-разному: waybar и mako — по SIGHUP или
перезапуску, alacritty — по live-reload, niri — по перезагрузке конфига.

## Палитра

`colorscheme.py` извлекает 13 токенов:

| Токен | Что | Пример |
|---|---|---|
| `@{bg}` | основной фон | `#0d0d14` |
| `@{bg_alt}` | фон второго уровня | `#1a1a24` |
| `@{bg_t}` | полупрозрачный bg (для waybar) | `#0d0d14e0` |
| `@{surface}` | поверхность (карточки, hover) | `#2a2a38` |
| `@{fg}` | основной текст | `#e8eaf2` |
| `@{muted}` | вторичный текст | `#8e93a8` |
| `@{accent}` | акцент (активный workspace, курсор) | `#a8b4e0` |
| `@{red}` `@{green}` `@{yellow}` | семантика | `#f7768e` `#9ece6a` `#e0af68` |
| `@{blue}` `@{magenta}` `@{cyan}` | вторичные акценты | — |

Акцент берётся из самого частого цвета изображения. Фон — усреднённый,
затемнённый. Семантические цвета — фиксированные (красный, зелёный,
жёлтый), чтобы ошибки и предупреждения всегда были различимы.

## Шаблоны

В `config/templates/` лежат версии конфигов с токенами `@{…}`. Скрипт
подставляет значения и пишет результат в `config/<app>/`. Соответствие
«шаблон → выходной файл» — в `colorscheme.py`, словарь `OUTPUTS`.

Добавить новый шаблон:

1. Создать файл в `config/templates/`.
2. Использовать токены из палитры: `@{bg}`, `@{accent}` и т. д.
3. Добавить пару в `OUTPUTS` в `colorscheme.py`.
4. Запустить `wallpaper.sh` — новый конфиг сгенерируется.

## Использование

```sh
# Меню выбора обоев + генерация палитры
wallpaper.sh

# Конкретный файл
wallpaper.sh ~/Pictures/Wallpapers/saturn.png

# Только перегенерировать палитру (без смены обоев)
python3 scripts/colorscheme.py ~/.cache/dotfiles/wallpaper
```

## Где хранится состояние

| Файл | Что |
|---|---|
| `~/.cache/dotfiles/wallpaper` | Путь до текущих обоев |
| `~/.cache/dotfiles/apps/` | Кеш для отдельных приложений |

После перезагрузки `autostart.sh` поднимает `swaybg` с последними обоями,
палитра остаётся от прошлой генерации.

## Ручная правка палитры

Если автоматика даёт не тот акцент (например, фон занимает большую часть
картинки и перетягивает внимание), можно:

1. Открыть `scripts/colorscheme.py`.
2. В функции `extract()` заменить блок с `accent = …` на константу:

```python
accent = (168, 180, 224)   # RGB вручную
```

3. Запустить `wallpaper.sh` заново.
