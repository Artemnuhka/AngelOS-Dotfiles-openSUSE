# angelOS ♡

Пиксельная розовая оболочка для **niri** на **Quickshell** в духе NEEDY GIRL OVERDOSE.
Светлая тема «angel» и тёмная «overdose», три вкуса палитры, блюр через
`ext-background-effect`.

## Что внутри

- **Рабочий стол**: обои на каждый монитор и воркспейс, пиксельный переход
  (мозаика + дизер Байера) при смене воркспейса, ПКМ-меню (пункты дают плагины).
- **Анимации воркспейсов**: NGO-попап `workspace_N.exe`, полоска сердечек справа.
- **Лирика** посередине панели: текущая строка песни (lrclib.net + MPRIS),
  печатная машинка, старая строка уезжает вверх.
- **Виджеты рабочего стола**: часы, системный монитор (CPU/GPU/RAM/VRAM/сеть),
  визуализатор cava, «сейчас играет» и виджеты плагинов — таскаются за заголовок,
  добавляются через ПКМ → Вид (двойной клик по заголовку — режим правки).
- **ПКМ по обоям** в духе Windows 11: быстрые действия, Вид ▸ / Создать ▸ / Открыть ▸,
  параметры экрана, персонализация, терминал, «Показать больше» для плагинов.
- **Мастер первого запуска и подсказки**: при первом входе — мастер, потом подсказки,
  которые обводят элементы интерфейса кружком (повторить: Внешний вид → Подсказки).
- **Панель** трёх видов: таскбар Win98 / полоса сверху / плавающий остров.
  Пуск-меню, сердечки воркспейсов, кнопки окон, трей, раскладка, громкость, часы
  с календарём и историей уведомлений, мини-плеер.
- **Уведомления**, **OSD** громкости/раскладки, **лаунчер** (Mod+Space),
  **буфер обмена** (Mod+V), **меню выключения**, **экран блокировки** (PAM),
  **polkit-агент**.
- **Настройки**: Внешний вид, Обои, Панель (раскладка, сердечки или иконки
  воркспейсов, ширина кнопок окон, цвет иконок трея), Воркспейсы, Лирика, Монитор,
  Окна (ширина новых окон, пресеты Mod+R, своя ширина для каждого приложения),
  По умолчанию (браузер, редактор, файлы, терминал, медиа…), голосовой ввод VoxType
  (схема с перетаскиванием, пишет monitor.kdl), Клавиатура и мышь (пишет
  cfg/input.kdl), Звук, Уведомления, Плагины, Dotfiles, System.
- **Плагины** — см. [docs/PLUGINS.md](docs/PLUGINS.md). В комплекте:
  котик на панели (бежит от нагрузки CPU), спидтест со спидометром, веб-поиск
  в лаунчере (`web …`), Claude Companion (пульс сессий Claude Code, сфера на
  столе, `claude …` / `claude ? вопрос`, MCP-мост «angelos»), ночной свет
  (wlsunset), быстрые действия и стрим-статы (выключены), заготовка `_template`.
- **Dotfiles одной кнопкой**: git pull + установщик репозитория, перед этим снимок
  конфигов в `~/.local/state/angelos/backups/`.

## Новое (2026-09-29)

- **Пуск по Meta, как в Windows**: короткое нажатие Super открывает «Пуск»,
  удержание и сочетания Mod+… — нет. Стрелки, Enter, печать сразу ищет в лаунчере.
  Выключается в Настройки → Панель → Кнопка «Пуск». Слушатель читает клавиатуры
  только на чтение (группа `input`, python-evdev) и не запоминает, какие клавиши
  нажаты. Поверх полноэкранных игр по умолчанию не открывается.
- **Шрифты**: Настройки → Шрифты и шаг мастера первого запуска — наборы
  angelOS / Arcade (Press Start 2P + Tiny5 + Monocraft) / Soft pixels
  (Pixelify Sans + Departure Mono) / Blocky (Monocraft), всё с кириллицей.
  Скачиваются по закреплённым URL с проверкой SHA-256 в `~/.local/share/fonts/angelos`,
  размеры подгоняются под пиксельную сетку шрифта.
