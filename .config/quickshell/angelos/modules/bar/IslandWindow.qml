import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Floating island at the top centre.
PanelWindow {
    id: win

    required property var modelData
    readonly property bool compact: Config.bar.compactOnVertical && modelData.width < 1300

    screen: modelData
    anchors.top: true
    margins.top: Theme.u * 4
    implicitWidth: Math.min(modelData.width - Theme.u * 8, row.implicitWidth + Theme.u * 12)
    implicitHeight: Theme.u * 20
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
        width: parent.width - Theme.u * 2
        height: parent.height - Theme.u * 2
        color: Theme.panel
        shadow: Config.appearance.shadows

        Rectangle {
            width: parent.width
            height: Theme.u * 2
            color: Theme.menuHeader
        }

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

    RightClickGuard {}
}
