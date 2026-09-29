import QtQuick
import qs.config
import qs.widgets

// Terminal bubble with a ">_" face; bobs gently (stepped) while Codex works.
Item {
    id: root

    property int pixel: Theme.u
    property string state: CodexState.state
    readonly property var rows: [
        "...#####...",
        "..#wwwww#..",
        ".#wxxxxxw#.",
        "#wxx#xxxxw#",
        "#wxxx#xxxw#",
        "#wxx#x###w#",
        "#wxxxxxxxw#",
        ".#wwwwwww#.",
        "..#######..",
        "...#...#..."
    ]
    property int bob: 0

    implicitWidth: face.width
    implicitHeight: face.height + pixel

    Timer {
        interval: 250
        repeat: true
        running: root.visible && root.state === "working"
        onTriggered: root.bob = root.bob ? 0 : 1
        onRunningChanged: if (!running)
            root.bob = 0
    }
    PxIcon {
        id: face
        y: root.bob * root.pixel
        bitmap: root.rows
        pixel: root.pixel
        fill2: root.state === "none" ? Theme.textDim : CodexState.stateColor(root.state, Theme)
        light: Theme.dark ? Theme.face : "#ffffff"
        opacity: root.state === "none" ? 0.7 : 1
    }
}
