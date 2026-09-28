pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

PxPage {
    heading: "System"

    Component.onCompleted: {
        SystemInfo.refresh();
        DesktopActions.refresh();
    }

    PxGroup {
        title: I18n.t("Диспетчер задач", "Task Manager")
        icon: "chip"
        width: parent.width
        SettingRow {
            label: I18n.t("Системный монитор", "System monitor")
            hint: I18n.t("Запускается также через ПКМ по свободному месту панели", "Also available by right-clicking empty taskbar space")
            PxCombo {
                model: [{value: "auto", label: I18n.t("Автоматически", "Automatic")}].concat(DesktopActions.monitors, [{value: "custom", label: I18n.t("Другая программа…", "Custom application…")}])
                currentValue: Config.system.monitor
                onActivated: v => Config.system.monitor = v
            }
        }
        SettingRow {
            visible: Config.system.monitor === "custom"
            label: I18n.t("Программа", "Executable")
            hint: I18n.t("Имя программы или полный путь, без аргументов", "Program name or full path, without arguments")
            PxField {
                width: Theme.u * 100
                text: Config.system.monitorProgram
                placeholder: "missioncenter"
                onEdited: Config.system.monitorProgram = text
            }
        }
        SettingRow {
            visible: Config.system.monitor === "custom"
            label: I18n.t("Запускать в терминале", "Run in terminal")
            PxToggle {
                checked: Config.system.monitorInTerminal
                onToggled: c => Config.system.monitorInTerminal = c
            }
        }
        PxButton {
            text: I18n.t("Открыть диспетчер задач", "Open Task Manager")
            icon: "chip"
            enabled: DesktopActions.available
            onClicked: DesktopActions.launchMonitor()
        }
    }

    PxGroup {
        title: I18n.t("Этот компьютер", "This computer")
        icon: "chip"
        width: parent.width

        Row {
            spacing: Theme.u * 8
            width: parent.width
            PxIcon {
                name: "ghost"
                pixel: Theme.u * 5
            }
            Grid {
                columns: 2
                columnSpacing: Theme.u * 8
                rowSpacing: Theme.u * 2
                Repeater {
                    model: [[I18n.t("Система", "System"), "os"], [I18n.t("Ядро", "Kernel"), "kernel"], [I18n.t("Хост", "Host"), "host"], [I18n.t("Процессор", "CPU"), "cpu"], [I18n.t("Видеокарта", "GPU"), "gpu"], [I18n.t("Память", "Memory"), "mem"], ["Работает", "uptime"], ["niri", "niri"], ["Quickshell", "qs"], [I18n.t("Шелл", "Shell"), "shell"]].reduce((a, r) => a.concat([
                            {
                                "t": r[0],
                                "dim": true
                            },
                            {
                                "t": SystemInfo.info[r[1]] || "—",
                                "dim": false
                            }
                        ]), [])
                    PxText {
                        required property var modelData
                        text: modelData.t
                        dim: modelData.dim
                    }
                }
            }
        }
    }

    PxGroup {
        visible: SystemInfo.powerProfile !== ""
        title: I18n.t("Питание", "Power")
        icon: "power"
        width: parent.width
        SettingRow {
            label: I18n.t("Профиль", "Profile")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Экономия", "Power saver"),
                        "value": "power-saver"
                    },
                    {
                        "label": I18n.t("Баланс", "Balanced"),
                        "value": "balanced"
                    },
                    {
                        "label": I18n.t("Мощность", "Performance"),
                        "value": "performance"
                    }
                ]
                currentValue: SystemInfo.powerProfile
                onActivated: v => SystemInfo.setPowerProfile(v)
            }
        }
    }

    PxGroup {
        title: I18n.t("Блокировка", "Lock screen")
        icon: "lock"
        width: parent.width
        SettingRow {
            label: I18n.t("Блокировать после простоя", "Lock when idle")
            hint: I18n.t("0 = никогда", "0 = never")
            PxSpin {
                from: 0
                to: 120
                stepSize: 5
                value: Config.lock.idleMinutes
                suffix: I18n.t(" мин", " min")
                onMoved: v => Config.lock.idleMinutes = v
            }
        }
        SettingRow {
            label: I18n.t("Пикселизовать обои на локе", "Pixelate lock screen wallpaper")
            PxToggle {
                checked: Config.lock.pixelate
                onToggled: c => Config.lock.pixelate = c
            }
        }
        SettingRow {
            label: I18n.t("Терминал", "Terminal")
            PxField {
                width: Theme.u * 80
                text: Config.system.terminal
                onEdited: Config.system.terminal = text
            }
        }
        SettingRow {
            label: I18n.t("Файловый менеджер", "File manager")
            PxField {
                width: Theme.u * 80
                text: Config.system.fileManager
                onEdited: Config.system.fileManager = text
            }
        }
    }

    PxGroup {
        title: "angelOS"
        icon: "heart"
        width: parent.width
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            text: I18n.t("angelOS — пиксельная оболочка на Quickshell для niri. Конфиг: ", "angelOS is a pixel shell built with Quickshell for niri. Config: ") + Quickshell.shellDir + I18n.t(", настройки: ", ", settings: ") + Config.dir
            dim: true
        }
        Row {
            spacing: Theme.u * 4
            PxButton {
                text: I18n.t("Перезапустить оболочку", "Restart shell")
                icon: "refresh"
                onClicked: Quickshell.reload(true)
            }
            PxButton {
                text: I18n.t("Перечитать niri", "Reload niri")
                icon: "refresh"
                onClicked: Niri.action("LoadConfigFile", {})
            }
            PxButton {
                text: I18n.t("Папка настроек", "Settings folder")
                icon: "folder"
                onClicked: Shell.openPath(Config.dir)
            }
            PxButton {
                text: I18n.t("Бэкапы", "Backups")
                icon: "package"
                onClicked: Shell.openPath(Config.stateDir + "/backups")
            }
        }
    }
}
