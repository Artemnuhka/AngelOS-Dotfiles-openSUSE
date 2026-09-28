pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Win98-like start menu.
PopupWindow {
    id: root

    required property Item anchorItem
    property bool above: true
    property string title: "angelOS"
    property string panelId: "start"
    readonly property string outputName: anchorItem && anchorItem.QsWindow.window && anchorItem.QsWindow.window.screen ? anchorItem.QsWindow.window.screen.name : ""
    Component.onCompleted: PopupManager.registerPopup(root)
    Component.onDestruction: PopupManager.unregisterPopup(root)

    function toggle() {
        PopupManager.toggle(root);
    }
    function run(fn) {
        visible = false;
        fn();
    }

    anchor.item: anchorItem
    anchor.rect.x: 0
    anchor.rect.y: above ? -Theme.u * 2 : anchorItem.height + Theme.u * 2
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: above ? Edges.Top | Edges.Left : Edges.Bottom | Edges.Left
    anchor.gravity: above ? Edges.Top | Edges.Right : Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
    grabFocus: true
    color: "transparent"
    implicitWidth: frame.width + Theme.u * 3
    implicitHeight: frame.height + Theme.u * 3
    onVisibleChanged: {
        if (visible) {
            if (PopupManager.active && PopupManager.active !== root)
                PopupManager.close(PopupManager.active);
            PopupManager.active = root;
        } else if (PopupManager.active === root)
            PopupManager.active = null;
    }
    visible: false

    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: frame
    }

    PxBox {
        id: frame
        width: Theme.u * 160
        height: brand.height + Theme.u * 4 + col.implicitHeight + inset * 2
        color: Qt.alpha(Theme.menuSurface, Theme.panelAlpha)
        edgeColor: Theme.menuBorder
        flat: true
        shadow: Config.appearance.shadows
        focus: true
        Keys.onEscapePressed: root.visible = false

        Rectangle {
            id: brand
            width: parent.width
            height: Theme.u * 27
            color: Theme.menuHeader
            AngelLogo {
                anchors.centerIn: parent
            }
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: Theme.u
                color: Theme.menuBorder
            }
        }

        Column {
            id: col
            y: brand.height + Theme.u * 2
            width: parent.width

            PxMenuItem {
                text: I18n.t("Программы…", "Applications…")
                icon: "search"
                hint: "Mod+Space"
                onTriggered: root.run(() => Shell.launcherOpen = true)
            }
            PxMenuItem {
                text: I18n.t("Терминал", "Terminal")
                icon: "terminal"
                onTriggered: root.run(() => Shell.terminal())
            }
            PxMenuItem {
                text: I18n.t("Файлы", "Files")
                icon: "folder"
                onTriggered: root.run(() => Shell.exec([Config.system.fileManager || "xdg-open", Config.home]))
            }
            PxMenuItem {
                separator: true
            }
            PxMenuItem {
                text: I18n.t("Обои", "Wallpaper")
                icon: "image"
                onTriggered: root.run(() => Shell.openSettings("wallpaper"))
            }
            PxMenuItem {
                text: I18n.t("Настройки", "Settings")
                icon: "gear"
                onTriggered: root.run(() => Shell.openSettings())
            }
            PxMenuItem {
                text: I18n.t("Плагины", "Plugins")
                icon: "plug"
                onTriggered: root.run(() => Shell.openSettings("plugins"))
            }
            PxMenuItem {
                visible: Owner.enabled
                height: visible ? implicitHeight : 0
                text: "Dotfiles"
                icon: "package"
                onTriggered: root.run(() => Shell.openSettings("dotfiles"))
            }
            PxMenuItem {
                text: Theme.dark ? I18n.t("Светлая тема", "Light theme") : I18n.t("Тёмная тема", "Dark theme")
                icon: Theme.dark ? "sun" : "moon"
                onTriggered: root.run(() => Config.appearance.mode = Theme.dark ? "light" : "dark")
            }
            PxMenuItem {
                separator: true
            }
            PxMenuItem {
                text: I18n.t("Заблокировать", "Lock")
                icon: "lock"
                onTriggered: root.run(() => Shell.lock())
            }
            PxMenuItem {
                text: I18n.t("Выключение…", "Power…")
                icon: "power"
                onTriggered: root.run(() => Shell.sessionOpen = true)
            }
        }
    }
}
