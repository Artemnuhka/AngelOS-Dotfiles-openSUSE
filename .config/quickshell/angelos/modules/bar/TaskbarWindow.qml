import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Win98 taskbar at the bottom.
PanelWindow {
    id: win

    required property var modelData
    readonly property bool compact: Config.bar.compactOnVertical && modelData.width < 1300

    screen: modelData
    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: Theme.u * 20
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
        anchors.fill: parent
        color: Theme.panel
        outline: false

        Rectangle {
            // top highlight line like the original taskbar
            width: parent.width
            height: Theme.u
            y: -box.inset
            color: Theme.hi
        }

        BarContent {
            anchors.fill: parent
            anchors.leftMargin: Theme.u
            anchors.rightMargin: Theme.u
            screenName: win.modelData.name
            barWindow: win
            style: "taskbar"
            compact: win.compact
            itemHeight: Theme.u * 15
        }
    }
}
