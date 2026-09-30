import QtQuick
import qs.config
import qs.widgets

// Bar styles: taskbar (Win98, bottom) | top (thin strip) | island (floating).
// The bar slides in; a window sits in the space it leaves.
Scene {
    id: root

    readonly property real k: ease(seg(0.1, 0.35))
    readonly property real barH: Math.round(height * 0.15)

    MiniWindow {
        x: root.width * 0.12
        y: root.variant === "top" ? root.barH * 0.7 + Theme.u * 3 : root.variant === "island" ? root.barH + Theme.u * 5 : Theme.u * 4
        width: root.width * 0.76
        height: root.height - y - (root.variant === "taskbar" ? root.barH : 0) - Theme.u * 4
    }

    MiniBar {
        visible: root.variant === "taskbar"
        width: root.width
        height: root.barH
        y: root.height - height * root.k
        count: 3
        hot: 0
    }
    // thin strip across the top: workspaces left, clock right
    Rectangle {
        visible: root.variant === "top"
        width: root.width
        height: root.barH * 0.7
        y: -height * (1 - root.k)
        color: Theme.face
        Row {
            x: Theme.u * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u * 2
            Repeater {
                model: 4
                PxIcon {
                    required property int index
                    name: "heart"
                    pixel: 1
                    opacity: index === 0 ? 1 : 0.4
                }
            }
        }
        PxText {
            x: parent.width - width - Theme.u * 3
            anchors.verticalCenter: parent.verticalCenter
            text: "12:00"
            kind: "tiny"
        }
    }
    // floating island in the middle of the top edge
    Rectangle {
        visible: root.variant === "island"
        width: root.width * 0.46
        height: root.barH * 0.8
        x: (root.width - width) / 2
        y: Theme.u * 2 - (height + Theme.u * 2) * (1 - root.k)
        color: Theme.face
        border.width: Math.max(1, Theme.u / 2)
        border.color: Theme.edge
        Row {
            anchors.centerIn: parent
            spacing: Theme.u * 3
            Repeater {
                model: 3
                PxIcon {
                    required property int index
                    name: ["heart", "music", "wifi"][index]
                    pixel: 1
                }
            }
            PxText {
                text: "12:00"
                kind: "tiny"
            }
        }
    }
}
