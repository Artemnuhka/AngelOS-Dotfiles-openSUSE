# Плагины angelOS

Плагин — это папка с `manifest.json` и QML-файлами:

```
~/.config/angelos/plugins/<id>/     ← твои плагины
~/.config/quickshell/angelos/plugins/<id>/  ← встроенные примеры
```

Быстрый старт: **Настройки → Плагины → Новый плагин** создаёт заготовку из
`plugins/_template` со всеми точками встраивания. Правишь QML — оболочка
перезагружается сама. Включить/выключить плагин можно там же.

Создание с ИИ: включи **Настройки → System → Режим разработчика** и открой
**Мастер плагинов** в настройках или «Пуске». Он уточняет идею, предлагает
план, генерирует файлы и устанавливает их после просмотра. Поддерживаются
OpenAI и Claude, русский и английский интерфейс. [Руководство мастера](PLUGIN_STUDIO.md).

## manifest.json

```json
{
  "id": "my-widget",
  "name": "Мой виджет",
  "version": "1.0.0",
  "author": "я",
  "description": "что он делает",
  "icon": "heart",
  "enabledByDefault": true,

  "menu": [
    { "label": "Терминал", "icon": "terminal", "exec": "kitty" },
    { "separator": true },
    { "label": "Обои…", "icon": "image", "settings": "wallpaper" },
    { "label": "Сайт", "icon": "info", "url": "https://example.com" }
  ],
  "menuComponent": "Menu.qml",
  "barWidget": "BarWidget.qml",
  "desktopWidget": "DesktopWidget.qml",
  "realms": ["heaven", "hell"],
  "settings": "Settings.qml",
  "main": "Main.qml",
  "launcher": "Launcher.qml"
}
```

Все поля кроме `id`/`name` необязательны. Точки встраивания:

| поле | куда попадает | свойства, которые получает компонент |
|---|---|---|
| `menu` | ПКМ-меню рабочего стола (декларативно). `exec` — команда sh, `settings` — открыть страницу настроек, `url` — xdg-open | — |
| `menuComponent` | QML-элементы в ПКМ-меню (обычно `PxMenuItem`) | `plugin`, `menu` (вызови `menu.close()`) |
| `barWidget` | панель, рядом с треем (все три стиля) | `plugin`, `screenName`, `barWindow` |
| `desktopWidget` | виджет на рабочем столе: angelOS сам рисует рамку с заголовком `desktopTitle`, перетаскивание и удаление; добавляется через ПКМ → Вид | `plugin`, `screenName`, `widget` (`{uid, x, y, settings}`) |
| `settings` | страница в Настройки → Плагины → имя | `plugin` |
| `main` | фоновый сервис, живёт пока плагин включён (можно держать тут `IpcHandler`) | `plugin` |
| `launcher` | провайдер результатов лаунчера (Mod+Space) | `plugin`, `pluginId` |
| `sidebarWidget` | блок в экспериментальном сайдбаре (раздел «AI-лимиты»), ширина задаётся сайдбаром | `plugin`, `width` |

`name` и `description` могут быть строкой или объектом `{"ru": "…", "en": "…"}` —
тогда показывается вариант на языке интерфейса.

## Провайдер лаунчера

```qml
QtObject {
    property var plugin
    property string pluginId
    readonly property string prefix: "web"   // «web запрос» — только этот провайдер
    readonly property bool global: true      // участвовать в обычном поиске
    signal changed                           // дёрни, когда подгрузились асинхронные данные

    // text — запрос без префикса; prefixed — набран ли префикс
    function query(text, prefixed) {
        return [{ id: "open:1", title: "Заголовок", subtitle: "подпись",
                  icon: "heart",            // пиксельная иконка
                  image: "/путь/к/png",     // или картинка
                  score: 50 }];             // приложения: 20–130
    }
    function activate(id, row) { /* вернуть true, чтобы лаунчер не закрывался */ }
}
```

Готовые примеры: `plugins/web-search` (префикс `web`, фавиконки, MRU),
`plugins/claude-companion` (префикс `claude`), `plugins/codex-companion`
(префикс `codex`) и `plugins/osu-mini` (`osu`).

Имена файлов плагина не должны совпадать с синглтонами `qs.services`
(`Sidebar`, `Idle`, `Fonts`, `Capture`, `MetaTap`, …): QML путает типы.

Объяви в корне компонента те свойства, которые используешь, например
`property var plugin` и `property string screenName`.

Виджет рабочего стола — это только содержимое: размер берётся из `implicitWidth` /
`implicitHeight`, рамку «*.exe» рисует angelOS. Виджеты рисуются в поверхности
обоев (backdrop niri): она не принимает ввод, поэтому angelOS ловит мышь
невидимым прокси и передаёт виджету настоящие события Qt — нажатия, hover,
колесо работают как обычно; перетаскивание за заголовок делает хост. Необязательное
`property bool wantVisible` прячет рамку, когда показывать нечего (в режиме правки
виджет всё равно виден полупрозрачным, чтобы его можно было подвинуть).

