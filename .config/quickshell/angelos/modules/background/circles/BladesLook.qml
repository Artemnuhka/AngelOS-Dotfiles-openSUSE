pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// The look of RadialMenu in the circle of violence: a fan of blades from a hilt at the
// pointer — up to nine fanned out above it, more all the way round, long and short by turns;
// the entries sit at their points. Opening, the fan snaps open from one blade; the one you're
// on is bloodied at the edge.
Item {
    id: look

    required property var menu
    readonly property real k: menu.k
    readonly property int n: Math.max(1, menu.slots.length)
    readonly property bool round: n > 9
    readonly property real slotSize: Math.round(Theme.u * 18 * k)
    readonly property real labelRoom: menu.labels ? Theme.sizeTiny + Theme.u * 3 : 0
    readonly property real span: round ? 2 * Math.PI : Math.PI * 1.25
    readonly property real step: round ? span / n : span / Math.max(1, n - 1)
    // all the way round, long and short by turns: the short ones keep the room between points
    readonly property real stagger: round ? slotSize + labelRoom + Theme.u * 6 * k : 0
    readonly property real shortR: Math.max(Theme.u * 58 * k, (slotSize + labelRoom + Theme.u * 10 * k) / Math.max(0.2, step * (round ? 2 : 1)))
    readonly property real longR: shortR + stagger
    readonly property real reach: longR + slotSize / 2 + labelRoom + Theme.u * 6
    readonly property Item blurItem: null
    // above the pointer, centred; the fan opens from its middle blade
    readonly property real mid: -Math.PI / 2
    function angleOf(i) {
        const a = round ? mid + i * step : mid - span / 2 + i * step;
        return mid + (a - mid) * menu.reveal;
    }
    function radiusOf(i) {
        return round && i % 2 ? shortR : longR;
    }
    function nav(e) {
        return menu.walk(e);
    }
    anchors.fill: parent

    // the blades: steel from the hilt to the point
    Repeater {
        model: look.menu.slots
        Item {
            id: blade
            required property int index
            readonly property bool hot: look.menu.current === index || look.menu.fly === look.menu.slots[index]
            readonly property real len: look.radiusOf(index) - look.slotSize / 2 - Theme.u * 2
            x: look.menu.cx
            y: look.menu.cy - height / 2
            width: len
            height: Math.max(2, Math.round(Theme.u * 4 * look.k))
            transformOrigin: Item.Left
            rotation: look.angleOf(index) * 180 / Math.PI
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: Theme.u * 10 * look.k
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop {
                        position: 0
                        color: Theme.hellText
                    }
                    GradientStop {
                        position: 0.5
                        color: Theme.hellTextDim
                    }
                    GradientStop {
                        position: 1
                        color: Theme.hellFaceAlt
                    }
                }
                border.width: Math.max(1, Theme.u / 2)
                border.color: Theme.hellEdge
            }
            // the bloodied edge of the one you're on
            Rectangle {
                visible: blade.hot
                x: parent.width * 0.45
                width: parent.width * 0.55
                height: Math.max(1, Theme.u)
                color: Theme.hellAccent
            }
            // the guard
            Rectangle {
                x: Theme.u * 9 * look.k
                y: (parent.height - height) / 2
                width: Math.max(2, Theme.u * 2)
                height: parent.height * 2.4
                color: Theme.hellGold
            }
        }
    }

    // the hilt's pommel: the middle
    CircleHub {
        menu: look.menu
        size: Math.round(look.slotSize * 1.15)
        corner: Theme.u * 2
        tilt: 45
        color: Theme.hellFace
        rim: Theme.hellGold
        showName: !look.round
        nameGap: -look.slotSize * 2.2
    }

    Repeater {
        model: look.menu.slots
        CircleEntry {
            id: point
            menu: look.menu
            readonly property real ang: look.angleOf(index)
            width: look.slotSize
            height: look.slotSize + look.labelRoom
            x: look.menu.cx + Math.cos(ang) * look.radiusOf(index) - width / 2
            y: look.menu.cy + Math.sin(ang) * look.radiusOf(index) - look.slotSize / 2
            opacity: Math.min(1, look.menu.reveal * 1.5)
            Rectangle {
                id: tip
                width: look.slotSize
                height: look.slotSize
                rotation: 45
                scale: point.hot ? 1.12 : 1
                color: point.hot ? Theme.hellFaceAlt : Theme.hellPlate
                border.width: Math.max(1, Theme.u / 2)
                border.color: point.hot ? Theme.hellAccent : Theme.hellRim
            }
            CircleIcon {
                anchors.centerIn: tip
                hot: point.hot
                name: point.icon
                pixel: Math.max(1, Math.round(Theme.u * look.k * 0.8))
            }
            // a drop falls from the one you're on
            Rectangle {
                visible: point.hot
                anchors.horizontalCenter: tip.horizontalCenter
                y: look.slotSize + Theme.u
                width: Theme.u * 2
                height: Theme.u * 3
                radius: Theme.u
                color: Theme.hellAccent
            }
            CircleLabel {
                visible: look.menu.labels
                hot: point.hot
                anchors.horizontalCenter: tip.horizontalCenter
                y: look.slotSize + Theme.u * (point.hot ? 5 : 2)
                text: point.label
            }
        }
    }

    CircleFly {
        menu: look.menu
        reach: look.reach
        at: look.menu.flyIndex >= 0 ? Qt.point(look.menu.cx + Math.cos(look.angleOf(look.menu.flyIndex)) * (look.radiusOf(look.menu.flyIndex) + look.slotSize / 2), look.menu.cy + Math.sin(look.angleOf(look.menu.flyIndex)) * (look.radiusOf(look.menu.flyIndex) + look.slotSize / 2)) : Qt.point(look.menu.cx, look.menu.cy)
    }
}
