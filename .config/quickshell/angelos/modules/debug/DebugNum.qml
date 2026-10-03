import QtQuick
import qs.config
import qs.widgets

// "label  − value +" for one number of the save. `value` stays bound to the save (nothing
// here assigns it): a change made elsewhere — a throw, a scene — shows at once.
Row {
    id: root

    property string label: ""
    property real value: 0
    property real from: 0
    property real to: 999
    property real step: 1
    property int labelWidth: Theme.u * 46
    property string note: ""                 // a word after the value (her step, a circle)
    signal moved(real value)

    spacing: Theme.u * 2
    function set(v) {
        root.moved(Math.max(from, Math.min(to, v)));
    }

    PxText {
        width: root.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: root.label
    }
    PxButton {
        compact: true
        icon: "minus"
        enabled: root.value > root.from
        onClicked: root.set(root.value - root.step)
    }
    PxBox {
        width: Theme.u * 22
        height: Theme.sizeBody + Theme.u * 6
        anchors.verticalCenter: parent.verticalCenter
        sunken: true
        color: Theme.sunken
        PxText {
            anchors.centerIn: parent
            text: String(Math.round(root.value * 100) / 100)
        }
        MouseArea {
            anchors.fill: parent
            onWheel: w => root.set(root.value + (w.angleDelta.y > 0 ? root.step : -root.step))
        }
    }
    PxButton {
        compact: true
        icon: "plus"
        enabled: root.value < root.to
        onClicked: root.set(root.value + root.step)
    }
    PxText {
        visible: root.note !== ""
        anchors.verticalCenter: parent.verticalCenter
        dim: true
        kind: "tiny"
        text: root.note
    }
}
