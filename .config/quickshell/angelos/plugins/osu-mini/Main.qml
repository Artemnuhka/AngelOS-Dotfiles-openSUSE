import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

// The game window, opened from Start, the launcher, the desktop menu or IPC.
Item {
    id: root
    property var plugin
    signal demoRequested

    IpcHandler {
        target: "osu"
        function start(): void {
            Shell.gameOpen = true;
        }
        function stop(): void {
            Shell.gameOpen = false;
        }
        // the game plays itself
        function demo(): void {
            Shell.gameOpen = true;
            Qt.callLater(() => root.demoRequested());
        }
    }

    LazyLoader {
        active: Shell.gameOpen && !!root.plugin
        FloatingWindow {
            id: win
            title: Shell.appTitle + " · osu!mini"
            visible: true
            implicitWidth: 1000
            implicitHeight: 680
            minimumSize: Qt.size(640, 460)
            color: Theme.desk
            onClosed: Shell.gameOpen = false
            onVisibleChanged: if (!visible)
                Shell.gameOpen = false

            Game {
                id: game
                anchors.fill: parent
                Connections {
                    target: root
                    function onDemoRequested() {
                        game.start(true);
                    }
                }
                plugin: root.plugin
                onQuitRequested: Shell.gameOpen = false
            }
        }
    }
}
