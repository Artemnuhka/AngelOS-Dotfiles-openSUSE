import QtQuick
import qs.config

// Menu row: icon + label (+ optional hint / submenu arrow). separator: true draws a line.
Item {
    id: root

    property string text: ""
    property string icon: ""
    property string hint: ""
    property bool separator: false
    property bool submenu: false
    property bool checked: false
    property bool checkable: false
    property bool highlighted: false        // keyboard selection
    property string skin: ""                // "" | y2k (glossy pill highlight, rainbow lines)
    readonly property bool hovered: mouse.containsMouse
    readonly property bool lit: (mouse.containsMouse || highlighted) && enabled
    signal triggered

    width: parent ? parent.width : implicitWidth
    implicitWidth: separator ? Theme.u * 20 : row.implicitWidth + hintText.implicitWidth + Theme.u * 24
    implicitHeight: separator ? Theme.u * 5 : Theme.sizeBody + Theme.u * 8
    opacity: enabled ? 1 : 0.45

    // y2k: a rainbow line
    Rectangle {
        visible: root.separator && root.skin === "y2k"
        anchors.verticalCenter: parent.verticalCenter
        x: Theme.u * 4
        width: parent.width - Theme.u * 8
        height: Math.max(1, Theme.u / 2)
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: "transparent"
            }
            GradientStop {
                position: 0.2
                color: "#ff6fb0"
            }
            GradientStop {
                position: 0.5
                color: "#ffe066"
            }
            GradientStop {
                position: 0.8
                color: "#8fe3ff"
            }
            GradientStop {
                position: 1
                color: "transparent"
            }
        }
    }
    Rectangle {
        visible: root.separator && root.skin !== "y2k"
        anchors.verticalCenter: parent.verticalCenter
        x: Theme.u * 2
        width: parent.width - Theme.u * 4
        height: Math.max(1, Theme.u / 2)
        color: Theme.lo
        Rectangle {
            y: parent.height
            width: parent.width
            height: parent.height
            color: Theme.hi
        }
    }

    Rectangle {
        visible: !root.separator && root.skin !== "y2k"
        anchors.fill: parent
        color: root.lit ? Theme.select : "transparent"
    }
    // y2k: a glossy pill
    Rectangle {
        visible: !root.separator && root.skin === "y2k" && root.lit
        anchors.fill: parent
        anchors.leftMargin: Theme.u * 2
        anchors.rightMargin: Theme.u * 2
        anchors.topMargin: Theme.u / 2
        anchors.bottomMargin: Theme.u / 2
        radius: height / 2
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.mix(Theme.accent, "#ffffff", 0.45)
            }
            GradientStop {
                position: 0.5
                color: Theme.accent
            }
            GradientStop {
                position: 1
                color: Theme.mix(Theme.accent, Theme.edge, 0.2)
            }
        }
        border.width: Math.max(1, Theme.u / 2)
        border.color: Qt.alpha("#ffffff", 0.6)
        Rectangle {
            x: parent.radius / 2
            y: Math.max(1, Theme.u / 2)
            width: parent.width - parent.radius
            height: parent.height * 0.42
            radius: height / 2
            color: Qt.alpha("#ffffff", 0.35)
        }
    }

    Row {
        id: row
        visible: !root.separator
        anchors.left: parent.left
        anchors.leftMargin: Theme.u * 5
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.u * 4
        Item {
            width: Theme.u * 12
            height: Theme.u * 11
            anchors.verticalCenter: parent.verticalCenter
            PxIcon {
                anchors.centerIn: parent
                visible: root.icon !== "" || (root.checkable && root.checked)
                name: root.checkable ? (root.checked ? "check" : "heart") : (root.icon || "heart")
                ink: root.lit ? Theme.selectText : (Theme.dark ? Theme.text : Theme.edge)
            }
        }
        PxText {
            text: root.text
            color: root.lit ? Theme.selectText : Theme.text
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    PxText {
        id: hintText
        visible: !root.separator && (root.hint !== "" || root.submenu)
        text: root.submenu ? (root.skin === "y2k" ? "✦" : "▸") : root.hint
        dim: !root.lit
        color: root.lit ? Theme.selectText : Theme.textDim
        anchors.right: parent.right
        anchors.rightMargin: Theme.u * 5
        anchors.verticalCenter: parent.verticalCenter
    }

    MouseArea {
        id: mouse
        visible: !root.separator
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
