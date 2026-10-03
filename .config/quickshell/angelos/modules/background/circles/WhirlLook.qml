pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// The look of RadialMenu in the circle of lust: the entries are petals caught in the
// whirlwind — strung along a spiral that winds out from the pointer, each petal turned along
// the wind; opening, the wind turns them into place. The middle is the eye of the storm.
Item {
    id: look

    required property var menu
    readonly property real k: menu.k
    readonly property int n: menu.slots.length
    readonly property real slotSize: Math.round(Theme.u * 20 * k)
    readonly property real labelRoom: menu.labels ? Theme.sizeTiny + Theme.u * 3 : 0
    // the spiral r = a + b·θ: one turn further out is a petal and its name
    readonly property real a: Theme.u * 30 * k
    readonly property real b: (slotSize + labelRoom + Theme.u * 6 * k) / (2 * Math.PI)
    readonly property var pts: {
        const out = [];
        let t = 0;
        for (let i = 0; i < n; i++) {
            const r = a + b * t;
            out.push({
                "t": t,
                "r": r
            });
            t += (slotSize + Theme.u * (menu.labels ? 16 : 8) * k) / r;
        }
        return out;
    }
    readonly property real outer: n ? pts[n - 1].r : a
    readonly property real reach: outer + slotSize / 2 + labelRoom + Theme.u * 4
    readonly property Item blurItem: null
    // the wind's turn while it opens: everything comes in from further round the spiral
    readonly property real spin: (1 - menu.reveal) * -2.2
    function angleOf(i) {
        return -Math.PI / 2 + pts[i].t + spin;
    }
    function radiusOf(i) {
        return pts[i].r * (0.35 + 0.65 * menu.reveal);
    }
    function nav(e) {
        return menu.walk(e);
    }
    anchors.fill: parent

    // the wind: the spiral's path in dotted streaks, turning with the petals
    Canvas {
        id: wind
        readonly property real d: (look.reach + Theme.u * 6) * 2
        x: look.menu.cx - d / 2
        y: look.menu.cy - d / 2
        width: d
        height: d
        rotation: look.spin * 180 / Math.PI
        opacity: 0.8 * look.menu.reveal
        onWidthChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const u = Theme.u, c = width / 2;
            ctx.fillStyle = Theme.hellRim.toString();
            // a dot every few pixels along the spiral, from the eye to past the last petal
            const end = look.n ? look.pts[look.n - 1].t + 1.2 : 6;
            for (let t = 0; t < end; t += 0.05) {
                const r = look.a * 0.6 + look.b * t;
                if (Math.floor(t * 20) % 3 === 2)
                    continue;
                const x = c + Math.cos(-Math.PI / 2 + t - 0.35) * r, y = c + Math.sin(-Math.PI / 2 + t - 0.35) * r;
                ctx.fillRect(Math.round(x / u) * u, Math.round(y / u) * u, u, u);
            }
        }
    }

    CircleHub {
        menu: look.menu
        size: Math.round(look.slotSize * 1.1)
        color: Theme.hellBody
        nameGap: Theme.u * 2
    }

    // the petals
    Repeater {
        model: look.menu.slots
        CircleEntry {
            id: petal
            menu: look.menu
            readonly property real ang: look.angleOf(index)
            readonly property real r: look.radiusOf(index)
            readonly property real lit: Math.max(0, Math.min(1, look.menu.reveal * 1.5 - index * 0.04))
            width: look.slotSize
            height: look.slotSize + look.labelRoom
            x: look.menu.cx + Math.cos(ang) * r - width / 2
            y: look.menu.cy + Math.sin(ang) * r - look.slotSize / 2
            opacity: lit
            // a petal: two round corners, turned along the wind
            Rectangle {
                id: leaf
                width: look.slotSize
                height: look.slotSize
                rotation: petal.ang * 180 / Math.PI + 45
                topLeftRadius: width / 2
                bottomRightRadius: width / 2
                scale: petal.hot ? 1.15 : 1
                Behavior on scale {
                    NumberAnimation {
                        duration: Motion.ms(90)
                    }
                }
                color: petal.hot ? Theme.hellFaceAlt : Theme.hellPlate
                border.width: Math.max(1, Theme.u / 2)
                border.color: petal.hot ? Theme.hellAccent : Theme.hellRim
            }
            CircleIcon {
                anchors.centerIn: leaf
                hot: petal.hot
                name: petal.icon
                pixel: Math.max(1, Math.round(Theme.u * look.k * 0.85))
            }
            CircleLabel {
                visible: look.menu.labels
                hot: petal.hot
                anchors.horizontalCenter: leaf.horizontalCenter
                y: look.slotSize + Theme.u * 2
                text: petal.label
            }
        }
    }

    CircleFly {
        menu: look.menu
        reach: look.reach
        at: look.menu.flyIndex >= 0 ? Qt.point(look.menu.cx + Math.cos(look.angleOf(look.menu.flyIndex)) * (look.radiusOf(look.menu.flyIndex) + look.slotSize / 2), look.menu.cy + Math.sin(look.angleOf(look.menu.flyIndex)) * (look.radiusOf(look.menu.flyIndex) + look.slotSize / 2)) : Qt.point(look.menu.cx, look.menu.cy)
    }
}