- **Цвета из обоев автоматически**: при схеме «Из обоев» новые обои сразу дают
  новый акцент (экран выбирается, результаты кэшируются).
- **Заставка (Idle)** как в Omarchy: ASCII-арт angelOS (или свой текст) с эффектами
  decrypt / rain / beams / wave / typewriter / hearts / glitch, часы, сердечки.
  «Пуск» → Заставка, меню выключения → Заставка, `angelos idle`, по простою.
- **Экран блокировки**: летающие сердечки, сердечко на каждый символ пароля,
  разбитое сердце при ошибке, фейерверк и пиксельное растворение при входе,
  Caps Lock / раскладка / заряд / сколько заблокировано / новые уведомления,
  NGO-«стрим» с LIVE, зрителями и чатом. Предпросмотр без блокировки:
  Настройки → Блокировка и заставка, `angelos lockPreview`.
- **Анимации смены воркспейса**: мягкий / слайд / подпрыг (пружины niri) и
  телепорт эндермена / пиксели / сердечко-диафрагма / глитч (мгновенное
  переключение + шейдер angelOS). Настройки → Воркспейсы.
- **Сайдбар (эксперимент)**: закладка на краю экрана, перетаскивается и
  прилипает к ближайшему краю; внутри переключатели, музыка, громкость и микрофон,
  система, лимиты Claude/Codex. Настройки → Панель → Сайдбар, `angelos sidebar`.
- **Codex Companion**: лимиты 5 ч / неделя / кредиты из логов Codex (если
  провайдер их присылает), токены за сегодня, сессии, `codex …` в лаунчере.
- **osu!mini**: мини-игра — сердечки в такт, клик или Z/X, комбо, ранги, рекорды,
  демо-режим. «Пуск» → Мини-игра osu!, `osu` в лаунчере.
- **Лирика по названию песни** из любого плеера (в т.ч. YouTube в браузере):
  название чистится, источники lrclib → NetEase → lyrics.ovh, ручной поиск.
- **Мастер плагинов через вход в браузере**: Claude-подписка (Claude Code) или
  ChatGPT (Codex CLI) вместо API-ключа.
