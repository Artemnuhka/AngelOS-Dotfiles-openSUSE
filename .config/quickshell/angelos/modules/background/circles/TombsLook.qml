pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// The look of RadialMenu in the circle of heresy: a graveyard of the city of Dis at the
// pointer — the entries are headstones in rows, the far rows smaller, each with the embers of
// its open tomb at its foot; the one you're on burns. Opening, the stones rise out of the
// ground row by row. The logo stands at the gate, above the graves.
Item {
    id: look

    required property var menu
    readonly property real k: menu.k
    readonly property int n: menu.slots.length
    readonly property int cols: Math.min(5, Math.max(1, Math.ceil(Math.sqrt(n * 1.6))))
    readonly property int rows: Math.max(1, Math.ceil(n / cols))
    readonly property real stoneW: Math.round(Theme.u * 22 * k)
    readonly property real stoneH: Math.round(Theme.u * 28 * k)
    readonly property real labelRoom: menu.labels ? Theme.sizeTiny + Theme.u * 4 : Theme.u * 2
    readonly property real colW: stoneW + (menu.labels ? Theme.u * 22 : Theme.u * 8) * k
    readonly property real rowH: stoneH + labelRoom + Theme.u * 6 * k
    readonly property real gateH: Math.round(Theme.u * 26 * k)
    readonly property real gridW: cols * colW
    readonly property real gridH: gateH + rows * rowH
    readonly property real reach: Math.max(gridW, gridH) / 2 + Theme.u * 6
    readonly property Item blurItem: null
    readonly property real y0: menu.cy - gridH / 2
    // the far rows smaller: the front one full size
    function scaleOf(row) {
        return rows < 2 ? 1 : 0.82 + 0.18 * row / (rows - 1);
    }
    function centreOf(i) {
        const row = Math.floor(i / cols), col = i % cols;
        const inRow = row === rows - 1 ? n - row * cols : cols;
        return Qt.point(menu.cx + (col - (inRow - 1) / 2) * colW * scaleOf(row), y0 + gateH + row * rowH + stoneH / 2);
    }
    function nav(e) {
        return menu.walk(e);
    }
    anchors.fill: parent

    // the gate of Dis: the logo between two posts
    CircleHub {
        menu: look.menu
        size: Math.round(look.stoneW * 1.05)
        corner: Theme.u * 2
        color: Theme.hellFace
        x: look.menu.cx - size / 2
        y: look.y0
        nameGap: Theme.u * 2
    }
    Repeater {
        model: 2
        Rectangle {
            required property int index
            width: Theme.u * 4 * look.k
            height: look.gateH - Theme.u * 4
            x: look.menu.cx + (index ? 1 : -1) * look.stoneW * 0.9 - width / 2
            y: look.y0
            color: Theme.hellPlate
            border.width: Math.max(1, Theme.u / 2)
            border.color: Theme.hellRim
            opacity: look.menu.reveal
        }
    }
    // the ground of each row
    Repeater {
        model: look.rows
        Rectangle {
            required property int index
            readonly property real s: look.scaleOf(index)
            x: look.menu.cx - width / 2
            y: look.y0 + look.gateH + index * look.rowH + look.stoneH - Theme.u
            width: look.gridW * s
            height: Theme.u * 2
            color: Qt.alpha(Theme.hellBody, 0.8 * look.menu.reveal)
        }
    }

    Repeater {
        model: look.menu.slots
        CircleEntry {
            id: grave
            menu: look.menu
            readonly property int row: Math.floor(index / look.cols)
            readonly property real s: look.scaleOf(row)
            readonly property point c: look.centreOf(index)
            readonly property real lit: Math.max(0, Math.min(1, look.menu.reveal * 1.7 - row * 0.25 - (index % look.cols) * 0.04))
            width: look.colW * s
            height: (look.stoneH + look.labelRoom) * s
            x: c.x - width / 2
            y: c.y + look.stoneH / 2 - look.stoneH * s
            opacity: lit
            // the stone rises out of the ground; nothing shows below it
            Item {
                id: plot
                anchors.horizontalCenter: parent.horizontalCenter
                width: look.stoneW * grave.s
                height: look.stoneH * grave.s
                clip: true
                Rectangle {
                    id: stone
                    width: parent.width
                    height: parent.height
                    y: (1 - grave.lit) * height
                    topLeftRadius: width / 2
                    topRightRadius: width / 2
                    color: grave.hot ? Theme.hellFaceAlt : Theme.hellPlate
                    border.width: Math.max(1, Theme.u / 2)
                    border.color: grave.hot ? Theme.hellAccent : Theme.hellRim
                    CircleIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height * 0.32
                        hot: grave.hot
                        name: grave.icon
                        pixel: Math.max(1, Math.round(Theme.u * look.k * 0.8 * grave.s))
                    }
                    // the embers of the open tomb at its foot
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: parent.border.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width * 0.6
                        height: Math.max(1, Theme.u)
                        color: grave.hot ? Theme.hellFlame : Qt.alpha(Theme.hellEmber, 0.7)
                    }
                }
            }
            // the one you're on burns: a flame on the stone
            PxIcon {
                visible: grave.hot
                bitmap: ["..r..", ".rr..", ".ryr.", "ryyr.", "ryyyr", ".ryr."]
                pixel: Math.max(1, Math.round(Theme.u * look.k * 0.75))
                bad: Theme.hellFlame
                fill3: Theme.hellGold
                anchors.horizontalCenter: plot.horizontalCenter
                y: -height + Theme.u
            }
            CircleLabel {
                visible: look.menu.labels
                hot: grave.hot
                anchors.horizontalCenter: plot.horizontalCenter
                y: plot.height + Theme.u * 2
                width: Math.min(implicitWidth, look.colW * grave.s)
                elide: Text.ElideRight
                text: grave.label
            }
        }
    }

    CircleFly {
        menu: look.menu
        reach: look.gridW / 2 + Theme.u * 4
        at: look.menu.flyIndex >= 0 ? look.centreOf(look.menu.flyIndex) : Qt.point(look.menu.cx, look.menu.cy)
    }
}
