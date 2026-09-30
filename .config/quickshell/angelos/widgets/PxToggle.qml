import QtQuick
import qs.config
import qs.services

// Pixel switch with a heart knob.
Item {
    id: root

    property bool checked: false
    property string text: ""
    signal toggled(bool checked)

    implicitWidth: track.width + (label.visible ? label.implicitWidth + Theme.u * 5 : 0)
    implicitHeight: Math.max(track.height, label.implicitHeight)
    opacity: enabled ? 1 : 0.45

    PxBox {
        id: track
        width: Theme.u * 26
        height: Theme.u * 13
        anchors.verticalCenter: parent.verticalCenter
        sunken: true
        color: root.checked ? Theme.mix(Theme.sunken, Theme.accent, 0.55) : Theme.sunken

        PxBox {
            id: knob
            width: parent.height
            height: width
            y: 0
            x: root.checked ? parent.width - width : 0
            color: root.checked ? Theme.accent : Theme.face
            Behavior on x {
                NumberAnimation {
                    duration: Theme.fast
                    easing.type: Easing.OutBack
                }
            }
            PxIcon {
                anchors.centerIn: parent
                name: "heartSmall"
                pixel: Math.max(1, Theme.u - 1)
                fill: root.checked ? "#ffffff" : Theme.lo
                ink: root.checked ? Theme.edge : Theme.textDim
            }
        }
    }

    PxText {
        id: label
        visible: root.text !== ""
        text: root.text
        anchors.left: track.right
        anchors.leftMargin: Theme.u * 5
        anchors.verticalCenter: parent.verticalCenter
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            // the owner's binding updates `checked` (see PxSegmented): assign only if it did not
            const next = !root.checked;
            root.toggled(next);
            if (root.checked !== next)
                root.checked = next;
            Sounds.play("toggle");
        }
    }
}
