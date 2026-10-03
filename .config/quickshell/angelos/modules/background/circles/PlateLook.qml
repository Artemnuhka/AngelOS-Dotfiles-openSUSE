pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// The look of RadialMenu in the circle of gluttony: a dinner plate laid at the pointer, a
// fork on its left and a knife on its right; the entries are small dishes served round its
// rim (more than the rim holds go into the well), the logo is the main course. Opening, the
// plate is set down and the dishes are served one by one.
Item {
    id: look

    required property var menu
    readonly property real k: menu.k
    readonly property int n: menu.slots.length
    readonly property real slotSize: Math.round(Theme.u * 20 * k)
    readonly property real labelRoom: menu.labels ? Theme.sizeTiny + Theme.u * 3 : 0
    readonly property int onRim: n > 12 ? 12 : n
    readonly property int inWell: n - onRim
    readonly property real step: slotSize + (menu.labels ? Theme.u * 26 : Theme.u * 10) * k
    readonly property real rimR: Math.max(Theme.u * 50 * k, onRim * step / (2 * Math.PI))
    readonly property real wellR: rimR * 0.5
    readonly property real plateR: rimR + slotSize / 2 + labelRoom + Theme.u * 5 * k
    readonly property real reach: plateR + Theme.u * 24 * k
    readonly property Item blurItem: null
    function angleOf(i) {
        return i < onRim ? -Math.PI / 2 + i * 2 * Math.PI / onRim : -Math.PI / 2 + (i - onRim + 0.5) * 2 * Math.PI / Math.max(1, inWell);
    }
    function radiusOf(i) {
        return i < onRim ? rimR : wellR;
    }
    function nav(e) {
        return menu.walk(e);
    }
    anchors.fill: parent

    // the plate: its rim, the glaze line, the well
    Item {
        id: plate
        x: look.menu.cx - look.plateR
        y: look.menu.cy - look.plateR
        width: look.plateR * 2
        height: width
        scale: 0.7 + 0.3 * look.menu.reveal
        opacity: look.menu.reveal
        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Theme.hellFace
            border.width: Math.max(1, Theme.u)
            border.color: Theme.hellRim
        }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width - Theme.u * 6
            height: width
            radius: width / 2
            color: "transparent"
            border.width: Math.max(1, Theme.u / 2)
            border.color: Qt.alpha(Theme.hellText, 0.18)
        }
        Rectangle {
            anchors.centerIn: parent
            width: (look.rimR - look.slotSize / 2 - Theme.u * 4) * 2
            height: width
            radius: width / 2
            color: Theme.hellPlate
            border.width: Math.max(1, Theme.u / 2)
            border.color: Qt.alpha(Theme.hellRim, 0.7)
        }
    }

    // the fork and the knife, laid either side
    PxIcon {
        bitmap: ["#.#.#", "#.#.#", "#.#.#", "#####", ".###.", "..#..", "..#..", "..#..", "..#..", "..#..", ".###.", ".###.", ".###.", "..#.."]
        pixel: Math.max(1, Math.round(Theme.u * look.k * 2))
        ink: Theme.hellTextDim
        x: look.menu.cx - look.plateR - width - Theme.u * 6
        y: look.menu.cy - height / 2
        opacity: look.menu.reveal
    }
    PxIcon {
        bitmap: [".#.", "##.", "##.", "###", "###", "###", "###", "###", ".#.", ".#.", "###", "###", "###", ".#."]
        pixel: Math.max(1, Math.round(Theme.u * look.k * 2))
        ink: Theme.hellTextDim
        x: look.menu.cx + look.plateR + Theme.u * 6
        y: look.menu.cy - height / 2
        opacity: look.menu.reveal
    }

    CircleHub {
        menu: look.menu
        size: Math.round(look.slotSize * 1.3)
        color: Theme.hellFaceAlt
        hover: Theme.mix(Theme.hellFaceAlt, Theme.hellAccent, 0.3)
    }

    // the dishes
    Repeater {
        model: look.menu.slots
        CircleEntry {
            id: dish
            menu: look.menu
            readonly property real ang: look.angleOf(index)
            readonly property real lit: Math.max(0, Math.min(1, look.menu.reveal * 1.8 - 0.3 - index * 0.06))
            width: look.slotSize
            height: look.slotSize + look.labelRoom
            x: look.menu.cx + Math.cos(ang) * look.radiusOf(index) - width / 2
            y: look.menu.cy + Math.sin(ang) * look.radiusOf(index) - look.slotSize / 2 - (1 - lit) * Theme.u * 8
            opacity: lit
            // a small plate with its own rim; the one you're on is lifted
            Rectangle {
                id: saucer
                width: look.slotSize
                height: look.slotSize
                radius: width / 2
                scale: dish.hot ? 1.15 : 1
                Behavior on scale {
                    NumberAnimation {
                        duration: Motion.ms(90)
                    }
                }
                color: dish.hot ? Theme.hellFaceAlt : Theme.hellPlate
                border.width: Math.max(1, Theme.u / 2)
                border.color: dish.hot ? Theme.hellAccent : Theme.hellRim
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - Theme.u * 5
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: Math.max(1, Theme.u / 2)
                    border.color: Qt.alpha(Theme.hellText, dish.hot ? 0.3 : 0.12)
                }
            }
            CircleIcon {
                anchors.centerIn: saucer
                hot: dish.hot
                name: dish.icon
                pixel: Math.max(1, Math.round(Theme.u * look.k * 0.85))
            }
            CircleLabel {
                visible: look.menu.labels
                hot: dish.hot
                anchors.horizontalCenter: saucer.horizontalCenter
                y: look.slotSize + Theme.u * 2
                text: dish.label
            }
        }
    }

    CircleFly {
        menu: look.menu
        reach: look.reach
        at: look.menu.flyIndex >= 0 ? Qt.point(look.menu.cx + Math.cos(look.angleOf(look.menu.flyIndex)) * look.plateR, look.menu.cy + Math.sin(look.angleOf(look.menu.flyIndex)) * look.plateR) : Qt.point(look.menu.cx, look.menu.cy)
    }
}
