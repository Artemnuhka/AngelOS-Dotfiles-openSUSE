pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// Limbo's look of RadialMenu: a ticket dispenser at the pointer — "take a number" — and the
// entries as numbered paper tickets rolling out of it one under another, perforated between;
// the one you're on is pulled out a little, its number lit on the dispenser's display.
// Flyouts open beside the tickets.
Item {
    id: look

    required property var menu
    readonly property real k: menu.k
    readonly property int n: menu.slots.length
    readonly property real tw: Math.round(Theme.u * (menu.labels ? 86 : 40) * k)
    readonly property real th: Math.round(Theme.u * 15 * k)
    readonly property real headH: Math.round(Theme.u * 20 * k)
    readonly property real total: headH + n * th
    readonly property real reach: Math.max(tw / 2 + Theme.u * 12, total / 2 + Theme.u * 4)
    readonly property Item blurItem: null
    readonly property real x0: menu.cx - tw / 2
    readonly property real y0: menu.cy - total / 2
    // the paper is bone, the print the pit's dark
    readonly property color paper: Theme.mix(Theme.hellText, Theme.hellFace, 0.18)
    readonly property color paperHot: Theme.hellText
    readonly property color type: Theme.hellBody
    function number(i) {
        return (i < 9 ? "0" : "") + (i + 1);
    }
    function nav(e) {
        return menu.walk(e);
    }
    anchors.fill: parent

    // the tickets, under the dispenser they come out of
    Repeater {
        model: look.menu.slots
        CircleEntry {
            id: ticket
            menu: look.menu
            readonly property real lit: Math.max(0, Math.min(1, look.menu.reveal * 1.6 - index * 0.05))
            x: look.x0 + (hot ? Theme.u * 6 : 0)
            y: look.y0 + look.headH + (index - (1 - lit)) * look.th
            width: look.tw
            height: look.th
            opacity: lit
            Behavior on x {
                NumberAnimation {
                    duration: Motion.ms(90)
                }
            }
            Rectangle {
                anchors.fill: parent
                color: ticket.hot ? look.paperHot : look.paper
            }
            // the notches on both sides, bitten out of the paper
            Repeater {
                model: 2
                Rectangle {
                    required property int index
                    width: Theme.u * 3
                    height: width
                    radius: width / 2
                    x: index ? ticket.width - width / 2 : -width / 2
                    y: (ticket.height - height) / 2
                    color: Theme.hellBody
                }
            }
            // the perforation under it
            Row {
                visible: ticket.index < look.n - 1
                x: Theme.u * 3
                y: ticket.height - height
                spacing: Theme.u
                Repeater {
                    model: Math.max(0, Math.floor((ticket.width - Theme.u * 6) / (Theme.u * 2)))
                    Rectangle {
                        width: Theme.u
                        height: Math.max(1, Theme.u / 2)
                        color: Qt.alpha(look.type, 0.4)
                    }
                }
            }
            Row {
                x: Theme.u * 5
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.u * 3
                PxText {
                    anchors.verticalCenter: parent.verticalCenter
                    kind: "mono"
                    font.bold: ticket.hot
                    color: ticket.hot ? Theme.hellBlood : Qt.alpha(look.type, 0.7)
                    text: look.number(ticket.index)
                }
                CircleIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    hot: ticket.hot
                    name: ticket.icon
                    pixel: Math.max(1, Math.round(Theme.u * look.k * 0.75))
                    ink: look.type
                    fill: ticket.hot ? Theme.hellBlood : Theme.mix(look.type, look.paper, 0.45)
                    light: look.paper
                    body: Theme.mix(look.paper, look.type, 0.15)
                }
                PxText {
                    visible: look.menu.labels
                    anchors.verticalCenter: parent.verticalCenter
                    width: look.tw - x - Theme.u * 8
                    elide: Text.ElideRight
                    kind: "tiny"
                    font.bold: ticket.hot
                    color: look.type
                    text: ticket.label
                }
            }
        }
    }

    // the dispenser: "take a number", and the number you're on in its little display
    Rectangle {
        id: box
        x: look.x0 - Theme.u * 4
        y: look.y0
        width: look.tw + Theme.u * 8
        height: look.headH
        color: Theme.hellFace
        border.width: Math.max(1, Theme.u / 2)
        border.color: Theme.hellRim
        scale: Math.min(1, 0.6 + look.menu.reveal)
        PxText {
            visible: look.menu.labels
            x: Theme.u * 5
            anchors.verticalCenter: parent.verticalCenter
            kind: "tiny"
            color: Theme.hellTextDim
            text: I18n.t("ВОЗЬМИТЕ ТАЛОН", "TAKE A NUMBER")
        }
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: Theme.u * 4
            anchors.verticalCenter: parent.verticalCenter
            width: shown.implicitWidth + Theme.u * 6
            height: look.headH - Theme.u * 7
            color: Theme.hellBody
            border.width: Math.max(1, Theme.u / 2)
            border.color: Theme.hellEdge
            PxText {
                id: shown
                anchors.centerIn: parent
                kind: "mono"
                color: look.menu.current >= 0 ? Theme.hellAccent : Theme.hellTextDim
                text: look.menu.current >= 0 ? look.number(look.menu.current) : "--"
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: look.menu.close()
            }
        }
        // the slot the tickets come out of
        Rectangle {
            x: Theme.u * 3
            y: parent.height - height
            width: parent.width - Theme.u * 6
            height: Math.max(1, Theme.u)
            color: Theme.hellBody
        }
    }

    CircleFly {
        menu: look.menu
        reach: look.tw / 2 + Theme.u * 4
        at: Qt.point(look.x0 + look.tw + Theme.u * 6, look.y0 + look.headH + Math.max(0, look.menu.flyIndex) * look.th + look.th / 2)
    }
}
