import QtQuick
import qs.config
import qs.widgets
import "."

// Sidebar block: state and plan limits at a glance.
Column {
    id: root

    property var plugin
    spacing: Theme.u * 2

    Row {
        spacing: Theme.u * 3
        Breath {
            plugin: root.plugin
            anchors.verticalCenter: parent.verticalCenter
        }
        PxText {
            anchors.verticalCenter: parent.verticalCenter
            text: "Claude · " + Pulse.word
            color: Pulse.colorFor(Pulse.state, Theme)
        }
    }
    Limits {
        width: root.width
        compact: true
    }
}
