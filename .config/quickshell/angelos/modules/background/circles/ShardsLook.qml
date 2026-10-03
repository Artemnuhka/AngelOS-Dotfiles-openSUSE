pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import qs.config
import qs.services
import qs.widgets

// The look of RadialMenu in the circle of treachery: an ice crystal grows from the pointer —
// six arms with their side branches; the entries are hexagons of ice, six at the arms' ends,
// six more between them, and further out along the arms the rest. Opening, the crystal grows
// and freezes them in place. The one you're on takes the accent's cold light.
Item {
    id: look

    required property var menu
    readonly property real k: menu.k
    readonly property int n: menu.slots.length
    readonly property real slotSize: Math.round(Theme.u * 20 * k)
    readonly property real labelRoom: menu.labels ? Theme.sizeTiny + Theme.u * 3 : 0
    readonly property real r1: Math.max(Theme.u * 50 * k, slotSize * 2.5)
    readonly property real gap: slotSize + labelRoom + Theme.u * 8 * k
    // ring 0: on the arms · ring 1: between the arms, further out · ring 2+: out along the
    // arms and between them by turns
    function placeOf(i) {
        const ring = Math.floor(i / 6), j = i % 6;
        const between = ring % 2 === 1;
        const r = r1 + ring * gap * 0.6;
        return {
            "a": -Math.PI / 2 + (j + (between ? 0.5 : 0)) * Math.PI / 3,
            "r": r
        };
    }
    readonly property real outer: {
        let m = r1;
        for (let i = 0; i < n; i++)
            m = Math.max(m, placeOf(i).r);
        return m;
    }
    readonly property real reach: outer + slotSize / 2 + labelRoom + Theme.u * 6
    readonly property Item blurItem: null
    readonly property real grow: menu.reveal
    function pointOf(i, extra) {
        const p = placeOf(i), r = p.r * grow + (extra || 0);
        return Qt.point(menu.cx + Math.cos(p.a) * r, menu.cy + Math.sin(p.a) * r);
    }
    function nav(e) {
        return menu.walk(e);
    }
    anchors.fill: parent

    // the arms and their side branches
    Repeater {
        model: 6
        Item {
            id: arm
            required property int index
            readonly property real len: (look.outer + look.slotSize * 0.2) * look.grow
            x: look.menu.cx
            y: look.menu.cy - height / 2
            width: len
            height: Math.max(2, Theme.u * 2)
            transformOrigin: Item.Left
            rotation: -90 + index * 60
            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Theme.hellText, 0.55)
            }
            // two pairs of branches, at 40 % and 70 % of the arm
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    readonly property real at: index < 2 ? 0.4 : 0.7
                    x: arm.len * at
                    y: (arm.height - height) / 2
                    width: look.slotSize * (index < 2 ? 0.9 : 0.6)
                    height: Math.max(1, Theme.u)
                    transformOrigin: Item.Left
                    rotation: index % 2 ? -45 : 45
                    color: Qt.alpha(Theme.hellText, 0.4)
                }
            }
        }
    }

    CircleHub {
        menu: look.menu
        size: Math.round(look.slotSize * 1.15)
        corner: Theme.u
        tilt: 45
        color: Qt.alpha(Theme.hellBody, 0.9)
        hover: Theme.hellFaceAlt
        rim: Theme.hellText
        nameGap: Theme.u * 3
    }

    Repeater {
        model: look.menu.slots
        CircleEntry {
            id: shard
            menu: look.menu
            readonly property point at: look.pointOf(index)
            width: look.slotSize
            height: look.slotSize + look.labelRoom
            x: at.x - width / 2
            y: at.y - look.slotSize / 2
            opacity: Math.max(0, Math.min(1, look.menu.reveal * 1.6 - Math.floor(index / 6) * 0.2))
            // a hexagon of ice
            Shape {
                id: hex
                width: look.slotSize
                height: look.slotSize
                scale: shard.hot ? 1.15 : 1
                preferredRendererType: Shape.CurveRenderer
                readonly property real s: width / 2
                ShapePath {
                    strokeWidth: Math.max(1, Theme.u / 2)
                    strokeColor: shard.hot ? Theme.hellAccent : Qt.alpha(Theme.hellText, 0.7)
                    fillColor: shard.hot ? Theme.hellFaceAlt : Qt.alpha(Theme.hellPlate, 0.92)
                    startX: hex.s
                    startY: 0
                    PathLine {
                        x: hex.s + hex.s * 0.866
                        y: hex.s * 0.5
                    }
                    PathLine {
                        x: hex.s + hex.s * 0.866
                        y: hex.s * 1.5
                    }
                    PathLine {
                        x: hex.s
                        y: hex.s * 2
                    }
                    PathLine {
                        x: hex.s - hex.s * 0.866
                        y: hex.s * 1.5
                    }
                    PathLine {
                        x: hex.s - hex.s * 0.866
                        y: hex.s * 0.5
                    }
                    PathLine {
                        x: hex.s
                        y: 0
                    }
                }
            }
            // a glint of frost on the upper edge
            Rectangle {
                x: hex.width * 0.3
                y: hex.height * 0.2
                width: Math.max(1, Theme.u)
                height: Math.max(1, Theme.u)
                color: Theme.hellText
                opacity: 0.8
            }
            CircleIcon {
                anchors.centerIn: hex
                hot: shard.hot
                name: shard.icon
                pixel: Math.max(1, Math.round(Theme.u * look.k * 0.8))
            }
            CircleLabel {
                visible: look.menu.labels
                hot: shard.hot
                anchors.horizontalCenter: hex.horizontalCenter
                y: look.slotSize + Theme.u * 2
                text: shard.label
            }
        }
    }

    CircleFly {
        menu: look.menu
        reach: look.reach
        at: look.menu.flyIndex >= 0 ? look.pointOf(look.menu.flyIndex, look.slotSize / 2) : Qt.point(look.menu.cx, look.menu.cy)
    }
}
