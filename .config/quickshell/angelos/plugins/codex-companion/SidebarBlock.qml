import QtQuick
import qs.config
import qs.widgets
import "."

// Sidebar block: Codex state and limits at a glance.
Column {
    id: root

    property var plugin
    spacing: Theme.u * 2

    Row {
        spacing: Theme.u * 3
        Mascot {
            anchors.verticalCenter: parent.verticalCenter
        }
        PxText {
            anchors.verticalCenter: parent.verticalCenter
            text: "Codex · " + (CodexState.words[CodexState.state] || "")
            color: CodexState.stateColor(CodexState.state, Theme)
        }
    }
    Limits {
        width: root.width
        compact: true
    }
}
