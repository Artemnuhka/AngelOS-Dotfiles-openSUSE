import QtQuick
import qs.config

Item {
    id: root

    property bool checked: false
    property string text: ""
    signal toggled(bool checked)

    implicitWidth: box.width + (text !== "" ? label.implicitWidth + Theme.u * 4 : 0)
    implicitHeight: Math.max(box.height, label.implicitHeight)
    opacity: enabled ? 1 : 0.45

    PxBox {
        id: box
        width: Theme.u * 10
        height: width
        sunken: true
        color: Theme.sunken
        anchors.verticalCenter: parent.verticalCenter
        PxIcon {
            anchors.centerIn: parent
            visible: root.checked
            name: "check"
            pixel: Math.max(1, Theme.u - 1)
            ink: Theme.accent
        }
    }
    PxText {
        id: label
        text: root.text
        anchors.left: box.right
        anchors.leftMargin: Theme.u * 4
        anchors.verticalCenter: parent.verticalCenter
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const next = !root.checked;
            root.toggled(next);
            if (root.checked !== next)
                root.checked = next;
        }
    }
}
