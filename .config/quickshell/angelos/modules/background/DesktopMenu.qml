pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Right-click desktop menu. Items come from plugins (manifest "menu" or "menuComponent").
PopupWindow {
    id: root

    required property var parentWindow
    property real px: 0
    property real py: 0

    function openAt(x, y) {
        px = x;
        py = y;
        visible = false;
        anchor.rect.x = x;
        anchor.rect.y = y;
        visible = true;
    }
    function close() {
        visible = false;
    }

    anchor.window: parentWindow
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide
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
        width: Math.max(Theme.u * 140, ...col.children.map(child => child.implicitWidth || 0)) + inset * 2 + side.width
        height: col.implicitHeight + inset * 2
        color: Qt.alpha(Theme.menuSurface, Theme.panelAlpha)
        shadow: Config.appearance.shadows
        focus: true
        Keys.onEscapePressed: root.close()

        // win98 start-menu style side banner
        Rectangle {
            id: side
            x: 0
            y: 0
            width: Theme.u * 13
            height: parent.height - frame.inset * 2
            color: Theme.menuHeader
            PxText {
                anchors.centerIn: parent
                rotation: -90
                text: "angelOS ♡"
                kind: "title"
                color: Theme.text
                style: Text.Normal
                styleColor: Qt.alpha(Theme.edge, 0.5)
            }
        }

        Column {
            id: col
            x: side.width
            width: parent.width - frame.inset * 2 - side.width

            Repeater {
                model: [
                    {key: "HOME", label: I18n.t("Открыть домашнюю папку", "Open Home")},
                    {key: "DOWNLOAD", label: I18n.t("Открыть Загрузки", "Open Downloads")},
                    {key: "DOCUMENTS", label: I18n.t("Открыть Документы", "Open Documents")},
                    {key: "PICTURES", label: I18n.t("Открыть Изображения", "Open Pictures")},
                    {key: "MUSIC", label: I18n.t("Открыть Музыку", "Open Music")},
                    {key: "VIDEOS", label: I18n.t("Открыть Видео", "Open Videos")}
                ]
                PxMenuItem {
                    required property var modelData
                    text: modelData.label
                    icon: "folder"
                    onTriggered: {
                        root.close();
                        DesktopActions.openDirectory(modelData.key);
                    }
                }
            }
            PxMenuItem {
                text: I18n.t("Новая временная заметка", "New temporary text file")
                icon: "document"
                onTriggered: {
                    root.close();
                    DesktopActions.newText();
                }
            }
            PxMenuItem { separator: true }

            Repeater {
                model: Plugins.menuEntries
                PxMenuItem {
                    required property var modelData
                    text: I18n.label(modelData.label || "?")
                    icon: modelData.icon || "heart"
                    hint: modelData.hint || ""
                    separator: !!modelData.separator
                    onTriggered: {
                        root.close();
                        Plugins.run(modelData);
                    }
                }
            }

            Repeater {
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
                separator: true
            }
            PxMenuItem {
                text: I18n.t("Настройки angelOS", "AngelOS settings")
                icon: "gear"
                onTriggered: {
                    root.close();
                    Shell.openSettings();
                }
            }
        }
    }
}
