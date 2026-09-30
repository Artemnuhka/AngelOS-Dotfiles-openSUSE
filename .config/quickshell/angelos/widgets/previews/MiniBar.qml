import QtQuick
import qs.config
import qs.widgets

// Taskbar for previews: start button, window buttons; one can be hidden, hot,
// or show the hover ×.
Item {
    id: root

    property int count: 3
    property int hidden: -1                  // button index that is gone (its window closed)
    property int hot: -1                     // pressed / hovered button
    property int withX: -1                   // button showing the hover ×
    property bool xHot: false
    readonly property int s: Math.max(1, Math.round(Theme.u / 2))
    readonly property real bw: Math.min(Theme.u * 30, (width - height * 1.6) / Math.max(1, count) - s * 2)

    // centre of button i / of its ×, in scene coordinates
    function buttonPoint(i) {
        return Qt.point(x + height * 1.4 + i * (bw + s * 2) + bw / 2, y + height / 2);
    }
    function xPoint(i) {
        return Qt.point(x + height * 1.4 + i * (bw + s * 2) + bw - height * 0.35, y + height * 0.4);
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.face
        Rectangle {
            width: parent.width
            height: root.s
            color: Theme.hi
        }
    }
    Rectangle {
        x: root.s * 2
        y: root.s * 2
        width: root.height * 1.2
        height: root.height - root.s * 4
        color: Theme.accent
        border.width: root.s
        border.color: Theme.edge
        PxIcon {
            anchors.centerIn: parent
            name: "heart"
            pixel: 1
        }
    }
    Repeater {
        model: root.count
        Rectangle {
            required property int index
            visible: index !== root.hidden
            x: root.height * 1.4 + index * (root.bw + root.s * 2)
            y: root.s * 2
            width: root.bw
            height: root.height - root.s * 4
            color: index === root.hot ? Theme.mix(Theme.face, Theme.accent, 0.35) : Theme.faceAlt
            border.width: root.s
            border.color: index === root.hot ? Theme.edge : Theme.lo
            Rectangle {
                x: root.s * 3
                anchors.verticalCenter: parent.verticalCenter
                width: parent.height * 0.5
                height: width
                color: [Theme.accent, Theme.accent2, Theme.accent3][index % 3]
            }
            Rectangle {
                x: parent.height * 0.8
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * 0.45
                height: Math.max(1, root.s * 2)
                color: Theme.mix(Theme.face, Theme.text, 0.4)
            }
            Rectangle {
                visible: index === root.withX
                x: parent.width - width - root.s * 2
                y: root.s * 2
                width: root.height * 0.45
                height: width
                color: root.xHot ? Theme.danger : Theme.face
                border.width: root.s
                border.color: Theme.edge
                PxIcon {
                    anchors.centerIn: parent
                    name: "close"
                    pixel: 1
                    ink: root.xHot ? "#ffffff" : Theme.text
                }
            }
        }
    }
}
