import QtQuick
import qs.config

Item {
    id: root

    property string text: ""
    property string icon: ""
    property bool checked: false
    property bool checkable: false
    property bool accent: false
    property bool danger: false
    property bool flat: false
    property bool compact: false
    property int iconPixel: Theme.u
    property bool middleButton: false      // also report middle clicks (task buttons close windows with them)
    property string kind: "body"
    property alias hovered: mouse.containsMouse
    property alias pressed: mouse.pressed
    readonly property bool down: mouse.pressed || checked
    signal clicked
    signal rightClicked
    signal middleClicked

    implicitWidth: row.implicitWidth + (compact ? Theme.u * 6 : Theme.pad * 2 + Theme.u * 2)
    implicitHeight: Math.max(row.implicitHeight + Theme.u * (compact ? 5 : 8), Theme.u * (compact ? 11 : 15))
    opacity: enabled ? 1 : 0.45

    PxBox {
        anchors.fill: parent
        visible: !root.flat || mouse.containsMouse || root.checked
        sunken: root.down
        color: root.accent ? (mouse.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent) : root.danger && mouse.containsMouse ? Theme.danger : root.checked ? Theme.mix(Theme.face, Theme.accent, Theme.dark ? 0.4 : 0.3) : mouse.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.12) : Theme.face
    }

    Row {
        id: row
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.down ? Theme.u : 0
        anchors.verticalCenterOffset: root.down ? Theme.u : 0
        spacing: Theme.u * 3

        PxIcon {
            visible: root.icon !== ""
            name: root.icon || "heart"
            pixel: root.iconPixel
            anchors.verticalCenter: parent.verticalCenter
            ink: root.accent ? Theme.selectText : (Theme.dark ? Theme.text : Theme.edge)
        }
        PxText {
            visible: root.text !== ""
            text: root.text
            kind: root.kind
            anchors.verticalCenter: parent.verticalCenter
            color: root.accent ? Theme.selectText : root.danger && mouse.containsMouse ? "#ffffff" : Theme.text
            font.bold: root.checked
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton | Qt.RightButton | (root.middleButton ? Qt.MiddleButton : 0)
        cursorShape: Qt.PointingHandCursor
        onClicked: e => {
            if (e.button === Qt.RightButton) {
                root.rightClicked();
                return;
            }
            if (e.button === Qt.MiddleButton) {
                root.middleClicked();
                return;
            }
            if (root.checkable)
                root.checked = !root.checked;
            root.clicked();
        }
    }
}
