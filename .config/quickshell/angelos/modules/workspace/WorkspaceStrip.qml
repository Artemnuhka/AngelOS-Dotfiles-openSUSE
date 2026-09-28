pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Vertical heart strip on the right edge (niri workspaces are vertical).
PanelWindow {
    id: win

    required property string screenName
    property int serial: 0
    property bool shown: false
    readonly property var list: Niri.workspacesOn(screenName).filter(w => w.name !== "privacy")

    onSerialChanged: {
        if (!Config.workspaces.indicator)
            return;
        shown = true;
        hideTimer.restart();
    }

    visible: shown || slide.running
    anchors.right: true
    implicitWidth: box.width + Theme.u * 8
    implicitHeight: box.height + Theme.u * 6
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "angelos-workspace"
    WlrLayershell.layer: WlrLayer.Overlay

    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: box
    }

    Timer {
        id: hideTimer
        interval: Math.max(400, Config.workspaces.popupMs)
        onTriggered: win.shown = false
    }

    PxBox {
        id: box
        anchors.verticalCenter: parent.verticalCenter
        x: win.shown ? Theme.u * 2 : win.implicitWidth
        width: col.implicitWidth + inset * 2 + Theme.u * 6
        height: col.implicitHeight + inset * 2 + Theme.u * 6
        color: Theme.panel
        shadow: Config.appearance.shadows
        Behavior on x {
            NumberAnimation {
                id: slide
                duration: Theme.normal
                easing.type: Easing.OutBack
            }
        }

        Column {
            id: col
            anchors.centerIn: parent
            spacing: Theme.u * 3
            Repeater {
                model: win.list
                Item {
                    id: cell
                    required property var modelData
                    width: Theme.u * 14
                    height: Theme.u * 12
                    Rectangle {
                        anchors.fill: parent
                        visible: cell.modelData.is_active
                        color: Qt.alpha(Theme.accent, 0.25)
                    }
                    PxIcon {
                        anchors.centerIn: parent
                        name: "heart"
                        hollow: !cell.modelData.is_active && Niri.windowsOn(cell.modelData.id).length === 0
                        fill: cell.modelData.is_active ? Theme.accent : Theme.accent4
                    }
                }
            }
        }
    }
}
