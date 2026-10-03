pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// The look of RadialMenu in the circle of wrath: a stone dropped into the Styx at the
// pointer. Ripples run out from it, and the entries are stones on them — six on the first
// ring, the rest on the next ones, each ring turned half a step; the one you're on rings the
// water round itself. Opening, the ripples spread out to their places.
Item {
    id: look

    required property var menu
    readonly property real k: menu.k
    readonly property int n: menu.slots.length
    readonly property real slotSize: Math.round(Theme.u * 20 * k)
    readonly property real labelRoom: menu.labels ? Theme.sizeTiny + Theme.u * 3 : 0
    readonly property real gap: slotSize + labelRoom + Theme.u * 10 * k
    // how many stones each ring holds: 6, then 10, then the rest
    readonly property var rings: {
        const out = [];
        let left = n, cap = 6;
        while (left > 0) {
            out.push(Math.min(left, cap));
            left -= cap;
            cap += 4;
        }
        return out;
    }
    readonly property real r0: Theme.u * 40 * k
    readonly property real outer: r0 + Math.max(0, rings.length - 1) * gap
    readonly property real reach: outer + slotSize / 2 + labelRoom + Theme.u * 6
    readonly property Item blurItem: null
    function ringOf(i) {
        let j = i;
        for (let r = 0; r < rings.length; r++) {
            if (j < rings[r])
                return {
                    "ring": r,
                    "at": j,
                    "of": rings[r]
                };
            j -= rings[r];
        }
        return {
            "ring": 0,
            "at": 0,
            "of": 1
        };
    }
    function angleOf(i) {
        const p = ringOf(i);
        return -Math.PI / 2 + (p.at + (p.ring % 2 ? 0.5 : 0)) * 2 * Math.PI / p.of;
    }
    function radiusOf(i) {
        return (r0 + ringOf(i).ring * gap) * (0.4 + 0.6 * menu.reveal);
    }
    function nav(e) {
        return menu.walk(e);
    }
    anchors.fill: parent

    // the dark water they run over
    Rectangle {
        readonly property real r: (look.outer + look.gap * 0.7) * (0.4 + 0.6 * look.menu.reveal)
        x: look.menu.cx - r
        y: look.menu.cy - r
        width: r * 2
        height: width
        radius: r
        color: Qt.alpha(Theme.hellBody, 0.55 * look.menu.reveal)
    }
    // the ripples: each ring of stones, a ring between them, and two fading ones beyond
    Repeater {
        model: (look.rings.length + 2) * 2
        Rectangle {
            required property int index
            readonly property real r: (look.r0 * 0.5 + index * look.gap / 2) * (0.4 + 0.6 * look.menu.reveal)
            visible: index % 2 === 0
            x: look.menu.cx - r
            y: look.menu.cy - r
            width: r * 2
            height: width
            radius: r
            color: "transparent"
            border.width: Math.max(1, Theme.u / 2)
            border.color: Qt.alpha(Theme.hellText, Math.max(0.08, 0.3 - index * 0.04) * look.menu.reveal)
        }
    }
    Repeater {
        model: look.rings.length + 2
        Rectangle {
            required property int index
            readonly property real r: (look.r0 + index * look.gap) * (0.4 + 0.6 * look.menu.reveal)
            x: look.menu.cx - r
            y: look.menu.cy - r
            width: r * 2
            height: width
            radius: r
            color: "transparent"
            border.width: Math.max(1, Theme.u)
            border.color: Qt.alpha(Theme.hellRim, Math.max(0.2, 0.9 - index * 0.2) * look.menu.reveal)
        }
    }
    // the stone that fell: the middle
    CircleHub {
        menu: look.menu
        size: Math.round(look.slotSize * 1.1)
        corner: size * 0.35
        color: Theme.hellFace
    }

    Repeater {
        model: look.menu.slots
        CircleEntry {
            id: stone
            menu: look.menu
            readonly property real ang: look.angleOf(index)
            width: look.slotSize
            height: look.slotSize + look.labelRoom
            x: look.menu.cx + Math.cos(ang) * look.radiusOf(index) - width / 2
            y: look.menu.cy + Math.sin(ang) * look.radiusOf(index) - look.slotSize / 2
            opacity: Math.max(0, Math.min(1, look.menu.reveal * 1.6 - look.ringOf(index).ring * 0.25))
            // the water rung round the one you're on
            Rectangle {
                visible: stone.hot
                anchors.centerIn: rock
                width: look.slotSize * 1.6
                height: width
                radius: width / 2
                color: "transparent"
                border.width: Math.max(1, Theme.u / 2)
                border.color: Qt.alpha(Theme.hellAccent, 0.7)
            }
            Rectangle {
                id: rock
                width: look.slotSize
                height: look.slotSize
                radius: width * 0.35
                color: stone.hot ? Theme.hellFaceAlt : Theme.hellPlate
                border.width: Math.max(1, Theme.u / 2)
                border.color: stone.hot ? Theme.hellAccent : Theme.hellRim
                // the waterline: the lower third under the Styx
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: parent.border.width
                    x: parent.border.width
                    width: parent.width - parent.border.width * 2
                    height: Math.round(parent.height / 3)
                    bottomLeftRadius: parent.radius
                    bottomRightRadius: parent.radius
                    color: Qt.alpha(Theme.hellRim, 0.55)
                }
            }
            CircleIcon {
                anchors.centerIn: rock
                hot: stone.hot
                name: stone.icon
                pixel: Math.max(1, Math.round(Theme.u * look.k * 0.85))
            }
            CircleLabel {
                visible: look.menu.labels
                hot: stone.hot
                anchors.horizontalCenter: rock.horizontalCenter
                y: look.slotSize + Theme.u * 2
                text: stone.label
            }
        }
    }

    CircleFly {
        menu: look.menu
        reach: look.reach
        at: look.menu.flyIndex >= 0 ? Qt.point(look.menu.cx + Math.cos(look.angleOf(look.menu.flyIndex)) * (look.radiusOf(look.menu.flyIndex) + look.slotSize / 2), look.menu.cy + Math.sin(look.angleOf(look.menu.flyIndex)) * (look.radiusOf(look.menu.flyIndex) + look.slotSize / 2)) : Qt.point(look.menu.cx, look.menu.cy)
    }
}
