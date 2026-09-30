pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Pixel-styled DBus menu with drill-down submenus.
PopupWindow {
    id: root

    required property Item anchorItem
    property bool above: true
    property var handle: null
    property var stack: []
    readonly property var current: stack.length ? stack[stack.length - 1] : handle

    function toggle() {
        stack = [];
        if (handle)
            PopupManager.toggle(root);
    }

    anchor.item: anchorItem
    anchor.rect.x: 0
    anchor.rect.y: above ? -Theme.u * 2 : anchorItem.height + Theme.u * 2
    anchor.rect.width: anchorItem.width
    anchor.rect.height: 1
    anchor.edges: above ? Edges.Top : Edges.Bottom
    anchor.gravity: above ? Edges.Top : Edges.Bottom
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

    QsMenuOpener {
        id: opener
        menu: root.current
    }

    PxBox {
        id: frame
        width: Math.max(Theme.u * 90, col.implicitWidth + inset * 2)
        height: col.implicitHeight + inset * 2
        color: Theme.panel
        shadow: Config.appearance.shadows

        Column {
            id: col
            width: parent.width - frame.inset * 2

            PxMenuItem {
                visible: root.stack.length > 0
                text: I18n.t("◂ назад", "◂ Back")
                icon: "arrowUp"
                onTriggered: root.stack = root.stack.slice(0, -1)
            }
            Repeater {
                model: opener.children
                PxMenuItem {
                    required property var modelData
                    separator: modelData.isSeparator
                    text: (modelData.text || "").replace(/_(?!_)/, "")
                    enabled: modelData.enabled
                    submenu: modelData.hasChildren
                    checkable: modelData.buttonType !== QsMenuButtonType.None
                    checked: modelData.checkState === Qt.Checked
                    icon: ""
                    onTriggered: {
                        if (modelData.hasChildren) {
                            root.stack = root.stack.concat([modelData]);
                        } else {
                            modelData.triggered();
                            root.visible = false;
                        }
                    }
                }
            }
        }
    }

    RightClickGuard {}
}
