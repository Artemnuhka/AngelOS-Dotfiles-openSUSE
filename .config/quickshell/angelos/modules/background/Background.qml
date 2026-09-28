pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Desktop layer per screen: wallpaper, desktop widgets, RMB menu.
Variants {
    model: Shell.screens

    PanelWindow {
        id: win

        required property var modelData
        screen: modelData
        color: Theme.desk
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "angelos-wallpaper"

        WallpaperView {
            anchors.fill: parent
            screenName: win.modelData.name
        }

        // plugin desktop widgets
        Repeater {
            model: Plugins.desktopWidgets
            Loader {
                required property var modelData
                anchors.fill: parent
                Component.onCompleted: setSource(Plugins.url(modelData, modelData.desktopWidget), {
                    "plugin": Plugins.context(modelData),
                    "screenName": win.modelData.name
                })
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton | Qt.LeftButton
            onClicked: m => {
                if (m.button === Qt.RightButton)
                    menu.openAt(m.x, m.y);
                else
                    menu.close();
            }
        }

        DesktopMenu {
            id: menu
            parentWindow: win
        }
    }
}
