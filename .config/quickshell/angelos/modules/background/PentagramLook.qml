pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// Hell's look of RadialMenu (while the demon rules, or picked by hand): a pentagram that
// draws itself in glowing red around the pointer. The first five entries sit on its points,
// the rest are runes on the outer circle between them; candles burn at the points, embers
// rise; flyouts open as a FlyColumn in hell's colours. The middle (horned logo) closes.
Item {
    id: look

    required property var menu
    readonly property real k: menu.k
    readonly property color blood: "#e0203a"
    readonly property color ember: "#ff7a2a"
    readonly property color bone: "#ffd9c2"
    readonly property color pit: "#12040a"
    readonly property real slotSize: Math.round(Theme.u * 22 * k)
    readonly property real runeSize: Math.round(Theme.u * 16 * k)
    readonly property real labelRoom: menu.labels ? Theme.sizeTiny + Theme.u * 3 : 0
    readonly property int rays: Math.min(5, menu.slots.length)
    readonly property int runes: Math.max(0, menu.slots.length - 5)
    readonly property real star: Math.round(Theme.u * 58 * k)                 // the points' radius
    readonly property real ring: star + slotSize * 0.5 + labelRoom + runeSize * 0.7 + Theme.u * 4
    readonly property real reach: ring + runeSize + labelRoom
    readonly property Item blurItem: null
    function angleOf(i) {
        if (i < 5)
            return -Math.PI / 2 + i * 2 * Math.PI / 5;
        // runes: one in each gap while they fit, else evenly all around
        const j = i - 5;
        if (runes <= 5)
            return -Math.PI / 2 + (j + 0.5) * 2 * Math.PI / 5;
        return -Math.PI / 2 + (j + 0.5) * 2 * Math.PI / runes;
    }
    function radiusOf(i) {
        return i < 5 ? star : ring;
    }
    function nav(e) {
        return menu.walk(e);
    }
    anchors.fill: parent

    // a red glow in the pit
    Rectangle {
        x: look.menu.cx - width / 2
        y: look.menu.cy - height / 2
        width: (look.ring + look.runeSize) * 2 * Math.max(0.3, look.menu.reveal)
        height: width
        radius: width / 2
        color: Qt.alpha("#3a0610", 0.55 * look.menu.reveal)
        border.width: Math.max(1, Theme.u / 2)
        border.color: Qt.alpha(look.blood, 0.35 * look.menu.reveal)
    }

    // the pentagram and its circles, drawn stroke by stroke as it opens — a shader
    // (shaders/pentagram.frag): the blurred Canvas it replaces stuttered on opening
    ShaderEffect {
        id: sigil
        readonly property real d: (look.ring + look.runeSize) * 2
        x: look.menu.cx - d / 2
        y: look.menu.cy - d / 2
        width: d
        height: d
        property real progress: look.menu.reveal
        property real side: d
        property real star: look.star
        property real ring: look.ring
        property real u: Theme.u
        property color blood: look.blood
        property color ember: look.ember
        fragmentShader: Qt.resolvedUrl("../../shaders/pentagram.frag.qsb")
    }

    // embers rising through it (made once; they only move while the menu is open)
    Repeater {
        model: 14
        Rectangle {
            id: spark
            required property int index
            readonly property real seed: (index * 7919 % 97) / 97
            width: Math.max(2, Theme.u * (seed > 0.6 ? 1.5 : 1))
            height: width
            color: seed > 0.5 ? look.ember : "#ffd23f"
            x: look.menu.cx + (seed - 0.5) * look.ring * 1.8
            property real rise: 0
            y: look.menu.cy + look.ring * 0.9 - rise * look.ring * 2
            opacity: (1 - rise) * look.menu.reveal
            NumberAnimation on rise {
                from: 0
                to: 1
                duration: 1800 + spark.seed * 1600
                loops: Animation.Infinite
                running: look.menu.visible
            }
        }
    }

    // the middle: the (horned) logo; closes
    Rectangle {
        id: hub
        x: look.menu.cx - width / 2
        y: look.menu.cy - height / 2
        width: Math.round(look.slotSize * 1.2)
        height: width
        radius: width / 2
        scale: look.menu.reveal
        color: hubMouse.containsMouse ? "#5a0c16" : look.pit
        border.width: Math.max(1, Theme.u)
        border.color: look.blood
        AngelLogo {
            anchors.centerIn: parent
            emblemOnly: true
            pixel: Math.max(1, Math.round(Theme.u * look.k * 0.75))
        }
        MouseArea {
            id: hubMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
                look.menu.current = -1;
                look.menu.fly = "";
            }
            onClicked: look.menu.close()
        }
    }
    // the hovered entry's full name, burnt above the middle
    Rectangle {
        visible: !!look.menu.hoveredEntry && look.menu.reveal > 0.6
        x: look.menu.cx - width / 2
        y: look.menu.cy - hub.height / 2 - height - Theme.u * 3
        width: hoverName.implicitWidth + Theme.u * 8
        height: hoverName.implicitHeight + Theme.u * 4
        color: look.pit
        border.width: Math.max(1, Theme.u / 2)
        border.color: look.blood
        PxText {
            id: hoverName
            anchors.centerIn: parent
            kind: "tiny"
            font.bold: true
            color: look.bone
            text: look.menu.hoveredEntry ? look.menu.hoveredEntry.label : ""
        }
    }

    // the points and the runes
    Repeater {
        model: look.menu.slots
        Item {
            id: slot
            required property string modelData
            required property int index
            readonly property var e: DeskMenu.entry(modelData)
            readonly property bool ray: index < 5
            readonly property real size: ray ? look.slotSize : look.runeSize
            readonly property real a: look.angleOf(index)
            readonly property bool sel: look.menu.current === index
            readonly property bool open: look.menu.fly === modelData
            // they light up once the stroke has reached them
            readonly property real lit: Math.max(0, Math.min(1, look.menu.reveal * 1.6 - (ray ? index * 0.12 : 0.6)))
            width: size
            height: size + look.labelRoom
            x: look.menu.cx + Math.cos(a) * look.radiusOf(index) - width / 2
            y: look.menu.cy + Math.sin(a) * look.radiusOf(index) - size / 2
            opacity: lit
            Rectangle {
                id: tile
                width: slot.size
                height: slot.size
                radius: slot.ray ? 0 : width / 2
                rotation: slot.ray ? 45 : 0
                scale: slot.sel || slot.open ? 1.15 : 1
                Behavior on scale {
                    NumberAnimation {
                        duration: 90
                    }
                }
                color: slot.sel || slot.open ? "#5a0c16" : look.pit
                border.width: Math.max(1, Theme.u / 2)
                border.color: slot.sel || slot.open ? look.ember : look.blood
            }
            PxIcon {
                anchors.centerIn: tile
                name: slot.e ? slot.e.icon : "heart"
                pixel: Math.max(1, Math.round(Theme.u * look.k * (slot.ray ? 1 : 0.75)))
                ink: look.bone
                fill: look.blood
                fill3: look.ember
                light: look.bone
            }
            // a candle outside each point
            PxIcon {
                visible: slot.ray
                name: "fire"
                pixel: Math.max(1, Math.round(Theme.u * 0.75))
                fill3: "#ffd23f"
                bad: look.ember
                light: "#fff3b0"
                x: tile.width / 2 + Math.cos(slot.a) * (slot.size * 0.95) - width / 2
                y: tile.height / 2 + Math.sin(slot.a) * (slot.size * 0.95) - height / 2 - (candleFlicker.on ? Theme.u / 2 : 0)
                Timer {
                    id: candleFlicker
                    property bool on: false
                    interval: 160 + slot.index * 37
                    repeat: true
                    running: look.menu.visible
                    onTriggered: on = !on
                }
            }
            PxText {
                visible: look.menu.labels
                anchors.horizontalCenter: tile.horizontalCenter
                y: slot.size + Theme.u * (slot.ray ? 3 : 1)
                width: Math.max(slot.size * 1.8, implicitWidth)
                horizontalAlignment: Text.AlignHCenter
                kind: "tiny"
                font.bold: slot.sel
                color: look.bone
                style: Text.Outline
                styleColor: look.pit
                text: slot.e ? (slot.e.short || slot.e.label) : ""
            }
            MouseArea {
                width: slot.size
                height: slot.size
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: look.menu.hoverEntry(slot.index)
                onClicked: look.menu.activate(slot.index)
            }
        }
    }

    FlyColumn {
        menu: look.menu
        hell: true
        radius: look.ring + look.runeSize / 2 + look.labelRoom + Theme.u * 10
        reach: look.reach + Theme.u * 2
        angle: look.angleOf(look.menu.flyIndex)
    }
}
