import QtQuick
import qs.config

// Pixel hearts drifting upwards with a little sway. Stepped at 12 fps: it looks
// pixel-y and does not keep a full-screen surface repainting at 60 fps.
Item {
    id: root

    property int count: 16
    property bool running: visible
    property real speed: 1
    property real minOpacity: 0.12
    property real maxOpacity: 0.4

    Repeater {
        id: rep
        model: root.count
        PxIcon {
            id: h
            required property int index
            property real vy: 0.5 + Math.random()
            property real phase: Math.random() * 6.28
            property real baseX: Math.random() * root.width
            name: index % 4 === 0 ? "sparkle" : index % 3 === 0 ? "heartSmall" : "heart"
            pixel: Math.max(1, Theme.u * (1 + index % 3))
            hollow: index % 2 === 0
            fill: index % 2 ? Theme.accent : Theme.accent2
            opacity: root.minOpacity + (index % 5) / 4 * (root.maxOpacity - root.minOpacity)
            x: baseX
            y: Math.random() * root.height
        }
    }
    Timer {
        interval: 83
        repeat: true
        running: root.running && root.width > 0
        onTriggered: {
            for (let i = 0; i < rep.count; i++) {
                const h = rep.itemAt(i);
                if (!h)
                    continue;
                h.y -= h.vy * Theme.u * 1.5 * root.speed;
                h.phase += 0.15;
                h.x = Math.round(h.baseX + Math.sin(h.phase) * Theme.u * 4);
                if (h.y < -h.height) {
                    h.y = root.height + Theme.u * 6;
                    h.baseX = Math.random() * root.width;
                }
            }
        }
    }
}
