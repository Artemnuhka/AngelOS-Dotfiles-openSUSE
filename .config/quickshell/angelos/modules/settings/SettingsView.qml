pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Settings content (frame, sidebar, pages). Hosted by SettingsWindow.
Item {
    id: win

    Component.onCompleted: Shell.settingsView = win
    Component.onDestruction: if (Shell.settingsView === win)
        Shell.settingsView = null
    function diagnostics() {
        return {
            page: Shell.settingsPage,
            source: String(page.source),
            status: page.status,
            plugin: page.item && page.item.loadedPlugin !== undefined ? page.item.loadedPlugin : ""
        };
    }
    property var hostWindow: null
    readonly property alias frame: frame
    readonly property var groups: [
        {
            "title": I18n.t("Вид", "Appearance"),
            "pages": [
                {
                    "id": "appearance",
                    "label": I18n.t("Внешний вид", "Appearance"),
                    "icon": "palette"
                },
                {
                    "id": "fonts",
                    "label": I18n.t("Шрифты", "Fonts"),
                    "icon": "document"
                },
                {
                    "id": "wallpaper",
                    "label": I18n.t("Обои", "Wallpaper"),
                    "icon": "image"
                },
                {
                    "id": "capture",
                    "label": I18n.t("Скриншоты", "Screenshots"),
                    "icon": "image"
                },
                {
                    "id": "cursor",
                    "label": I18n.t("Курсор", "Cursor"),
                    "icon": "cursor"
                },
                {
                    "id": "widgets",
                    "label": I18n.t("Виджеты", "Widgets"),
                    "icon": "layers"
                },
                {
                    "id": "bar",
                    "label": I18n.t("Панель", "Bar"),
                    "icon": "window"
                },
                {
                    "id": "workspaces",
                    "label": I18n.t("Воркспейсы", "Workspaces"),
                    "icon": "layers"
                },
                {
                    "id": "lyrics",
                    "label": I18n.t("Лирика", "Lyrics"),
                    "icon": "mic"
                }
            ]
        },
        {
            "title": I18n.t("Устройства", "Devices"),
            "pages": [
                {
                    "id": "monitor",
                    "label": I18n.t("Монитор", "Monitor"),
                    "icon": "monitor"
                },
                {
                    "id": "keyboard",
                    "label": I18n.t("Клавиатура и мышь", "Keyboard and mouse"),
                    "icon": "keyboard"
                },
                {
                    "id": "windows",
                    "label": I18n.t("Поведение окон", "Window behavior"),
                    "icon": "window"
                },
                {
                    "id": "sound",
                    "label": I18n.t("Звук", "Sound"),
                    "icon": "speaker"
                },
                {
                    "id": "network",
                    "label": I18n.t("Сеть и Wi-Fi", "Network and Wi-Fi"),
                    "icon": "wifi"
                },
                {
                    "id": "bluetooth",
                    "label": "Bluetooth",
                    "icon": "bluetooth"
                },
                {
                    "id": "gamepad",
                    "label": I18n.t("Геймпад", "Gamepad"),
                    "icon": "gamepad"
                }
            ]
        },
        {
            "title": "System",
            "pages": [
                {
                    "id": "defaults",
                    "label": I18n.t("По умолчанию", "Default apps"),
                    "icon": "star"
                },
                {
                    "id": "notifications",
                    "label": I18n.t("Уведомления", "Notifications"),
                    "icon": "bell"
                },
                {
                    "id": "plugins",
                    "label": I18n.t("Плагины", "Plugins"),
                    "icon": "plug"
                },
                {
                    "id": "studio",
                    "label": I18n.t("Мастер плагинов", "Plugin Studio"),
                    "icon": "sparkle",
                    "developer": true
                },
                {
                    "id": "dotfiles",
                    "label": "Dotfiles",
                    "icon": "package",
                    "owner": true
                },
                {
                    "id": "lock",
                    "label": I18n.t("Блокировка и заставка", "Lock and idle"),
                    "icon": "lock"
                },
                {
                    "id": "updates",
                    "label": I18n.t("Обновления", "Updates"),
                    "icon": "download"
                },
                {
                    "id": "system",
                    "label": "System",
                    "icon": "chip"
                }
            ]
        },
        {
            "title": I18n.t("Плагины", "Plugins"),
            "pages": Plugins.settingsPages.map(p => ({
                        "id": "plugin:" + p.id,
                        "label": I18n.label(p.name),
                        "icon": p.icon || "plug"
                    }))
        }
    ]
    // owner-only pages vanish in the public version
    readonly property var visibleGroups: groups.map(g => ({
                "title": g.title,
                "pages": g.pages.filter(p => (!p.owner || Owner.enabled) && (!p.developer || Config.developer.enabled))
            })).filter(g => g.pages.length > 0)
    readonly property var allPages: visibleGroups.reduce((a, g) => a.concat(g.pages), [])
    readonly property var currentPage: allPages.find(p => p.id === Shell.settingsPage) || allPages[0]

    PxWindow {
        id: frame
        anchors.fill: parent
        anchors.rightMargin: Config.appearance.shadows ? Theme.u * 2 : 0
        anchors.bottomMargin: Config.appearance.shadows ? Theme.u * 2 : 0
        title: "angelOS · " + (win.currentPage ? win.currentPage.label : I18n.t("Настройки", "Settings"))
        icon: win.currentPage ? win.currentPage.icon : "gear"
        minimizable: false
        maximizable: true
        onCloseClicked: Shell.settingsOpen = false
        onMaximizeClicked: if (win.hostWindow)
            win.hostWindow.maximized = !win.hostWindow.maximized
        onTitlePressed: if (win.hostWindow)
            win.hostWindow.startSystemMove()
        bodyPadding: Theme.u * 4

        // sidebar
        PxBox {
            id: sidebar
            width: Theme.u * 95
            height: parent.height
            sunken: true
            color: Qt.alpha(Theme.sunken, 0.55)

            PxScroll {
                anchors.fill: parent
                anchors.margins: Theme.u * 2
                contentHeight: side.implicitHeight

                Column {
                    id: side
                    width: parent.width
                    spacing: Theme.u

                    Repeater {
                        model: win.visibleGroups
                        Column {
                            id: grp
                            required property var modelData
                            width: side.width
                            spacing: Theme.u
                            PxText {
                                text: "✧ " + grp.modelData.title
                                kind: "tiny"
                                dim: true
                                topPadding: Theme.u * 4
                                leftPadding: Theme.u * 3
                                bottomPadding: Theme.u
                            }
                            Repeater {
                                model: grp.modelData.pages
                                Rectangle {
                                    id: entry
                                    required property var modelData
                                    readonly property bool sel: Shell.settingsPage === modelData.id
                                    width: grp.width
                                    height: Theme.u * 15
                                    color: sel ? Theme.select : em.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.15) : "transparent"
                                    Row {
                                        anchors.left: parent.left
                                        anchors.leftMargin: Theme.u * 4
                                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                        spacing: Theme.u * 4
                                        PxIcon {
                                            name: entry.modelData.icon
                                            anchors.verticalCenter: parent.verticalCenter
                                            ink: entry.sel ? Theme.selectText : (Theme.dark ? Theme.text : Theme.edge)
                                        }
                                        PxText {
                                            width: entry.width - Theme.u * 24
                                            elide: Text.ElideRight
                                            text: entry.modelData.label
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: entry.sel ? Theme.selectText : Theme.text
                                            font.bold: entry.sel
                                        }
                                    }
                                    MouseArea {
                                        id: em
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Shell.settingsPage = entry.modelData.id
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // page
        PxBox {
            id: pageBox
            anchors.left: sidebar.right
            anchors.leftMargin: Theme.u * 4
            anchors.right: parent.right
            height: parent.height
            sunken: true
            color: Qt.alpha(Theme.face, Config.appearance.blur ? 0.55 : 1)

            Loader {
                id: page
                anchors.fill: parent
                anchors.margins: Theme.u * 3
                active: win.hostWindow ? win.hostWindow.visible : true
                source: {
                    const id = Shell.settingsPage;
                    if (id.startsWith("plugin:"))
                        return "pages/PluginSettingsPage.qml";
                    if (id === "dotfiles")
                        return Owner.enabled ? "file://" + Owner.dir + "/DotfilesPage.qml" : "pages/AppearancePage.qml";
                    const name = id.charAt(0).toUpperCase() + id.slice(1);
                    return "pages/" + (win.allPages.find(p => p.id === id) ? name : "Appearance") + "Page.qml";
                }
            }
        }

        // resize grip
        PxIcon {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: -Theme.u * 3
            name: "sparkle"
            fill: Theme.textDim
            MouseArea {
                anchors.fill: parent
                anchors.margins: -Theme.u * 3
                cursorShape: Qt.SizeFDiagCursor
                onPressed: if (win.hostWindow)
                    win.hostWindow.startSystemResize(Edges.Bottom | Edges.Right)
            }
        }
    }
}
