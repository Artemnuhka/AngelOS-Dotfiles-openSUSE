import QtQuick
import qs.config
import qs.widgets
import "."
import "Frames.js" as Frames

// Animated cat: idle below walk threshold, walks, then runs faster with load.
Item {
    id: root

    property var plugin
    property int pixel: Theme.u
    readonly property int walkAt: plugin ? plugin.get("walk", 15) : 15
    readonly property int runAt: Math.max(walkAt + 1, plugin ? plugin.get("run", 60) : 60)
    readonly property real cpu: Cpu.percent
    readonly property string pace: cpu < walkAt ? "idle" : cpu < runAt ? "walk" : "run"
    readonly property int frameMs: pace === "walk" ? 380 - (cpu - walkAt) / Math.max(1, runAt - walkAt) * 200 : 160 - (cpu - runAt) / Math.max(1, 100 - runAt) * 105
    readonly property color fur: plugin && plugin.get("colorMode", "theme") === "custom" ? plugin.get("color", "#e8a24c") : Theme.accent4
    property int frame: 0

    implicitWidth: sprite.width
    implicitHeight: sprite.height + pixel

    Timer {
        interval: Math.max(50, root.frameMs)
        running: root.pace !== "idle" && root.visible
        repeat: true
        onTriggered: root.frame = (root.frame + 1) % 5
    }
    Timer {
        // slow zzz blink while asleep
        interval: 700
        running: root.pace === "idle" && root.visible
        repeat: true
        onTriggered: root.frame = (root.frame + 1) % 2
    }

    PxIcon {
        id: sprite
        pixel: root.pixel
        bitmap: root.pace === "idle" ? Frames.sleep.map((r, i) => root.frame === 1 && i < 2 ? r.replace(/y/g, ".") : r) : Frames.run(root.frame)
        body: root.fur
        fill: Theme.accent
        fill3: Theme.accent2
        light: "#ffffff"
        y: root.pace !== "idle" && root.frame % 2 === 1 ? 0 : root.pixel
    }
}
