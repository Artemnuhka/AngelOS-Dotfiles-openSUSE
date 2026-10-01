import QtQuick
import qs.config
import qs.services
import qs.widgets

// Terminal bubble with a ">_" face; bobs gently (stepped) while Codex works.
Item {
    id: root

    property int pixel: Theme.u
    property string state: CodexState.state
    // the demon rules: two little horns on the bubble (on the bar too); on the desktop
    // in hell (Theme.hell) obsidian and embers
    property bool horns: Angel.demon || Theme.hell
    property bool hellLook: Theme.hell
    readonly property var rows: horns ? hornRows : haloRows
    readonly property var hornRows: [
        ".r.......r.",
        ".rr#####rr.",
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
    readonly property var haloRows: [
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
        ink: root.hellLook ? Theme.hellGold : (Theme.dark ? Theme.text : Theme.edge)
        fill2: root.hellLook ? CodexState.hellStateColor(root.state, Theme) : root.state === "none" ? Theme.textDim : CodexState.stateColor(root.state, Theme)
        light: root.hellLook ? Theme.hellFaceAlt : Theme.dark ? Theme.face : "#ffffff"
        bad: root.hellLook ? Theme.hellEmber : "#e0203a"
        opacity: root.state === "none" ? 0.7 : 1
    }
}
