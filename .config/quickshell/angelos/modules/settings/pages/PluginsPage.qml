pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

PxPage {
    id: page

    heading: I18n.t("Плагины", "Plugins")
    subtitle: I18n.t("Папка ~/.config/angelos/plugins/<id>/ с manifest.json. Плагин может добавить пункты в ПКМ-меню, виджет на панель или рабочий стол, фоновый сервис и страницу настроек. Документация: docs/PLUGINS.md", "Plugins live in ~/.config/angelos/plugins/<id>/ with manifest.json. They can add menus, bar or desktop widgets, services, and settings pages. See docs/PLUGINS.md.")

    property string createLog: ""
    Connections {
        target: Plugins
        function onCreated(id, ok) {
            page.createLog = ok ? I18n.t("создан ~/.config/angelos/plugins/", "Created ~/.config/angelos/plugins/") + id + " ♡" : I18n.t("не получилось (такая папка уже есть?)", "Could not create plugin. Does the folder already exist?");
        }
    }

    PxGroup {
        title: I18n.t("Установленные (", "Installed (") + Plugins.plugins.length + ")"
        icon: "plug"
        width: parent.width

        Repeater {
            model: Plugins.plugins
            PxBox {
                id: card
                required property var modelData
                readonly property bool on: Plugins.isEnabled(modelData)
                width: parent.width
                height: cardCol.implicitHeight + Theme.u * 10
                color: on ? Theme.mix(Theme.face, Theme.accent, 0.08) : Theme.face

                Row {
                    x: Theme.u * 4
                    y: Theme.u * 4
                    width: parent.width - Theme.u * 8
                    spacing: Theme.u * 5
                    PxIcon {
                        name: card.modelData.icon || "plug"
                        pixel: Theme.u * 2
                    }
                    Column {
                        id: cardCol
                        width: parent.width - Theme.u * 80
                        spacing: Theme.u
                        PxText {
                            text: I18n.label(card.modelData.name) + "  v" + (card.modelData.version || "0") + (card.modelData.bundled ? I18n.t("  · встроенный", "  · bundled") : "")
                            font.bold: true
                        }
                        PxText {
                            width: parent.width
                            text: I18n.label(card.modelData.description || "")
                            wrapMode: Text.Wrap
                            dim: true
                        }
                        PxText {
                            text: [card.modelData.menu ? "ПКМ-меню" : "", card.modelData.menuComponent ? I18n.t("меню (QML)", "menu (QML)") : "", card.modelData.barWidget ? I18n.t("панель", "bar") : "", card.modelData.desktopWidget ? I18n.t("рабочий стол", "desktop") : "", card.modelData.main ? I18n.t("сервис", "service") : "", card.modelData.settings ? I18n.t("настройки", "settings") : ""].filter(s => s).join(" · ") + (card.modelData.author ? "  —  " + card.modelData.author : "")
                            kind: "tiny"
                            dim: true
                        }
                    }
                    Column {
                        spacing: Theme.u * 3
                        PxToggle {
                            checked: card.on
                            onToggled: c => Plugins.setEnabled(card.modelData.id, c)
                        }
                        Row {
                            spacing: Theme.u * 2
                            PxButton {
                                visible: !!card.modelData.settings && card.on
                                compact: true
                                icon: "gear"
                                onClicked: Shell.settingsPage = "plugin:" + card.modelData.id
                            }
                            PxButton {
                                compact: true
                                icon: "folder"
                                onClicked: Shell.openPath(card.modelData.dir)
                            }
                        }
                    }
                }
            }
        }
    }

    PxGroup {
        title: I18n.t("Новый плагин", "New plugin")
        icon: "plus"
        width: parent.width
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            text: I18n.t("Создаст заготовку со всеми точками встраивания — открой папку и правь QML, оболочка перезагрузится сама.", "Creates a template with extension points. Open the folder and edit its QML files.")
            dim: true
        }
        Row {
            spacing: Theme.u * 3
            PxField {
                id: newId
                width: Theme.u * 70
                placeholder: I18n.t("id, напр. my-widget", "ID, e.g. my-widget")
            }
            PxField {
                id: newName
                width: Theme.u * 80
                placeholder: I18n.t("Название", "Name")
            }
            PxButton {
                text: I18n.t("Создать", "Create")
                icon: "plus"
                accent: true
                enabled: newId.text.trim() !== ""
                onClicked: Plugins.create(newId.text.trim(), newName.text.trim() || newId.text.trim())
            }
        }
        PxText {
            visible: page.createLog !== ""
            text: page.createLog
        }
        Row {
            spacing: Theme.u * 3
            PxButton {
                text: I18n.t("Перечитать плагины", "Reload plugins")
                icon: "refresh"
                onClicked: Plugins.reload()
            }
            PxButton {
                text: I18n.t("Открыть папку", "Open folder")
                icon: "folder"
                onClicked: Shell.openPath(Config.pluginsDir)
            }
        }
    }
}
