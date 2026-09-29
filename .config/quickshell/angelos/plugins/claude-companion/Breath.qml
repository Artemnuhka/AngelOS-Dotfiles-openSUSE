import QtQuick
import qs.config
import qs.widgets
import "."

// The mascot: face tinted by state, breathing slowly and softly (a bit quicker when it needs you).
Item {
    id: root

    property var plugin
    property int pixel: Theme.u
    property string state: Pulse.state
    readonly property real speed: plugin ? plugin.get("breath", 1.0) : 1.0
    readonly property bool urgent: state === "needs_attention" || state === "error"
    readonly property bool busy: state === "turn_start" || state === "text" || state === "tool_start"
    property real glow: 1

    implicitWidth: face.width
    implicitHeight: face.height

    SequentialAnimation on glow {
        loops: Animation.Infinite
        running: root.visible && root.state !== "none" && root.state !== "idle" && root.speed > 0
        // one full breath ≈ 4 s (≈ 2 s when it waits for you); depth stays gentle
        NumberAnimation {
            to: root.urgent ? 0.45 : root.busy ? 0.7 : 0.82
            duration: (root.urgent ? 1000 : 2000) / Math.max(0.1, root.speed)
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            to: 1
            duration: (root.urgent ? 1000 : 2000) / Math.max(0.1, root.speed)
            easing.type: Easing.InOutSine
        }
    }

    PxIcon {
        id: face
        name: "bot"
        pixel: root.pixel
        body: Pulse.colorFor(root.state, Theme)
        fill3: root.state === "none" ? Theme.textDim : Theme.accent3
        opacity: root.state === "none" ? 0.6 : root.glow
    }
}
