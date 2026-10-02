import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Floating island at the top centre. The surface keeps the screen's width and
// the island grows and shrinks inside it, animated: resizing the layer surface
// on every change of its content went in jerks (issue #14). Input and blur
// only cover the island. In hell (BarLayout.hell): a floating chunk of brimstone,
// sulphur in its cracks, with a fire burning under it (headroom below, no input there).
PanelWindow {
    id: win

    required property var modelData
    readonly property bool compact: Config.bar.compactOnVertical && modelData.width < 1300

    screen: modelData
    anchors.top: true
    margins.top: Theme.u * 4
    implicitWidth: modelData.width - Theme.u * 8
    readonly property bool hell: BarLayout.hell
    readonly property int barHeight: Theme.u * 20
    implicitHeight: barHeight + (hell ? Theme.u * 9 : 0)
    mask: Region {
        item: box
    }
    exclusiveZone: barHeight + Theme.u * 2
    exclusionMode: Shell.dev ? ExclusionMode.Ignore : ExclusionMode.Normal
    color: "transparent"
    WlrLayershell.namespace: "angelos-bar"
    WlrLayershell.layer: WlrLayer.Top

    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: box
    }

    PxBox {
        id: box
        readonly property real want: Math.min(win.width - Theme.u * 2, row.implicitWidth + Theme.u * 10)
        width: want
        x: Math.round((win.width - Theme.u * 2 - width) / 2)
        height: win.barHeight - Theme.u * 2
        color: win.hell ? "transparent" : Theme.panel
        hell: win.hell
        shadow: Config.appearance.shadows && !win.hell
        Behavior on width {
            NumberAnimation {
                duration: Theme.normal
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            visible: !win.hell
            width: parent.width
            height: Theme.u * 2
            color: Theme.menuHeader
        }
        HellSlab {
            visible: win.hell
            x: -box.inset
            y: -box.inset
            width: box.width
            height: box.height
            look: "brimstone"
            seed: 7
            live: !Shell.fullscreenOn(win.modelData.name)
        }

        // the content shows through the growing island, not over its edges
        Item {
            anchors.fill: parent
            clip: true
            BarContent {
                id: row
                anchors.centerIn: parent
                anchors.verticalCenterOffset: Theme.u
                screenName: win.modelData.name
                barWindow: win
                style: "island"
                compact: win.compact
                inline: true
                itemHeight: Theme.u * 13
            }
        }
    }

    // the brimstone's underside burning, flames hanging from it, a little narrower than it
    HellFlames {
        visible: win.hell
        width: Math.max(Theme.u * 20, box.width - Theme.u * 16)
        x: box.x + (box.width - width) / 2 + Theme.u
        y: box.y + box.height - Theme.u
        rows: 8
        seed: 9
        down: true
        live: !Shell.fullscreenOn(win.modelData.name)
        z: -1
    }

    RightClickGuard {}
}
