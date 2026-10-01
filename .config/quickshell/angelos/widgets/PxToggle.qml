import QtQuick
import qs.config
import qs.services

// Pixel switch with a heart knob.
Item {
    id: root

    property bool checked: false
    property string text: ""
    signal toggled(bool checked)

    // Long labels wrap instead of running off a narrow page (the grimoire's right
    // page): inside a box marked `fixedWidth` (SettingRow's control slot, PxGroup's
    // column) the switch is no wider than what is left of that box.
    readonly property real room: {
        let dx = 0;
        for (let p = root; p && p.parent; p = p.parent) {
            dx += p.x;
            if (p.parent.fixedWidth === true)
                return p.parent.width - dx;
        }
        return Infinity;
    }

    implicitWidth: track.width + (label.visible ? label.implicitWidth + Theme.u * 5 : 0)
    implicitHeight: Math.max(track.height, label.implicitHeight)
    width: Math.max(track.width, Math.min(implicitWidth, room))
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
        width: Math.min(implicitWidth, Math.max(0, root.width - track.width - Theme.u * 5))
        wrapMode: Text.Wrap
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
