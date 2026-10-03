pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// The look of RadialMenu in the circle of greed: a wheel of fortune at the pointer. One
// sector per entry, dark and blood by turns, gold between them and studs round the rim; the
// sector you're on lights up under the gold pointer's gaze. Opening, the wheel spins and
// stops with every entry in its place; the names stand outside the rim.
Item {
    id: look

    required property var menu
    readonly property real k: menu.k
    readonly property int n: Math.max(1, menu.slots.length)
    readonly property real slotSize: Math.round(Theme.u * 18 * k)
    readonly property real labelRoom: menu.labels ? Theme.sizeTiny + Theme.u * 3 : 0
    readonly property real wheelR: Math.max(Theme.u * 58 * k, n * (slotSize + Theme.u * 8 * k) / (2 * Math.PI * 0.68))
    readonly property real iconR: wheelR * 0.7
    readonly property real nameR: wheelR + Theme.u * 6 + labelRoom
    readonly property real reach: nameR + Theme.u * 10
    readonly property Item blurItem: null
    // the spin: one and a half turns, slowing to a stop with the menu's opening
    readonly property real spin: (1 - menu.reveal) * Math.PI * 3
    function angleOf(i) {
        return -Math.PI / 2 + (i + 0.5) * 2 * Math.PI / n + spin;
    }
    function nav(e) {
        return menu.walk(e);
    }
    anchors.fill: parent

    // the wheel: sectors, gold spokes and rim, studs
    Canvas {
        id: wheel
        x: look.menu.cx - width / 2
        y: look.menu.cy - height / 2
        width: (look.wheelR + Theme.u * 4) * 2
        height: width
        rotation: look.spin * 180 / Math.PI
        opacity: Math.min(1, look.menu.reveal * 2)
        property int hot: look.menu.current
        onHotChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const c = width / 2, R = look.wheelR, n = look.n, u = Theme.u;
            for (let i = 0; i < n; i++) {
                const a0 = -Math.PI / 2 + i * 2 * Math.PI / n, a1 = a0 + 2 * Math.PI / n;
                ctx.beginPath();
                ctx.moveTo(c, c);
                ctx.arc(c, c, R, a0, a1, false);
                ctx.closePath();
                ctx.fillStyle = (i === hot ? Theme.mix(Theme.hellBlood, Theme.hellAccent, 0.45) : i % 2 ? Theme.hellBlood : Theme.hellBody).toString();
                ctx.fill();
            }
            ctx.strokeStyle = Theme.hellGold.toString();
            ctx.lineWidth = Math.max(1, u);
            for (let i = 0; i < n; i++) {
                const a = -Math.PI / 2 + i * 2 * Math.PI / n;
                ctx.beginPath();
                ctx.moveTo(c, c);
                ctx.lineTo(c + Math.cos(a) * R, c + Math.sin(a) * R);
                ctx.stroke();
            }
            ctx.lineWidth = Math.max(2, u * 2);
            ctx.beginPath();
            ctx.arc(c, c, R, 0, 2 * Math.PI, false);
            ctx.stroke();
            // the studs on the rim, two to a sector
            ctx.fillStyle = Theme.hellGold.toString();
            for (let i = 0; i < n * 2; i++) {
                const a = -Math.PI / 2 + (i + 0.5) * Math.PI / n;
                const x = c + Math.cos(a) * (R + u * 2), y = c + Math.sin(a) * (R + u * 2);
                ctx.fillRect(Math.round(x - u), Math.round(y - u), u * 2, u * 2);
            }
        }
    }

    // the pointer at the top, looking down into the wheel
    PxIcon {
        bitmap: ["#######", "#yyyyy#", ".#yyy#.", "..#y#..", "...#..."]
        pixel: Math.max(1, Math.round(Theme.u * look.k))
        ink: Theme.hellEdge
        fill3: look.menu.current >= 0 ? Theme.hellAccent : Theme.hellGold
        x: look.menu.cx - width / 2
        y: look.menu.cy - look.wheelR - height + Theme.u * 2
        opacity: look.menu.reveal
    }

    CircleHub {
        menu: look.menu
        size: Math.round(look.slotSize * 1.4)
        color: Theme.hellFace
        rim: Theme.hellGold
        nameGap: look.wheelR - look.slotSize * 0.7 + Theme.u * 10
    }

    // the entries: an icon in each sector, its name outside the rim
    Repeater {
        model: look.menu.slots
        CircleEntry {
            id: sector
            menu: look.menu
            readonly property real ang: look.angleOf(index)
            width: look.slotSize
            height: look.slotSize
            x: look.menu.cx + Math.cos(ang) * look.iconR - width / 2
            y: look.menu.cy + Math.sin(ang) * look.iconR - height / 2
            CircleIcon {
                anchors.centerIn: parent
                hot: sector.hot
                name: sector.icon
                scale: sector.hot ? 1.2 : 1
                pixel: Math.max(1, Math.round(Theme.u * look.k * 0.85))
                fill: sector.hot ? Theme.hellGold : Theme.hellTextDim
            }
            CircleLabel {
                visible: look.menu.labels
                hot: sector.hot
                opacity: Math.max(0, look.menu.reveal * 4 - 3)
                x: Math.cos(sector.ang) * (look.nameR - look.iconR) + (sector.width - width) / 2 + Math.cos(sector.ang) * width * 0.35
                y: Math.sin(sector.ang) * (look.nameR - look.iconR) + (sector.height - height) / 2
                text: sector.label
            }
        }
    }

    CircleFly {
        menu: look.menu
        reach: look.reach
        at: look.menu.flyIndex >= 0 ? Qt.point(look.menu.cx + Math.cos(look.angleOf(look.menu.flyIndex)) * look.nameR, look.menu.cy + Math.sin(look.angleOf(look.menu.flyIndex)) * look.nameR) : Qt.point(look.menu.cx, look.menu.cy)
    }
}
