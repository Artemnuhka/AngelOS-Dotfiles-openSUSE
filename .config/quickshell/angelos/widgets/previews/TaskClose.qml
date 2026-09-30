import QtQuick
import qs.config
import qs.widgets

// Closing a window from its taskbar button.
//   variant  menu | close | none         — right-click (Settings → Window behavior)
//            middle-on | middle-off      — middle click closes
//            hover-on | hover-off        — × on hover
Scene {
    id: root

    readonly property bool hover: variant.startsWith("hover")
    readonly property bool middle: variant.startsWith("middle")
    readonly property bool closes: variant === "menu" || variant === "close" || variant === "middle-on" || variant === "hover-on"
    // when the window goes away
    readonly property real closeAt: variant === "menu" ? 0.72 : 0.42
    readonly property bool gone: closes && t >= closeAt
    readonly property real fade: closes ? 1 - seg(closeAt, closeAt + 0.08) : 1

    MiniBar {
        id: bar
        y: root.height - height
        width: root.width
        height: Math.round(root.height * 0.17)
        count: 3
        hot: root.t > 0.28 && root.t < root.closeAt ? 1 : -1
        hidden: root.gone ? 1 : -1
        withX: root.variant === "hover-on" && root.t > 0.26 && !root.gone ? 1 : -1
        xHot: root.t > 0.34
    }

    MiniWindow {
        x: root.width * 0.2
        y: root.height * 0.1
        width: root.width * 0.46
        height: root.height * 0.55
        opacity: root.fade
        scale: 0.9 + 0.1 * root.fade
        visible: opacity > 0
    }

    // the right-click menu of the button
    Rectangle {
        id: menu
        visible: root.variant === "menu" && root.t > 0.34 && root.t < 0.72
        x: bar.buttonPoint(1).x - width * 0.3
        y: bar.y - height - Theme.u
        width: Theme.u * 52
        height: col.height + Theme.u * 2
        color: Theme.menuSurface
        border.width: Math.max(1, Theme.u / 2)
        border.color: Theme.edge
        Column {
            id: col
            x: Theme.u
            y: Theme.u
            width: parent.width - Theme.u * 2
            Repeater {
                model: [I18n.t("Во весь экран", "Fullscreen"), I18n.t("Плавающее", "Floating"), I18n.t("На стол 2", "To desk 2"), I18n.t("Закрыть", "Close")]
                Rectangle {
                    required property string modelData
                    required property int index
                    width: col.width
                    height: Theme.u * 8
                    color: index === 3 && root.t > 0.56 ? Theme.select : "transparent"
                    PxText {
                        x: Theme.u * 2
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.modelData
                        kind: "tiny"
                        color: index === 3 && root.t > 0.56 ? Theme.selectText : Theme.text
                    }
                }
            }
        }
    }

    // "nothing happens"
    PxText {
        visible: !root.closes && root.t > 0.42
        x: bar.buttonPoint(1).x - width / 2
        y: bar.y - height - Theme.u * 3
        text: "…"
        font.bold: true
        color: Theme.textDim
    }

    MiniCursor {
        readonly property point start: Qt.point(root.width * 0.72, root.height * 0.3)
        readonly property point atButton: bar.buttonPoint(1)
        readonly property point atX: bar.xPoint(1)
        readonly property point atClose: Qt.point(menu.x + menu.width * 0.4, menu.y + Theme.u * 29)
        readonly property point p: {
            if (root.variant === "menu" && root.t > 0.4)
                return root.mixp(atButton, atClose, root.ease(root.seg(0.42, 0.56)));
            if (root.hover && root.t > 0.26)
                return root.mixp(atButton, atX, root.ease(root.seg(0.26, 0.33)));
            return root.mixp(start, atButton, root.ease(root.seg(0.05, 0.26)));
        }
        x: p.x
        y: p.y
        click: {
            if (root.variant === "menu")
                return root.t > 0.28 && root.t < 0.36 ? "right" : root.t > 0.64 && root.t < 0.72 ? "left" : "";
            if (root.middle)
                return root.t > 0.3 && root.t < 0.42 ? "middle" : "";
            if (root.hover)
                return root.variant === "hover-on" && root.t > 0.35 && root.t < 0.42 ? "left" : "";
            return root.t > 0.3 && root.t < 0.42 ? "right" : "";
        }
    }
}
