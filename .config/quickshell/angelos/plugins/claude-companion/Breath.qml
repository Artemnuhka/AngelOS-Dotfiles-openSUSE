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

    // Pixel-stepped breathing: ~10 frames a second, and only distinct values
    // reach the scene graph. A 60 fps NumberAnimation here kept every bar and
    // the full-screen desktop layer repainting and cost several % CPU idle.
    property real _phase: 0
    Timer {
        interval: 100
        repeat: true
        running: root.visible && root.state !== "none" && root.state !== "idle" && root.speed > 0
        onRunningChanged: if (!running)
            root.glow = 1
        onTriggered: {
            // one full breath ≈ 4 s (≈ 2 s when it waits for you); depth stays gentle
            const period = (root.urgent ? 2000 : 4000) / Math.max(0.1, root.speed);
            root._phase = (root._phase + interval / period) % 1;
            const depth = root.urgent ? 0.55 : root.busy ? 0.3 : 0.18;
            const v = 1 - depth * (0.5 - 0.5 * Math.cos(root._phase * 2 * Math.PI));
            const stepped = Math.round(v * 16) / 16;
            if (stepped !== root.glow)
                root.glow = stepped;
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
