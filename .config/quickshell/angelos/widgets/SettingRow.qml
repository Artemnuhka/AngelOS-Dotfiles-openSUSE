import QtQuick
import qs.config

// "label ........ control" row with an optional hint below the label.
Item {
    id: root

    property string label: ""
    property string hint: ""
    property int labelWidth: Math.min(Theme.u * 120, width * 0.45)
    default property alias control: slot.data

    width: parent ? parent.width : implicitWidth
    implicitHeight: Math.max(labels.implicitHeight, slot.childrenRect.height) + Theme.u * 2

    Column {
        id: labels
        width: root.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        PxText {
            width: parent.width
            text: root.label
            wrapMode: Text.Wrap
        }
        PxText {
            visible: root.hint !== ""
            width: parent.width
            text: root.hint
            kind: "tiny"
            dim: true
            wrapMode: Text.Wrap
        }
    }
    Item {
        id: slot
        anchors.left: labels.right
        anchors.leftMargin: Theme.u * 6
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: childrenRect.height
    }
}
