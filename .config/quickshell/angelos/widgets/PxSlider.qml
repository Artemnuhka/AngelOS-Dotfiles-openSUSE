import QtQuick
import qs.config

// Pixel slider: sunken track, pink fill, heart thumb.
Item {
    id: root

    property real from: 0
    property real to: 1
    property real value: 0
    property real stepSize: 0
    property bool live: true
    property string suffix: ""
    property int decimals: 0
    property bool showValue: true
    property real valueScale: 1
    readonly property bool dragging: mouse.pressed
    signal moved(real value)
    signal released(real value)

    implicitWidth: Theme.u * 110
    implicitHeight: Theme.u * 12

    readonly property real frac: to === from ? 0 : Math.max(0, Math.min(1, (value - from) / (to - from)))
    property real _drag: frac

    function valueAt(x) {
        let f = Math.max(0, Math.min(1, (x - thumb.width / 2) / (track.width - thumb.width)));
        let v = from + f * (to - from);
        if (stepSize > 0)
            v = Math.round((v - from) / stepSize) * stepSize + from;
        return Math.max(Math.min(from, to), Math.min(Math.max(from, to), v));
    }

    PxBox {
        id: track
        anchors.left: parent.left
        anchors.right: valueLabel.visible ? valueLabel.left : parent.right
        anchors.rightMargin: valueLabel.visible ? Theme.u * 4 : 0
        anchors.verticalCenter: parent.verticalCenter
        height: Theme.u * 6
        sunken: true
        color: Theme.sunken

        Rectangle {
            x: 0
            y: 0
            height: parent.height - track.inset * 2
            width: Math.max(0, thumb.x + thumb.width / 2 - track.inset)
            color: Theme.accent
        }
    }

    PxBox {
        id: thumb
        width: Theme.u * 9
        height: Theme.u * 12
        anchors.verticalCenter: track.verticalCenter
        x: track.x + root.frac * (track.width - width)
        color: mouse.containsMouse || mouse.pressed ? Theme.faceAlt : Theme.face
        PxIcon {
            anchors.centerIn: parent
            name: "heartSmall"
            pixel: Math.max(1, Theme.u - 1)
        }
    }

    PxText {
        id: valueLabel
        visible: root.showValue
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.u * 26
        horizontalAlignment: Text.AlignRight
        text: (root.value * root.valueScale).toFixed(root.decimals) + root.suffix
    }

    MouseArea {
        id: mouse
        anchors.fill: track
        anchors.topMargin: -Theme.u * 4
        anchors.bottomMargin: -Theme.u * 4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        function apply(mx) {
            const v = root.valueAt(mx);
            if (root.live)
                root.value = v;
            root.moved(v);
        }
        onPressed: m => apply(m.x)
        onPositionChanged: m => {
            if (pressed)
                apply(m.x);
        }
        onReleased: m => root.released(root.valueAt(m.x))
        onWheel: w => {
            const step = root.stepSize > 0 ? root.stepSize : (root.to - root.from) / 50;
            const v = Math.max(Math.min(root.from, root.to), Math.min(Math.max(root.from, root.to), root.value + (w.angleDelta.y > 0 ? step : -step)));
            root.value = v;
            root.moved(v);
            root.released(v);
        }
    }
}
