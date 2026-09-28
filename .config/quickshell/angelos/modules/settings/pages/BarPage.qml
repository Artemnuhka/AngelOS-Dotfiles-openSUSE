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
