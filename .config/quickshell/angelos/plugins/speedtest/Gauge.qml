import QtQuick
import qs.config
import "."

// Pixel speedometer: blocks along a half circle, log-ish scale up to 1 Gbit/s.
Canvas {
    id: root

    property real value: 0           // Mbit/s
    property real maxValue: 1000
    readonly property real frac: Speed.running && (Speed.phase === "download" || Speed.phase === "upload" || Speed.phase === "ping") ? Speed.wobble : Math.min(1, Math.log10(1 + value) / Math.log10(1 + maxValue))
    property real shown: frac
    Behavior on shown {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }
    readonly property int b: Theme.u * 3        // block size
    property color on: Speed.phase === "upload" ? Theme.accent2 : Theme.accent
    property color off: Theme.dark ? Theme.hi : Theme.lo

    width: Theme.u * 110
    height: Theme.u * 60
    renderTarget: Canvas.Image
    antialiasing: false

    onShownChanged: requestPaint()
    onOnChanged: requestPaint()
    onOffChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const cx = width / 2, cy = height - b;
        const r1 = width / 2 - b, r0 = r1 - b * 4;
        // arc blocks
        for (let a = 0; a <= 180; a += 4) {
            const t = a / 180;
            const rad = Math.PI - t * Math.PI;
            for (let rr = r0; rr <= r1; rr += b) {
                const x = Math.round((cx + Math.cos(rad) * rr) / b) * b;
                const y = Math.round((cy - Math.sin(rad) * rr) / b) * b;
                ctx.fillStyle = t <= shown ? on : off;
                ctx.fillRect(x, y, b, b);
            }
        }
        // needle
        const rad = Math.PI - shown * Math.PI;
        ctx.fillStyle = Theme.dark ? Theme.text : Theme.edge;
        for (let rr = 0; rr < r0 - b; rr += b) {
            const x = Math.round((cx + Math.cos(rad) * rr) / b) * b;
            const y = Math.round((cy - Math.sin(rad) * rr) / b) * b;
            ctx.fillRect(x, y, b, b);
        }
        ctx.fillStyle = Theme.accent3;
        ctx.fillRect(Math.round(cx / b) * b - b, cy - b, b * 2, b * 2);
    }
}
