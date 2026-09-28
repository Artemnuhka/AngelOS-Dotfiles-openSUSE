import QtQuick
import qs.config

// Win98 group box: etched frame with the title cut into the top edge.
Item {
    id: root

    property string title: ""
    property string icon: ""
    property int spacing: Theme.u * 5
    default property alias content: col.data

    implicitWidth: col.implicitWidth + Theme.pad * 2
    implicitHeight: col.implicitHeight + head.height + Theme.pad * 2

    readonly property int lineY: head.height / 2
    readonly property int b: Math.max(1, Theme.u / 2)

    // etched frame: lo line + hi line offset by one
    Repeater {
        model: 2
        Item {
            required property int index
            readonly property color c: index === 0 ? Theme.lo : Theme.hi
            readonly property int o: index * root.b
            x: o
            y: root.lineY + o
            width: root.width - root.b
            height: root.height - root.lineY - root.b
            Rectangle { x: 0; y: 0; width: Theme.u * 4; height: root.b; color: parent.c }
            Rectangle { x: head.x + head.width + Theme.u * 2 - parent.o; y: 0; width: Math.max(0, parent.width - x); height: root.b; color: parent.c }
            Rectangle { x: 0; y: 0; width: root.b; height: parent.height; color: parent.c }
            Rectangle { x: parent.width - root.b; y: 0; width: root.b; height: parent.height; color: parent.c }
            Rectangle { x: 0; y: parent.height - root.b; width: parent.width; height: root.b; color: parent.c }
        }
    }

    Row {
        id: head
        x: Theme.u * 6
        spacing: Theme.u * 3
        leftPadding: Theme.u * 2
        rightPadding: Theme.u * 2
        PxIcon {
            visible: root.icon !== ""
            name: root.icon || "heart"
            anchors.verticalCenter: parent.verticalCenter
        }
        PxText {
            text: root.title
            kind: "title"
            color: Theme.dark ? Theme.accent : Theme.edge
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Column {
        id: col
        x: Theme.pad
        y: head.height + Theme.u * 4
        width: root.width - Theme.pad * 2
        spacing: root.spacing
    }
}
