pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config

// A run of bar widgets; "tasks" may stretch to fill the section.
RowLayout {
    id: root

    required property var ids
    required property var bar
    property bool fillTasks: false
    property real lyricsMax: Theme.u * 150

    spacing: Theme.u * 3

    Repeater {
        model: root.ids
        BarItem {
            required property string modelData
            wid: modelData
            bar: root.bar
            fillTasks: root.fillTasks
            lyricsMax: root.lyricsMax
        }
    }
}
