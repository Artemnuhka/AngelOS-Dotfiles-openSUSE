import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Thin strip at the top.
PanelWindow {
    id: win

    required property var modelData
    readonly property bool compact: Config.bar.compactOnVertical && modelData.width < 1300

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.u * 16
    exclusionMode: Shell.dev ? ExclusionMode.Ignore : ExclusionMode.Auto
    color: "transparent"
    WlrLayershell.namespace: "angelos-bar"
    WlrLayershell.layer: WlrLayer.Top

    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: strip
    }

    Rectangle {
        id: strip
        anchors.fill: parent
        color: Theme.panel
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: Theme.u
            color: Theme.dark ? Theme.edge : Theme.lo
        }
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.u
            width: parent.width
            height: Theme.u
            color: Theme.menuHeader
        }

        BarContent {
            anchors.fill: parent
            anchors.bottomMargin: Theme.u * 2
            screenName: win.modelData.name
            barWindow: win
            style: "top"
            compact: win.compact
            itemHeight: Theme.u * 12
        }
    }

    RightClickGuard {}
}