## Два измерения: рай и ад

Когда пользователь скидывает ангела в ад, правит демоница: обои становятся
пиксельным адом, а виджеты рабочего стола сгорают и встают адскими (Y2K →
Ангел или демон → «Виджеты в аду»). Виджет плагина должен уметь оба вида:

- в манифесте `"realms": ["heaven", "hell"]` — «я рисую ад сам». Без этого
  angelOS в аду перекрашивает виджет шейдером (запасной вариант);
- `Theme.realm` — `"heaven"` или `"hell"`, `Theme.hell` — `true` в аду. Просто
  привязывайся к ним: переключение идёт посреди сгорания, само сгорание и адскую
  рамку (обсидиан, пламя, капли) рисует хост — сам переход не анимируй;
- ад — не перекраска, а своя версия с теми же данными и кнопками на тех же
  местах: часы римскими цифрами (`Theme.roman(n)`), CPU — «Жар», обложка —
  горящая пластинка, счётчики — «души». Размер почти тот же (±20 %);
- палитра ада: `Theme.hellBody / hellFace / hellFaceAlt / hellSunken`
  (обсидиан), `hellEdge / hellHi / hellLo` (фаски), `hellBlood`, `hellEmber`,
  `hellFlame`, `hellGold`, `hellText` (кость), `hellTextDim`, а ещё `hellPlate` —
  спокойная подложка под текстом, `hellRim` — кромка рамок, `hellAccent` — единственный
  акцент. Цвета задаёт текущий вид ада (`story/circles.json`, `HellLook`), они могут
  меняться на ходу — привязывайся к токенам, не копируй значения. `hellText`,
  `hellTextDim` и `hellAccent` всегда читаются на `hellPlate` (контраст ≥ 4.5:1);
- шрифт `Theme.fontHell` — Jacquard 24, пиксельная готика, только латиница:
  проверяй `Theme.latin(text)`, чётко в `Theme.hellPx(n)` = 24·n px;
- контролы: `PxBox { hell: Theme.hell }`, `PxButton { hell: Theme.hell }`;
  иконки `skull`, `pentagram`, `fire`.

Встроенные виджеты (часы, sysmon, cava, музыка) — живые примеры.

## Объект `plugin`

```js
plugin.id, plugin.dir, plugin.manifest
plugin.get("key", default)   // настройки плагина (хранятся в ~/.config/angelos/settings.json)
plugin.set("key", value)
plugin.settings()            // весь объект настроек
plugin.url("file.png")       // file:// URL внутри папки плагина
```

## Что можно импортировать

```qml
import qs.config    // Config (настройки), Theme (цвета, размеры, шрифты)
import qs.widgets   // PxWindow, PxBox, PxButton, PxToggle, PxSlider, PxField, PxCombo,
                    // PxGroup, PxText, PxIcon, PxHearts, PxMenuItem, SettingRow, AppIcon…
import qs.services  // Niri, Audio, Lyrics, Notifs, Wallpapers, Plugins, Shell, Clipboard…
import Quickshell   // и остальное из Quickshell
```

Свои синглтоны кладутся рядом с `qmldir` (см. `plugins/stream-stats`, `plugins/cat`).
Свою пиксельную картинку можно нарисовать прямо в плагине: `PxIcon { bitmap: ["..#..", ".#o#.", …] }`.
Попап у виджета панели — `import qs.modules.bar` и `BarPopup { anchorItem: … }` (см. `plugins/speedtest`).

### Полезное

- `Theme.u` — размер арт-пикселя; все отступы — кратные ему.
- `Theme.accent / accent2 / accent3 / face / text / edge …` — меняются вместе с темой.
- Иконки: `PxIcon { name: "heart" }` — список в `widgets/Icons.js`, свои рисуются
  ASCII-битмапом (`#` контур, `o` розовый, `x` голубой, `y` жёлтый, `w` белый, `f` фон, `r` красный).
- `Shell.openSettings("wallpaper")`, `Shell.sh("команда")`, `Shell.terminal("команда")`.
- `Niri.action("FocusWorkspaceDown", {})`, `Niri.workspaces`, `Niri.windows`.

## Шаблоны тем

Помимо плагинов, темы для приложений тоже расширяемые: положи в
`~/.config/angelos/templates/` JSON вида

```json
[{ "id": "mytool", "name": "Mytool", "template": "mytool.conf",
   "target": "~/.config/mytool/colors.conf", "reload": "pkill -USR1 mytool" }]
```

и файл шаблона рядом. Плейсхолдеры: `{{accent}}` → `#ff5cad`, `{{accent.strip}}` →
`ff5cad`, `{{bg}} {{fg}} {{color0..15}} {{mode}} {{flavor}}` и все токены темы.
