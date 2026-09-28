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
    signal triggered

    width: parent ? parent.width : implicitWidth
    implicitWidth: separator ? Theme.u * 20 : row.implicitWidth + hintText.implicitWidth + Theme.u * 24
    implicitHeight: separator ? Theme.u * 5 : Theme.sizeBody + Theme.u * 8
    opacity: enabled ? 1 : 0.45

    Rectangle {
        visible: root.separator
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
        visible: !root.separator
        anchors.fill: parent
        color: mouse.containsMouse && root.enabled ? Theme.select : "transparent"
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
                ink: mouse.containsMouse ? Theme.selectText : (Theme.dark ? Theme.text : Theme.edge)
            }
        }
        PxText {
            text: root.text
            color: mouse.containsMouse && root.enabled ? Theme.selectText : Theme.text
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    PxText {
        id: hintText
        visible: !root.separator && (root.hint !== "" || root.submenu)
        text: root.submenu ? "▸" : root.hint
        dim: !mouse.containsMouse
        color: mouse.containsMouse ? Theme.selectText : Theme.textDim
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
