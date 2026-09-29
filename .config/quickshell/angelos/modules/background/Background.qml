pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.modules.desktop

// Two background-layer surfaces per screen:
//   angelos-wallpaper — the picture; niri puts it into the overview backdrop, where
//                       surfaces get NO input at all (layer-rule place-within-backdrop)
//   angelos-desktop   — transparent, on top: right-click menu and desktop widgets
Variants {
    model: Shell.screens

    Scope {
        id: scope
        required property var modelData

        PanelWindow {
            screen: scope.modelData
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
                screenName: scope.modelData.name
            }
        }

        PanelWindow {
            id: win

            readonly property var modelData: scope.modelData
            screen: scope.modelData
            color: "transparent"
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "angelos-desktop"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton | Qt.LeftButton
                onClicked: m => {
                    if (m.button === Qt.RightButton)
                        menu.openAt(m.x, m.y);
                    else {
                        menu.close();
                        DesktopWidgets.editMode = false;
                    }
                }
            }

            // desktop widgets (built-in + plugins), above the click catcher so they get their own input
            Item {
                id: deskArea
                anchors.fill: parent
                Repeater {
                    model: DesktopWidgets.uidsFor(win.modelData.name)
                    DesktopWidgetHost {
                        required property string modelData
                        uid: modelData
                        screenName: win.modelData.name
                        area: deskArea
                    }
                }
            }

            DesktopMenu {
                id: menu
                parentWindow: win
                Component.onCompleted: {
                    const m = Shell.desktopMenus;
                    m[win.modelData.name] = menu;
                    Shell.desktopMenus = m;
                }
            }
        }
    }
}
