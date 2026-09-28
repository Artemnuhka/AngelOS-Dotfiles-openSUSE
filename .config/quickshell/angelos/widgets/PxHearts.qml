import QtQuick
import qs.config

// Meter made of hearts (value 0..1).
Row {
    id: root

    property real value: 0
    property int count: 10
    property int pixel: Theme.u
    property color fill: Theme.accent
    property string icon: "heart"

    spacing: pixel

    Repeater {
        model: root.count
        Item {
            id: cell
            required property int index
            readonly property real part: Math.max(0, Math.min(1, root.value * root.count - index))
            width: empty.width
            height: empty.height
            PxIcon {
                id: empty
                name: root.icon
                pixel: root.pixel
                hollow: true
            }
            Item {
                width: Math.round(parent.width * (cell.part >= 1 ? 1 : cell.part > 0 ? 0.5 : 0))
                height: parent.height
                clip: true
                PxIcon {
                    name: root.icon
                    pixel: root.pixel
                    fill: root.fill
                }
            }
        }
    }
}
