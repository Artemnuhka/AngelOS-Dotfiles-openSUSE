pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Right-click desktop menu, laid out like Windows 11: a row of quick actions on top,
// then Вид ▸ / Создать ▸ / Открыть ▸, screen & personalization shortcuts, and
// "Показать больше ▸" for plugin entries.
PopupWindow {
    id: root

    required property var parentWindow
    readonly property string screenName: parentWindow && parentWindow.screen ? parentWindow.screen.name : ""
    property real px: 0
    property real py: 0
    property string hoverHint: ""

    function openAt(x, y) {
        px = x;
        py = y;
        sub.visible = false;
        visible = false;
        anchor.rect.x = x;
        anchor.rect.y = y;
        visible = true;
    }
    function close() {
        sub.visible = false;
        visible = false;
    }
    function run(fn) {
        close();
        fn();
    }

    // ---- flyout contents ----
    readonly property var viewItems: DesktopWidgets.types.map(t => ({
                "label": t.label,
                "icon": t.icon,
                "checkable": true,
                "checked": DesktopWidgets.has(t.type, root.screenName),
                "keepOpen": true,
                "run": () => DesktopWidgets.toggle(t.type, root.screenName)
            })).concat([
            {
                "separator": true
            },
            {
                "label": I18n.t("Редактировать виджеты", "Edit widgets"),
                "icon": "gear",
                "checkable": true,
                "checked": DesktopWidgets.editMode,
                "run": () => DesktopWidgets.editMode = !DesktopWidgets.editMode
            },
            {
                "label": I18n.t("Прилипать к сетке", "Snap to grid"),
                "checkable": true,
                "checked": Config.desktop.snap,
                "keepOpen": true,
                "run": () => Config.desktop.snap = !Config.desktop.snap
            }
        ])
    readonly property var newItems: [
        {
            "label": I18n.t("Текстовую заметку", "Text note"),
            "icon": "terminal",
            "run": () => DesktopActions.newText()
        },
        {
            "label": I18n.t("Скриншот области", "Region screenshot"),
            "icon": "image",
            "run": () => Capture.screenshot()
        },
        {
            "label": I18n.t("Запись области экрана", "Region recording"),
            "icon": "play",
            "enabled": true,
            "run": () => Capture.record()
        },
        {
            "label": I18n.t("Видео для DaVinci (mediafix)…", "Video for DaVinci (mediafix)…"),
            "icon": "music",
            "run": () => NautilusSetup.mediafix([])
        }
    ]
    readonly property var openItems: [
        {
            "key": "HOME",
            "label": I18n.t("Домашняя папка", "Home")
        },
        {
            "key": "DESKTOP",
            "label": I18n.t("Рабочий стол", "Desktop")
        },
        {
            "key": "DOWNLOAD",
            "label": I18n.t("Загрузки", "Downloads")
        },
        {
            "key": "DOCUMENTS",
            "label": I18n.t("Документы", "Documents")
        },
        {
            "key": "PICTURES",
            "label": I18n.t("Изображения", "Pictures")
        },
        {
            "key": "MUSIC",
            "label": I18n.t("Музыка", "Music")
        },
        {
            "key": "VIDEOS",
            "label": I18n.t("Видео", "Videos")
        }
    ].map(d => ({
                "label": d.label,
                "icon": "folder",
                "run": () => DesktopActions.openDirectory(d.key)
            }))
    readonly property var moreItems: Plugins.menuEntries.map(e => ({
                "label": I18n.label(e.label || "?"),
                "icon": e.icon || "heart",
                "hint": e.hint || "",
                "separator": !!e.separator,
                "run": () => Plugins.run(e)
            }))

    anchor.window: parentWindow
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide
    grabFocus: !Shell.demo
    color: "transparent"
    implicitWidth: frame.width + Theme.u * 3
    implicitHeight: frame.height + Theme.u * 3
    onVisibleChanged: {
        if (visible) {
            if (PopupManager.active && PopupManager.active !== root)
                PopupManager.close(PopupManager.active);
            PopupManager.active = root;
        } else if (PopupManager.active === root) {
            PopupManager.active = null;
        }
    }
    visible: false

    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: frame
    }

    DesktopSubmenu {
        id: sub
        parentMenu: root
        onDone: root.close()
    }
    // hover opens flyouts after a short beat, like Windows
    Timer {
        id: hoverTimer
        property Item item: null
        property var list: []
        interval: 160
        onTriggered: if (item && item.hovered)
            sub.openFor(item, list)
    }
    // scripting: open a flyout by name ("view" | "new" | "open" | "more")
    function openSub(name) {
        const m = {
            "view": [viewItem, viewItems],
            "new": [newItem, newItems],
            "open": [openItem, openItems],
            "more": [moreItem, moreItems]
        }[name];
        if (m)
            sub.openFor(m[0], m[1]);
    }
    function hoverSub(item, list) {
        if (sub.visible && sub.anchorItem === item)
            return;
        hoverTimer.item = item;
        hoverTimer.list = list;
        hoverTimer.restart();
    }

    PxBox {
        id: frame
        width: Math.max(Theme.u * 150, quick.implicitWidth + Theme.u * 8, ...col.children.map(c => c.implicitWidth || 0)) + inset * 2
        height: col.implicitHeight + inset * 2
        color: Qt.alpha(Theme.menuSurface, Theme.panelAlpha)
        shadow: Config.appearance.shadows
        focus: true
        Keys.onEscapePressed: root.close()

        Column {
            id: col
            width: parent.width - frame.inset * 2

            // quick actions row (Windows 11 puts cut/copy/paste here; we put the everyday stuff)
            Item {
                width: parent.width
                height: quick.height + Theme.u * 4
                Row {
                    id: quick
                    anchors.centerIn: parent
                    spacing: Theme.u * 2
                    Repeater {
                        model: [
                            {
                                "icon": "terminal",
                                "tip": I18n.t("Терминал", "Terminal"),
                                "run": () => Shell.terminal()
                            },
                            {
                                "icon": "folder",
                                "tip": I18n.t("Файлы", "Files"),
                                "run": () => DesktopActions.openDirectory("HOME")
                            },
                            {
                                "icon": "chip",
                                "tip": I18n.t("Системный монитор", "System monitor"),
                                "run": () => DesktopActions.launchMonitor()
                            },
                            {
                                "icon": "image",
                                "tip": I18n.t("Обои", "Wallpaper"),
                                "run": () => Shell.openSettings("wallpaper")
                            },
                            {
                                "icon": "gear",
                                "tip": I18n.t("Настройки", "Settings"),
                                "run": () => Shell.openSettings()
                            }
                        ]
                        PxButton {
                            required property var modelData
                            compact: true
                            flat: true
                            icon: modelData.icon
                            width: Theme.u * 17
                            height: Theme.u * 15
                            onHoveredChanged: root.hoverHint = hovered ? modelData.tip : ""
                            onClicked: root.run(modelData.run)
                        }
                    }
                }
            }
            PxText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: root.hoverHint || " "
                kind: "tiny"
                dim: true
            }
            PxMenuItem {
                separator: true
            }

            PxMenuItem {
                id: viewItem
                text: I18n.t("Вид", "View")
                icon: "layers"
                submenu: true
                onHoveredChanged: if (hovered)
                    root.hoverSub(viewItem, root.viewItems)
                onTriggered: sub.openFor(viewItem, root.viewItems)
            }
            PxMenuItem {
                id: newItem
                text: I18n.t("Создать", "New")
                icon: "plus"
                submenu: true
                onHoveredChanged: if (hovered)
                    root.hoverSub(newItem, root.newItems)
                onTriggered: sub.openFor(newItem, root.newItems)
            }
            PxMenuItem {
                id: openItem
                text: I18n.t("Открыть", "Open")
                icon: "folder"
                submenu: true
                onHoveredChanged: if (hovered)
                    root.hoverSub(openItem, root.openItems)
                onTriggered: sub.openFor(openItem, root.openItems)
            }
            PxMenuItem {
                separator: true
            }
            PxMenuItem {
                text: I18n.t("Обновить", "Refresh")
                icon: "refresh"
                onHoveredChanged: if (hovered)
                    sub.visible = false
                onTriggered: root.run(() => {
                    Wallpapers.scan();
                    Plugins.reload();
                })
            }
            PxMenuItem {
                text: I18n.t("Параметры экрана", "Display settings")
                icon: "monitor"
                onHoveredChanged: if (hovered)
                    sub.visible = false
                onTriggered: root.run(() => Shell.openSettings("monitor"))
            }
            PxMenuItem {
                text: I18n.t("Персонализация", "Personalize")
                icon: "palette"
                onHoveredChanged: if (hovered)
                    sub.visible = false
                onTriggered: root.run(() => Shell.openSettings("appearance"))
            }
            PxMenuItem {
                text: I18n.t("Открыть в терминале", "Open in Terminal")
                icon: "terminal"
                onHoveredChanged: if (hovered)
                    sub.visible = false
                onTriggered: root.run(() => Shell.terminal())
            }
            PxMenuItem {
                visible: DesktopActions.available
                height: visible ? implicitHeight : 0
                text: I18n.t("Системный монитор", "System monitor")
                icon: "chip"
                hint: DesktopActions.selectedMonitor ? DesktopActions.selectedMonitor.label : ""
                onHoveredChanged: if (hovered)
                    sub.visible = false
                onTriggered: root.run(() => DesktopActions.launchMonitor())
            }
            PxMenuItem {
                separator: true
            }
            PxMenuItem {
                id: moreItem
                visible: root.moreItems.length > 0 || Plugins.menuComponents.length > 0
                height: visible ? implicitHeight : 0
                text: I18n.t("Показать больше", "Show more options")
                icon: "sparkle"
                submenu: true
                onHoveredChanged: if (hovered)
                    root.hoverSub(moreItem, root.moreItems)
                onTriggered: sub.openFor(moreItem, root.moreItems)
            }
            Repeater {
                // QML menu components from plugins can't live in a flyout list; they stay inline
                model: Plugins.menuComponents
                Loader {
                    required property var modelData
                    width: col.width
                    Component.onCompleted: setSource(Plugins.url(modelData, modelData.menuComponent), {
                        "plugin": Plugins.context(modelData),
                        "menu": root
                    })
                }
            }
            PxMenuItem {
                text: I18n.t("Настройки angelOS", "angelOS settings")
                icon: "gear"
                onHoveredChanged: if (hovered)
                    sub.visible = false
                onTriggered: root.run(() => Shell.openSettings())
            }
        }
    }
}
