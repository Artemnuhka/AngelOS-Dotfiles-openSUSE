import QtQuick
import qs.config
import qs.widgets

// A small window for previews: bevelled frame, gradient title with ×, text lines.
Item {
    id: root

    property bool active: true
    property bool closeHot: false            // the × is being clicked
    readonly property int s: Math.max(1, Math.round(Theme.u / 2))
    readonly property real titleH: Math.max(Theme.u * 6, height * 0.16)
    readonly property point closePoint: Qt.point(width - titleH * 0.75, titleH * 0.6)

    Rectangle {
        anchors.fill: parent
        color: Theme.edge
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: root.s
        color: Theme.face
        border.width: root.s
        border.color: Theme.hi
    }
    Rectangle {
        id: bar
        x: root.s * 2
        y: root.s * 2
        width: parent.width - root.s * 4
        height: root.titleH
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: root.active ? Theme.title1 : Theme.faceAlt
            }
            GradientStop {
                position: 1
                color: root.active ? Theme.title2 : Theme.faceAlt
            }
        }
        Rectangle {
            x: parent.width - width - root.s * 2
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height - root.s * 4
            height: width
            color: root.closeHot ? Theme.danger : Theme.face
            border.width: root.s
            border.color: Theme.edge
            PxIcon {
                anchors.centerIn: parent
                name: "close"
                pixel: 1
                ink: root.closeHot ? "#ffffff" : Theme.text
            }
        }
        Rectangle {
            x: root.s * 3
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.35
            height: Math.max(1, parent.height * 0.3)
            color: Qt.alpha("#ffffff", 0.75)
        }
    }
    Column {
        x: root.s * 5
        y: bar.y + bar.height + root.s * 4
        spacing: root.s * 3
        Repeater {
            model: [0.7, 0.5, 0.62, 0.4]
            Rectangle {
                required property real modelData
                width: (root.width - root.s * 10) * modelData
                height: Math.max(1, root.s * 2)
                color: Theme.mix(Theme.face, Theme.text, 0.35)
                visible: y + height < root.height - bar.height - root.s * 8
            }
        }
    }
}
