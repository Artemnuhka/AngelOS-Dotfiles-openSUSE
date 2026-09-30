import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Floating island at the top centre. The surface keeps the screen's width and
// the island grows and shrinks inside it, animated: resizing the layer surface
// on every change of its content went in jerks (issue #14). Input and blur
// only cover the island.
PanelWindow {
    id: win

    required property var modelData
    readonly property bool compact: Config.bar.compactOnVertical && modelData.width < 1300

    screen: modelData
    anchors.top: true
    margins.top: Theme.u * 4
    implicitWidth: modelData.width - Theme.u * 8
    implicitHeight: Theme.u * 20
    mask: Region {
        item: box
    }
    exclusiveZone: implicitHeight + Theme.u * 2
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
        height: parent.height - Theme.u * 2
        color: Theme.panel
        shadow: Config.appearance.shadows
        Behavior on width {
            NumberAnimation {
                duration: Theme.normal
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            width: parent.width
            height: Theme.u * 2
            color: Theme.menuHeader
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

    RightClickGuard {}
}
