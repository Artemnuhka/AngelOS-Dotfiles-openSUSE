import QtQuick
import qs.config
import qs.widgets
import "."

// Desktop "codex.exe": mascot, state and limits. The host draws the frame.
Item {
    id: root

    property var plugin
    property string screenName
    property var widget
    readonly property string mode: plugin ? plugin.get("orb", "always") : "always"   // always | active | off
    readonly property bool wantVisible: mode === "always" || (mode === "active" && CodexState.state !== "none")

    implicitWidth: Theme.u * 116
    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: Theme.u * 3
        Mascot {
            anchors.horizontalCenter: parent.horizontalCenter
            pixel: Theme.u * 3
        }
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: CodexState.words[CodexState.state] || ""
            kind: "title"
            color: CodexState.stateColor(CodexState.state, Theme)
        }
        Limits {
            width: parent.width
            compact: true
        }
    }
}
