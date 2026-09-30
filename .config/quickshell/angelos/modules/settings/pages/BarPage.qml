import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets
import qs.modules.settings

PxPage {
    heading: I18n.t("Панель", "Bar")
    subtitle: I18n.t("Три вида: таскбар как в Win98, тонкая полоса сверху или плавающий остров.", "Choose a taskbar, a top strip, or a floating island.")

    PxGroup {
        title: I18n.t("Кнопка «Пуск»", "Start button")
        icon: "pill"
        width: parent.width
        SettingRow {
            id: startStyleRow
            preview: "StartMenu"
            label: I18n.t("Вид меню", "Menu style")
            hint: Config.bar.startStyle === "win11" ? I18n.t("по центру: поиск, закреплённые (ПКМ — закрепить), все приложения, питание", "Centred: search, pinned apps (right-click pins), all apps, power") : Config.bar.startStyle === "fullscreen" ? I18n.t("на весь экран, как на iPhone: страницы иконок, док, колесо листает", "Full screen like an iPhone: pages of icons, a dock, the wheel flips pages") : I18n.t("список как в Win98 у кнопки", "A Win98 list next to the button")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Классика", "Classic"),
                        "value": "classic"
                    },
                    {
                        "label": "Windows 11",
                        "value": "win11"
                    },
                    {
                        "label": I18n.t("Как iPhone", "iPhone-like"),
                        "value": "fullscreen"
                    }
                ]
                currentValue: Config.bar.startStyle
                onActivated: v => {
                    Config.bar.startStyle = v;
                    startStyleRow.show(v, ({
                            "classic": I18n.t("классика", "classic"),
                            "win11": "Windows 11",
                            "fullscreen": I18n.t("как iPhone", "iPhone-like")
                        })[v]);
                }
            }
        }
        SettingRow {
            id: startPosRow
            preview: "StartMenu"
            visible: Config.bar.startStyle !== "fullscreen"
            label: I18n.t("Где открывать", "Position")
            hint: I18n.t("«Авто»: классика — у кнопки, Windows 11 — посередине", "Auto: classic at the button, Windows 11 in the middle")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Авто", "Auto"),
                        "value": "auto"
                    },
                    {
                        "label": I18n.t("Слева", "Left"),
                        "value": "left"
                    },
                    {
                        "label": I18n.t("Посередине", "Center"),
                        "value": "center"
                    },
                    {
                        "label": I18n.t("Справа", "Right"),
                        "value": "right"
                    }
                ]
                currentValue: Config.bar.startAlign || "auto"
                onActivated: v => {
                    Config.bar.startAlign = v;
                    startPosRow.show(v, ({
                            "auto": I18n.t("авто", "auto"),
                            "left": I18n.t("слева", "left"),
                            "center": I18n.t("посередине", "center"),
                            "right": I18n.t("справа", "right")
                        })[v]);
                }
            }
        }
        SettingRow {
            visible: Config.bar.startStyle !== "fullscreen"
            label: I18n.t("Размер меню", "Menu size")
            hint: I18n.t("ширина; у Windows 11 вместе с ней растёт число колонок", "Width; the Windows 11 menu gains columns as it grows")
            PxSlider {
                width: parent.width
                from: 70
                to: 180
                stepSize: 10
                value: Config.bar.startWidth || 100
                suffix: " %"
                onReleased: v => Config.bar.startWidth = v
            }
        }
        SettingRow {
            visible: Config.bar.startStyle === "win11"
            label: I18n.t("Рядов закреплённых", "Pinned rows")
            hint: I18n.t("выше меню — больше приложений без прокрутки", "A taller menu shows more apps without scrolling")
            PxSpin {
                from: 2
                to: 6
                value: Config.bar.startRows || 3
                onMoved: v => Config.bar.startRows = v
            }
        }
        Row {
            visible: Config.bar.startStyle !== "fullscreen"
            spacing: Theme.u * 3
            PxButton {
                compact: true
                icon: "pill"
                text: I18n.t("Открыть «Пуск»", "Open Start")
                onClicked: Shell.openStart(Shell.focusedScreen ? Shell.focusedScreen.name : "")
            }
            PxButton {
                compact: true
                icon: "refresh"
                text: I18n.t("Размер по умолчанию", "Default size")
                onClicked: {
                    Config.bar.startWidth = 100;
                    Config.bar.startRows = 3;
                }
            }
        }
        SettingRow {
            label: I18n.t("Открывать по нажатию Meta", "Open with a Meta tap")
            hint: I18n.t("короткое нажатие Super — меню «Пуск», как в Windows. Зажатая клавиша и сочетания (Mod+…) меню не открывают.", "A short Super tap opens Start, like on Windows. Holding it or shortcuts (Mod+…) never do.")
            PxToggle {
                checked: Config.bar.metaTap
                onToggled: c => Config.bar.metaTap = c
            }
        }
        SettingRow {
            visible: Config.bar.metaTap
            label: I18n.t("Самое долгое нажатие", "Longest tap")
            hint: I18n.t("дольше — это уже удержание", "Anything longer counts as a hold")
            PxSlider {
                width: parent.width
                from: 150
                to: 1000
                stepSize: 50
                value: Config.bar.metaTapMs
                suffix: I18n.t(" мс", " ms")
                onReleased: v => Config.bar.metaTapMs = v
            }
        }
        SettingRow {
            visible: Config.bar.metaTap
            label: I18n.t("Поверх полноэкранных окон", "Over fullscreen windows")
            hint: I18n.t("выключено — игры и видео на весь экран не прерываются", "Off: fullscreen games and video are never interrupted")
            PxToggle {
                checked: Config.bar.metaTapFullscreen
                onToggled: c => Config.bar.metaTapFullscreen = c
            }
        }
        PxText {
            visible: Config.bar.metaTap && MetaTap.status !== "ready"
            width: parent.width
            wrapMode: Text.Wrap
            color: MetaTap.status === "noperm" || MetaTap.status === "noevdev" || MetaTap.status === "error" ? Theme.danger : Theme.textDim
            text: ({
                    "noperm": I18n.t("Нет доступа к клавиатурам. Добавь себя в группу input: sudo usermod -aG input $USER и перезайди.", "No access to keyboards. Join the input group: sudo usermod -aG input $USER, then log in again."),
                    "noevdev": I18n.t("Нужен python-evdev: sudo pacman -S python-evdev", "python-evdev is required: sudo pacman -S python-evdev"),
                    "error": I18n.t("Слушатель клавиши остановился, перезапускаю…", "The key listener stopped; restarting…"),
                    "off": Shell.dev ? I18n.t("В dev-режиме выключено (ANGELOS_DEV_TAP=1 включит)", "Off in dev mode (set ANGELOS_DEV_TAP=1)") : "",
                    "starting": "…"
                })[MetaTap.status] || ""
        }
        PxText {
            visible: Config.bar.metaTap
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            text: I18n.t("niri не умеет назначать действие на одиночный модификатор, поэтому angelOS слушает клавиатуры сам (только чтение). Запоминается лишь «Meta нажата» и «было что-то ещё» — какие клавиши нажимались, никуда не пишется.", "niri cannot bind a bare modifier, so angelOS reads keyboards itself (read-only). It only tracks “Meta is down” and “something else happened”; which keys you press is never stored.")
        }
    }

    PxGroup {
        title: I18n.t("Сайдбар (эксперимент)", "Sidebar (experimental)")

        advanced: true
        icon: "layers"
        width: parent.width
        SettingRow {
            label: I18n.t("Включить сайдбар", "Enable the sidebar")
            hint: I18n.t("закладка на краю экрана: клик — открыть, перетащи — переставить (прилипает к ближайшему краю)", "A tab on the screen edge: click to open, drag to move — it snaps to the nearest edge")
            PxToggle {
                checked: Config.sidebar.enabled
                onToggled: c => Config.sidebar.enabled = c
            }
        }
        SettingRow {
            visible: Config.sidebar.enabled
            label: I18n.t("Экран", "Screen")
            PxCombo {
                width: Theme.u * 100
                model: [{
                        "label": I18n.t("Основной", "Primary"),
                        "value": ""
                    }].concat(Quickshell.screens.map(s => ({
                            "label": s.name,
                            "value": s.name
                        })))
                currentValue: Config.sidebar.screen
                onActivated: v => Config.sidebar.screen = v
            }
        }
        SettingRow {
            visible: Config.sidebar.enabled
            label: I18n.t("Разделы", "Sections")
            Flow {
                width: parent.width
                spacing: Theme.u * 5
                Repeater {
                    model: [["toggles", I18n.t("Переключатели", "Toggles")], ["media", I18n.t("Музыка", "Media")], ["sound", I18n.t("Звук", "Sound")], ["system", I18n.t("Система", "System")], ["ai", I18n.t("AI-лимиты", "AI limits")]]
                    PxCheck {
                        required property var modelData
                        text: modelData[1]
                        checked: Sidebar.has(modelData[0])
                        onToggled: c => Sidebar.setSection(modelData[0], c)
                    }
                }
            }
        }
        Row {
            visible: Config.sidebar.enabled
            spacing: Theme.u * 4
            PxButton {
                text: I18n.t("Открыть", "Open")
                icon: "layers"
                onClicked: {
                    Shell.settingsOpen = false;
                    Sidebar.open = true;
                }
            }
            PxButton {
                text: I18n.t("Закладку — на место", "Reset tab position")
                icon: "refresh"
                onClicked: {
                    Config.sidebar.edge = "right";
                    Config.sidebar.offset = 0.5;
                }
            }
        }
    }

    PxGroup {
        title: I18n.t("Стиль", "Style")
        icon: "window"
        width: parent.width
        SettingRow {
            id: barStyleRow
            preview: "BarStyle"
            label: I18n.t("Вид панели", "Bar style")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Таскбар", "Taskbar"),
                        "value": "taskbar"
                    },
                    {
                        "label": I18n.t("Полоса", "Strip"),
                        "value": "top"
                    },
                    {
                        "label": I18n.t("Остров", "Island"),
                        "value": "island"
                    }
                ]
                currentValue: Config.bar.style
                onActivated: v => {
                    Config.bar.style = v;
                    barStyleRow.show(v, ({
                            "taskbar": I18n.t("таскбар", "taskbar"),
                            "top": I18n.t("полоса", "strip"),
                            "island": I18n.t("остров", "island")
                        })[v]);
                }
            }
        }
        SettingRow {
            label: I18n.t("Подписывать окна", "Show window titles")
            hint: I18n.t("подписи видны, пока хватает места; дальше только иконки, потом прокрутка. Выключи — всегда иконки", "Titles show while there is room, then icons only, then scrolling. Off: always icons")
            PxToggle {
                checked: Config.bar.taskLabels
                onToggled: c => Config.bar.taskLabels = c
            }
        }
        SettingRow {
            visible: Config.bar.taskLabels
            label: I18n.t("Ширина кнопок окон", "Window button width")
            hint: I18n.t("мин и макс: кнопки сужаются, когда окон много", "min and max: buttons shrink when many windows are open")
            Column {
                width: parent.width
                spacing: Theme.u * 2
                PxSlider {
                    width: parent.width
                    from: 16
                    to: 120
                    stepSize: 2
                    value: Config.bar.taskMinWidth
                    valueScale: Theme.u
                    suffix: " px ↓"
                    onMoved: v => {
                        Config.bar.taskMinWidth = v;
                        if (Config.bar.taskMaxWidth < v)
                            Config.bar.taskMaxWidth = v;
                    }
                }
                PxSlider {
                    width: parent.width
                    from: 30
                    to: 200
                    stepSize: 2
                    value: Config.bar.taskMaxWidth
                    valueScale: Theme.u
                    suffix: " px ↑"
                    onMoved: v => {
                        Config.bar.taskMaxWidth = v;
                        if (Config.bar.taskMinWidth > v)
                            Config.bar.taskMinWidth = v;
                    }
                }
            }
        }
        SettingRow {
            label: I18n.t("Воркспейсы на панели", "Workspaces on the bar")
            hint: I18n.t("сердечки, иконки открытых приложений или всё вместе", "hearts, icons of open apps, or both")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Сердечки", "Hearts"),
                        "value": "hearts",
                        "icon": "heart"
                    },
                    {
                        "label": I18n.t("Иконки", "Icons"),
                        "value": "icons",
                        "icon": "window"
                    },
                    {
                        "label": I18n.t("Оба", "Both"),
                        "value": "both"
                    }
                ]
                currentValue: Config.bar.workspaceStyle
                onActivated: v => Config.bar.workspaceStyle = v
            }
        }
        SettingRow {
            visible: Config.bar.workspaceStyle !== "hearts"
            label: I18n.t("Иконок на воркспейс", "Icons per workspace")
            PxSpin {
                from: 1
                to: 6
                value: Config.bar.workspaceIcons
                onMoved: v => Config.bar.workspaceIcons = v
            }
        }
        SettingRow {
            label: I18n.t("Мониторы", "Monitors")
            hint: I18n.t("ничего не выбрано = на всех", "No selection = all displays")
            Flow {
                width: parent.width
                spacing: Theme.u * 6
                Repeater {
                    model: Quickshell.screens
                    PxCheck {
                        required property var modelData
                        text: modelData.name
                        checked: (Config.bar.screens || []).includes(modelData.name)
                        onToggled: c => {
                            const l = (Config.bar.screens || []).filter(s => s !== modelData.name);
                            if (c)
                                l.push(modelData.name);
                            Config.bar.screens = l;
                        }
                    }
                }
            }
        }
    }

    PxGroup {
        title: I18n.t("Логотип angelOS", "angelOS logo")

        advanced: true
        icon: "heart"
        width: parent.width
        // one choice, as pictures with their names (issue #15: buttons and pictures disagreed)
        SettingRow {
            label: I18n.t("Вариант", "Variant")
            Flow {
                width: parent.width
                spacing: Theme.u * 6
                Repeater {
                    model: [
                        {
                            "value": "classic",
                            "label": "Classic 95"
                        },
                        {
                            "value": "angel",
                            "label": "Angel +"
                        }
                    ]
                    PxButton {
                        id: logoCard
                        required property var modelData
                        width: Math.max(preview.implicitWidth, caption.implicitWidth) + Theme.u * 12
                        height: Theme.u * 34
                        checked: Config.bar.logoStyle === modelData.value
                        onClicked: Config.bar.logoStyle = modelData.value
                        AngelLogo {
                            id: preview
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: Theme.u * 5
                            variant: logoCard.modelData.value
                        }
                        PxText {
                            id: caption
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: Theme.u * 4
                            text: (logoCard.checked ? "♡ " : "") + logoCard.modelData.label
                            kind: "tiny"
                            font.bold: logoCard.checked
                        }
                    }
                }
            }
        }
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            text: I18n.t("Classic 95 — Liberation Sans; Angel + — Pixeloid Sans. Цвета следуют текущей теме.", "Classic 95 uses Liberation Sans; Angel + uses Pixeloid Sans. Both follow the current theme.")
        }
    }

    PxGroup {
        title: I18n.t("Раскладка", "Layout")

        advanced: true
        icon: "layers"
        width: parent.width
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            text: I18n.t("Перетаскивай элементы между частями панели. «Окна» растягиваются на свободное место слева (или по содержимому — настройка ниже), «Лирика» лучше всего смотрится в центре. Виджеты новых плагинов сами появляются справа.", "Drag widgets between sections. Windows use the free space on the left (or only what they need — below); lyrics fit best in the center. New plugin widgets appear on the right.")
            dim: true
        }
        BarLayoutEditor {
            width: parent.width
        }
        SettingRow {
            label: I18n.t("Ширина «Окон»", "“Windows” width")
            hint: Config.bar.tasksWidth === "compact" ? I18n.t("по кнопкам открытых окон — то, что после «Окон», встаёт сразу за ними", "As wide as the open windows' buttons: whatever comes after “Windows” sits right next to them") : I18n.t("занимает всё свободное место слева", "Takes all the free room on the left")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Растягивать", "Fill"),
                        "value": "fill"
                    },
                    {
                        "label": I18n.t("По содержимому", "Compact"),
                        "value": "compact"
                    }
                ]
                currentValue: Config.bar.tasksWidth || "fill"
                onActivated: v => Config.bar.tasksWidth = v
            }
        }
        PxButton {
            text: I18n.t("Как было", "Reset")
            icon: "refresh"
            onClicked: BarLayout.reset()
        }
    }

    PxGroup {
        title: I18n.t("Иконки", "Icons")

        advanced: true
        icon: "palette"
        width: parent.width
        SettingRow {
            label: I18n.t("Цвет иконок в трее", "Tray icon colors")
            hint: I18n.t("перекрасить под тему, чтобы не было радуги", "Use the current theme for a consistent tray")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Как есть", "Original"),
                        "value": "off"
                    },
                    {
                        "label": I18n.t("Моно", "Monochrome"),
                        "value": "mono"
                    },
                    {
                        "label": I18n.t("Акцент", "Accent"),
                        "value": "accent"
                    }
                ]
                currentValue: Config.bar.trayTint
                onActivated: v => Config.bar.trayTint = v
            }
        }
        SettingRow {
            label: I18n.t("Плотность трея", "Tray density")
            hint: ({
                    "compact": I18n.t("6 в ряд, мелкие иконки впритык", "6 per row, small icons close together"),
                    "normal": I18n.t("5 в ряд, как было", "5 per row, as before"),
                    "airy": I18n.t("4 в ряд, иконки крупнее и с отступами", "4 per row, bigger icons with room around them"),
                    "spacious": I18n.t("3 в ряд, крупно и просторно — легко попасть мышкой", "3 per row, big and roomy — easy to hit")
                })[Config.bar.trayDensity] || ""
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Плотно", "Compact"),
                        "value": "compact"
                    },
                    {
                        "label": I18n.t("Обычно", "Normal"),
                        "value": "normal"
                    },
                    {
                        "label": I18n.t("Свободно", "Airy"),
                        "value": "airy"
                    },
                    {
                        "label": I18n.t("Просторно", "Spacious"),
                        "value": "spacious"
                    }
                ]
                currentValue: Config.bar.trayDensity || "normal"
                onActivated: v => Config.bar.trayDensity = v
            }
        }
        SettingRow {
            label: I18n.t("Красить и кнопки окон", "Tint window icons")
            hint: I18n.t("активное окно остаётся в своих цветах", "The focused window keeps its original colors")
            PxToggle {
                checked: Config.bar.tintTasks
                onToggled: c => Config.bar.tintTasks = c
            }
        }
    }

    PxGroup {
        title: I18n.t("Содержимое", "Contents")

        advanced: true
        icon: "layers"
        width: parent.width
        SettingRow {
            label: I18n.t("Кнопки окон", "Window buttons")
            PxToggle {
                checked: Config.bar.showWindows
                onToggled: c => Config.bar.showWindows = c
            }
        }
        SettingRow {
            label: I18n.t("Окна со всех воркспейсов", "Windows from all workspaces")
            PxToggle {
                checked: Config.bar.allWindows
                onToggled: c => Config.bar.allWindows = c
            }
        }
        SettingRow {
            label: I18n.t("Мини-плеер", "Mini player")
            PxToggle {
                checked: Config.bar.showMedia
                onToggled: c => Config.bar.showMedia = c
            }
        }
        SettingRow {
            label: I18n.t("Секунды в часах", "Show seconds")
            PxToggle {
                checked: Config.bar.showSeconds
                onToggled: c => Config.bar.showSeconds = c
            }
        }
        SettingRow {
            label: I18n.t("Компактно на вертикальных", "Compact on portrait displays")
            hint: I18n.t("узкие экраны: без плеера, окна иконками", "Narrow screens: compact player and window icons")
            PxToggle {
                checked: Config.bar.compactOnVertical
                onToggled: c => Config.bar.compactOnVertical = c
            }
        }
    }
}
