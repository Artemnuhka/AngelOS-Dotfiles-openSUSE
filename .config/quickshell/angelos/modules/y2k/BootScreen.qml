pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Y2K loading screen, like a CD-ROM game from 2000: spinning disc, "insert
// disc 1", a chunky progress bar and the startup chime. Once per login (a
// marker in $XDG_RUNTIME_DIR, so crash restarts and `angelos restart` skip it),
// on the screens picked in Settings → Y2K. A click skips it.
Scope {
    id: root

    property bool firstStart: false
    property real p: 0                       // 0..1 through the show
    readonly property int step: Math.floor(p * 36)   // stepped, like the old installers

    function maybeStart() {
        if (firstStart && Config.ready && Config.y2k.boot && !Shell.dev)
            Shell.bootOpen = true;
    }
    function finish() {
        run.stop();
        Shell.bootOpen = false;
    }

    Process {
        running: true
        command: ["sh", "-c", 'm="${XDG_RUNTIME_DIR:-/tmp}/angelos-booted"; [ -e "$m" ] && exit 1; : > "$m"']
        onExited: code => {
            root.firstStart = code === 0;
            root.maybeStart();
        }
    }
    Connections {
        target: Config
        function onReadyChanged() {
            root.maybeStart();
        }
    }
    Connections {
        target: Shell
        function onBootOpenChanged() {
            if (!Shell.bootOpen)
                return;
            root.p = 0;
            run.restart();
            Sounds.play("startup");
        }
    }
    NumberAnimation {
        id: run
        target: root
        property: "p"
        from: 0
        to: 1
        duration: 3400
        onFinished: root.finish()
    }

    Variants {
        // streamed screens are skipped while stream mode is on
        model: Shell.bootOpen ? Shell.screens.filter(s => (!(Config.y2k.bootScreens || []).length || Config.y2k.bootScreens.includes(s.name)) && StreamMode.effectsOn(s.name)) : []

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "#0c0710"
            WlrLayershell.layer: WlrLayer.Overlay
            // takes input: the boot screen: a click skips it
            WlrLayershell.namespace: "angelos-boot"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            // fade out at the very end
            Item {
                anchors.fill: parent
                opacity: root.p < 0.9 ? 1 : Math.max(0, 1 - (root.p - 0.9) * 10)

                // CRT scanlines
                Image {
                    anchors.fill: parent
                    fillMode: Image.Tile
                    smooth: false
                    opacity: 0.35
                    source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='4' height='" + Theme.u * 3 + "'><rect width='4' height='" + Theme.u + "' fill='black'/></svg>"
                }
                // glow behind the disc
                Rectangle {
                    anchors.centerIn: disc
                    width: disc.width * 1.9
                    height: width
                    radius: width / 2
                    color: Qt.alpha(Theme.accent, 0.12)
                }

                // the spinning CD
                Item {
                    id: disc
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.verticalCenter
                    anchors.bottomMargin: Theme.u * 10
                    width: Math.round(Math.min(win.width, win.height) * 0.22)
                    height: width
                    rotation: root.step * 40
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "#d9d6e4"
                        border.width: Theme.u
                        border.color: Theme.edge
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop {
                                position: 0.0
                                color: "#cfd8ee"
                            }
                            GradientStop {
                                position: 0.35
                                color: Theme.mix(Theme.accent, "#ffffff", 0.35)
                            }
                            GradientStop {
                                position: 0.5
                                color: "#fff6c9"
                            }
                            GradientStop {
                                position: 0.65
                                color: Theme.mix(Theme.accent2, "#ffffff", 0.3)
                            }
                            GradientStop {
                                position: 1.0
                                color: "#d8d0ee"
                            }
                        }
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * 0.34
                        height: width
                        radius: width / 2
                        color: "#b8b3c8"
                        border.width: Theme.u
                        border.color: Theme.edge
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width * 0.12
                        height: width
                        radius: width / 2
                        color: "#0c0710"
                    }
                    PxIcon {
                        x: parent.width * 0.62
                        y: parent.height * 0.18
                        name: "heart"
                        pixel: Theme.u
                    }
                }

                Column {
                    anchors.top: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.u * 6
                    width: Math.min(win.width * 0.7, Theme.u * 300)

                    AngelLogo {
                        anchors.horizontalCenter: parent.horizontalCenter
                        pixel: Theme.u * 3
                        fontSize: Math.round(Theme.sizeHuge * 1.6)
                    }
                    PxText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#ffffff"
                        kind: "big"
                        text: root.p < 0.22 ? I18n.t("Вставьте диск 1…", "Please insert disc 1…") : root.p < 0.85 ? I18n.t("Читаю диск ANGEL (D:)…", "Reading disc ANGEL (D:)…") : I18n.t("Готово ♡", "Ready ♡")
                    }
                    // chunky progress bar
                    Rectangle {
                        width: parent.width
                        height: Theme.u * 16
                        color: "#1c1222"
                        border.width: Theme.u
                        border.color: "#d9d6e4"
                        Row {
                            x: Theme.u * 3
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.u * 2
                            Repeater {
                                model: 20
                                Rectangle {
                                    required property int index
                                    width: (parent.parent.width - Theme.u * 6 - 19 * Theme.u * 2) / 20
                                    height: Theme.u * 10
                                    visible: index < Math.floor(Math.max(0, root.p - 0.22) / 0.63 * 20)
                                    color: index % 2 ? Theme.accent : Theme.mix(Theme.accent, "#ffffff", 0.35)
                                }
                            }
                        }
                    }
                    PxText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#b8b3c8"
                        kind: "body"
                        text: Math.min(100, Math.round(Math.max(0, root.p - 0.22) / 0.63 * 100)) + "%  ·  " + I18n.t("клик — пропустить", "click to skip")
                    }
                }
                PxText {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.u * 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#6f6680"
                    kind: "tiny"
                    text: "© 2000 angelOS ♡ best viewed in 800×600"
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.finish()
            }
            RightClickGuard {}
        }
    }
}
