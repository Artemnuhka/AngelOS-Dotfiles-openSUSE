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
                onActivated: v => Config.bar.startStyle = v
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
                onActivated: v => Config.bar.style = v
            }
        }
        SettingRow {
            label: I18n.t("Подписывать окна", "Show window titles")
            hint: I18n.t("выключи, чтобы оставить на панели только иконки", "Turn off to show application icons only")
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
        icon: "heart"
        width: parent.width
        SettingRow {
            label: I18n.t("Вариант", "Variant")
            PxSegmented {
                model: [
                    {label: "Classic 95", value: "classic"},
                    {label: "Angel +", value: "angel"}
                ]
                currentValue: Config.bar.logoStyle
                onActivated: v => Config.bar.logoStyle = v
            }
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 8
            Repeater {
                model: ["classic", "angel"]
                PxButton {
                    required property string modelData
                    width: preview.implicitWidth + Theme.u * 12
                    height: Theme.u * 23
                    checked: Config.bar.logoStyle === modelData
                    onClicked: Config.bar.logoStyle = modelData
                    AngelLogo {
                        id: preview
                        anchors.centerIn: parent
                        variant: parent.modelData
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
        icon: "layers"
        width: parent.width
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            text: I18n.t("Перетаскивай элементы между частями панели. «Окна» растягиваются на свободное место слева, «Лирика» лучше всего смотрится в центре. Виджеты новых плагинов сами появляются справа.", "Drag widgets between sections. Windows use the free space on the left; lyrics fit best in the center. New plugin widgets appear on the right.")
            dim: true
        }
        BarLayoutEditor {
            width: parent.width
        }
        PxButton {
            text: I18n.t("Как было", "Reset")
            icon: "refresh"
            onClicked: BarLayout.reset()
        }
    }

    PxGroup {
        title: I18n.t("Иконки", "Icons")
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
