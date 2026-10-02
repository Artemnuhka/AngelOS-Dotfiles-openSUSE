pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Windose (Settings → Bar → Style → Windose): the NEEDY GIRL OVERDOSE taskbar along the
// bottom — pastel paper with a little check, a rose and lavender stripe on top, every
// button a pill (the controls inside take the "windose" skin, like Settings' Windose
// skin), a few hearts. In hell (BarLayout.hell) it is Hellose: black with a blood check,
// the content re-inked, blood running down from its top edge.
PanelWindow {
    id: win

    required property var modelData
    readonly property bool compact: Config.bar.compactOnVertical && modelData.width < 1300
    readonly property bool hell: BarLayout.hell
    readonly property bool fxLive: !Shell.fullscreenOn(modelData.name)

    screen: modelData
    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: Theme.u * 20
    exclusionMode: Shell.dev ? ExclusionMode.Ignore : ExclusionMode.Auto
    color: "transparent"
    WlrLayershell.namespace: "angelos-bar"
    WlrLayershell.layer: WlrLayer.Top

    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: paper
    }

    HoverHandler {
        onPointChanged: if (hovered)
            Pointer.report("bar", win.modelData.name, point.position.x, win.modelData.height - win.height + point.position.y)
        onHoveredChanged: if (!hovered)
            Pointer.left("bar", win.modelData.name)
    }

    Item {
        id: paper
        anchors.fill: parent
        // the controls inside are Windose's pills (PxButton, PxBox: Theme.settingsSkinFor)
        readonly property string settingsSkin: "windose"

        Rectangle {
            visible: !win.hell
            anchors.fill: parent
            color: Qt.alpha(Theme.windosePaper, Math.max(0.9, Theme.panelAlpha))
        }
        // the check: 4 art pixels a square, faint
        Image {
            visible: !win.hell
            anchors.fill: parent
            fillMode: Image.Tile
            smooth: false
            opacity: Theme.dark ? 0.16 : 0.22
            readonly property int sq: Theme.u * 4
            sourceSize: Qt.size(sq * 2, sq * 2)
            source: "data:image/svg+xml;utf8," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="' + sq * 2 + '" height="' + sq * 2 + '" shape-rendering="crispEdges"><rect width="' + sq + '" height="' + sq + '" fill="' + Theme.hex(Theme.windoseLavender) + '"/><rect x="' + sq + '" y="' + sq + '" width="' + sq + '" height="' + sq + '" fill="' + Theme.hex(Theme.windoseLavender) + '"/></svg>')
        }
        HellSlab {
            visible: win.hell
            anchors.fill: parent
            look: "blood"
            bevelled: false
            live: false
        }
        // the stripes along the top: rose over lavender (in hell blood over black)
        Rectangle {
            width: parent.width
            height: Theme.u
            color: win.hell ? Theme.hellBlood : Theme.windoseRose
        }
        Rectangle {
            y: Theme.u
            width: parent.width
            height: Theme.u
            color: win.hell ? "#050102" : Theme.windoseLavender
        }
        // hearts here and there along the paper, under the buttons
        Repeater {
            model: win.hell ? [] : [0.31, 0.52, 0.71]
            PxIcon {
                required property var modelData
                x: Math.round(win.width * modelData / Theme.u) * Theme.u
                y: win.height - height - Theme.u * 2
                name: "heartSmall"
                pixel: Theme.u
                fill: Theme.windoseRose
                ink: Theme.windoseLine
                opacity: 0.55
            }
        }
        // Hellose: blood running down from the top, a drop falling off now and then
        property real t: 0
        Timer {
            interval: 125
            repeat: true
            running: win.hell && win.fxLive
            onTriggered: paper.t += 0.125
        }
        Repeater {
            model: win.hell ? [[0.04, 7, 0.0], [0.17, 5, 1.3], [0.29, 9, 0.6], [0.46, 6, 2.1], [0.58, 8, 0.9], [0.69, 4, 1.7], [0.83, 7, 0.3], [0.95, 5, 2.6]] : []
            Item {
                id: drip
                required property var modelData
                // one run takes 4 s: it grows, hangs, the drop falls, it starts again
                readonly property real k: ((paper.t / 4 + modelData[2] / 3) % 1)
                readonly property int len: Math.round(modelData[1] * Math.min(1, k / 0.6))
                x: Math.round(win.width * modelData[0] / Theme.u) * Theme.u
                y: Theme.u * 2
                Rectangle {
                    width: Theme.u
                    height: Theme.u * drip.len
                    color: Theme.hellBlood
                }
                Rectangle {
                    visible: drip.k >= 0.6
                    x: -Theme.u / 2
                    y: Theme.u * (drip.modelData[1] + Math.round((drip.k - 0.6) / 0.4 * (win.height / Theme.u - drip.modelData[1] - 4)))
                    width: Theme.u * 2
                    height: Theme.u * 2
                    color: "#e8404f"
                }
            }
        }

        BarContent {
            anchors.fill: parent
            anchors.topMargin: Theme.u * 2
            anchors.leftMargin: Theme.u * 2
            anchors.rightMargin: Theme.u * 2
            screenName: win.modelData.name
            barWindow: win
            style: "windose"
            compact: win.compact
            itemHeight: Theme.u * 14
        }
    }

    RightClickGuard {}
}