- **Nautilus по умолчанию**: «Открыть в терминале», mediafix для видео
  (встроенная копия из [MixaDoDs/mediafix](https://github.com/MixaDoDs/mediafix)),
  настройки 7z / мелкие значки / без дерева. Настройки → По умолчанию.
- **Скины скриншотов и записи**: верёвочки, `screenshot.exe` и «Стрим Ame».
  Настройки → Скриншоты.
- **Безопасность и баги**: текст из заголовков окон, плееров, буфера и
  уведомлений больше не рендерится как HTML (нет удалённых картинок), тела
  уведомлений через белый список тегов; буфер не сохраняет пароли из
  менеджеров паролей и не светит текст в argv; создание плагина без sed-инъекции;
  шаблоны тем экранируют значения; `~/.local/state/angelos` — 0700; пинг
  спидтеста «1800000 мс» показывается как «—»; оболочка в простое тратит
  примерно в 4 раза меньше CPU (пошаговые анимации вместо 60 fps).

## Установка / переключение

```sh
sudo pacman -S --needed quickshell
ln -sfn ~/.config/quickshell/angelos/bin/angelos ~/.local/bin/angelos
angelos switch angelos      # бэкап, правка niri/тем приложений, запуск (Noctalia остановится)
angelos switch noctalia     # вернуть как было из бэкапа
```

Если пакета quickshell ещё нет, `~/.local/bin/qs` запускает локальную копию из
`~/.local/opt/quickshell` (так же `wlsunset`); после `pacman -S quickshell wlsunset`
обёртки сами переключаются на системные версии — их можно удалить.

## Хоткеи (после switch)

| | |
|---|---|
| Mod+Space | программы |
| Mod+V | буфер обмена |
| Mod+S / Mod+Alt+S | настройки |
| Mod+Shift+Return | обои |
| Mod+Alt+L | блокировка |
| Mod+Shift+Q | выключение |
| Mod+Alt+Y | лирика вкл/выкл |
| Mod+Alt+T | светлая/тёмная |
| Meta (коротко) | меню «Пуск» |

## CLI

`angelos help` — список IPC-функций. Примеры: `angelos theme toggle`,
`angelos wallpaper random`, `angelos bar island`, `angelos settings monitor`,
`angelos testFx DP-1`, `angelos restart`, `angelos log`.

## Файлы

- код: `~/.config/quickshell/angelos/`
- настройки: `~/.config/angelos/settings.json`
- свои плагины: `~/.config/angelos/plugins/`, шаблоны: `~/.config/angelos/templates/`
- бэкапы и история: `~/.local/state/angelos/`
- кэш лирики: `~/.cache/angelos/lyrics/`

Отладка без вмешательства в живую сессию:
`ANGELOS_DEV=1 ANGELOS_SCREENS=HDMI-A-1 qs -p ~/.config/quickshell/angelos` —
только выбранные мониторы, без записи тем приложений и буфера, окна не забирают фокус.

### Настройка интерфейса / Interface setup

- «Внешний вид» / Appearance: Русский и English, основная Overdose,
  Bubblegum, Cyber Angel, Gruvbox, Rosé Pine, Catppuccin, Nord, Dracula,
  Tokyo Night, Solarized, Everforest. «Создать из обоев» извлекает акцент
  текущих обоев (Python Pillow); полученная палитра сохраняется в настройках.
- «Панель» / Bar → «Подписывать окна» / Show window titles: выключить для
  режима с иконками. Стрелка трея открывает скрытые значки; ПКМ открывает меню приложения.
- `angelos setup` повторно открывает мастер: хоткеи, мониторы, ввод, окна,
  цветовые схемы. При новой установке он открывается автоматически.
- «Поведение окон» / Window behavior сохраняет отступы и центрирование niri
  с отдельным бэкапом и откатом при ошибке `niri validate`.
- Lyrics с таймкодами показываются синхронно. Для текста без таймкодов панель
  показывает первую строку, полный текст доступен по клику в настройках Lyrics.
- Обычный запуск использует все экраны. `ANGELOS_SCREENS` ограничивает
  экраны только вместе с `ANGELOS_DEV=1`.
- `angelos diagnostics` выводит состояние Lyrics, геометрию панелей,
  текущую страницу настроек и открытые popup. `angelos panel claude HDMI-A-1`
  открывает выбранный popup (также доступны `cat`, `speedtest`, `tray`).

### Compact bar and visual refinements

Window buttons default to square application icons; toggle **Bar → Show window
titles** to restore labels. **Claude Companion → Limits → In the bar → Icon
only** hides usage percentages. **Lyrics → Beside the lyrics** selects a music
note or album cover (missing covers fall back to a note).

The Start button and menu use a theme-aware heart-window emblem and a font-based
wordmark. **Bar → angelOS logo** offers Classic 95 (Liberation Sans) and Angel +
(Pixeloid Sans), with clickable previews. The tray scrolls within a clipped viewport when many apps register.
Only the destination workspace heart bounces. Night light compares its actual
command parameters before restarting wlsunset; unrelated settings do not
restart the gamma-control process. AngelOS windows are excluded from the
general niri blur prohibition so their client-supplied blur regions work.

Right-click empty taskbar space for **Task Manager**. **System → Task Manager**
selects an installed monitor (btop first in Automatic mode), or a custom executable
with an optional terminal, and includes a launch button.

Right-click the wallpaper to open Home, Downloads, Documents, Pictures, Music or
Videos using the system's XDG directory paths. **New temporary text file** creates
a private, unique `/tmp/angelOS-note-*.txt` and opens the default text/plain editor,
including terminal editors. Save elsewhere to keep a note beyond temporary-file cleanup.

**Appearance → Glass and pixels** controls panel opacity, blur strength, passes
and grain. Strength, passes and grain affect niri's global blur configuration.
The helper validates a copied configuration before applying, saves a backup under
`~/.local/state/angelos/backups/blur-*`, and rolls back on final validation failure.
The workspace badge has its own reserved slot, so it cannot overlap task buttons.
