pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets
import "AngelSprite.js" as Sprite

// The Y2K helper: a pixel angel floating in the bottom-right corner of the
// focused screen (or the one picked in Settings → Y2K). Speech bubble with an
// optional button; a click on her opens a small menu. Stepped animation at
// ~8 fps, so she costs next to nothing while idle.
Scope {
    // created only while she is wanted (no binding on the window's own visible:
    // Quickshell re-applies it when the screen changes, which loops)
    LazyLoader {
        active: Angel.shown && !Shell.bootOpen && Shell.screens.length > 0

        PanelWindow {
            id: win

            readonly property var target: Config.y2k.helperScreen ? Shell.screenByName(Config.y2k.helperScreen) : Shell.focusedScreen
            screen: target || Shell.screens[0] || null
            anchors {
                bottom: true
                right: true
            }
            margins {
                bottom: Theme.u * 4
                right: Theme.u * 6
            }
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 0
            color: "transparent"
            implicitWidth: Theme.u * 160
            implicitHeight: body.height
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "angelos-angel"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            // the bubble's own `visible` follows the window's: the mask uses the state
            readonly property bool bubbleOn: Angel.talking || Angel.menuOpen
            mask: Region {
                item: angel
                Region {
                    item: win.bubbleOn ? bubble : null
                }
            }

            // ---- 8 fps clock: wings, bobbing, blinking, talking ----
            property int tick: 0
            Timer {
                interval: 125
                running: win.visible
                repeat: true
                onTriggered: win.tick++
            }
            readonly property var frame: {
                if (Angel.talking && typer.shown < Angel.text.length && tick % 2 === 0)
                    return Sprite.talk;
                if (tick % 29 === 0)
                    return Sprite.blink;
                return Math.floor(tick / 3) % 2 ? Sprite.down : Sprite.up;
            }
            readonly property int bob: [0, 1, 2, 2, 1, 0, -1, -1][tick % 8]

            Item {
                id: body
                anchors.bottom: parent.bottom
                width: parent.width
                height: angel.height + (win.bubbleOn ? bubble.height + Theme.u * 2 : 0) + Theme.u * 4

                // ---- speech bubble / menu ----
                PxBox {
                    id: bubble
                    visible: win.bubbleOn
                    anchors.right: parent.right
                    anchors.bottom: angel.top
                    anchors.bottomMargin: Theme.u * 2
                    width: Theme.u * 150
                    height: bubbleCol.implicitHeight + Theme.u * 8
                    color: Theme.menuSurface
                    shadow: Config.appearance.shadows

                    Column {
                        id: bubbleCol
                        x: Theme.u * 4
                        y: Theme.u * 4
                        width: parent.width - Theme.u * 8
                        spacing: Theme.u * 3

                        Row {
                            width: parent.width
                            spacing: Theme.u * 2
                            PxText {
                                width: parent.width - closeBtn.width - Theme.u * 2
                                text: Angel.menuOpen ? I18n.t("Чем помочь? ♡", "How can I help? ♡") : Angel.text.slice(0, typer.shown)
                                wrapMode: Text.Wrap
                            }
                            PxButton {
                                id: closeBtn
                                compact: true
                                flat: true
                                icon: "close"
                                onClicked: Angel.hush()
                            }
                        }
                        PxButton {
                            visible: !Angel.menuOpen && !!Angel.action && typer.shown >= Angel.text.length
                            compact: true
                            accent: true
                            icon: "heart"
                            text: Angel.action ? Angel.action.label : ""
                            onClicked: {
                                const a = Angel.action;
                                Angel.hush();
                                if (a)
                                    a.run();
                            }
                        }
                        Flow {
                            visible: Angel.menuOpen
                            width: parent.width
                            spacing: Theme.u * 2
                            PxButton {
                                compact: true
                                icon: "star"
                                text: I18n.t("Совет", "A tip")
                                onClicked: Angel.tip()
                            }
                            PxButton {
                                compact: true
                                icon: "gear"
                                text: I18n.t("Настройки", "Settings")
                                onClicked: {
                                    Angel.hush();
                                    Shell.openSettings();
                                }
                            }
                            PxButton {
                                compact: true
                                icon: "moon"
                                text: I18n.t("Спрячься на час", "Hide for an hour")
                                onClicked: Angel.hide(60)
                            }
                            PxButton {
                                compact: true
                                icon: "close"
                                text: I18n.t("Выключить", "Turn off")
                                onClicked: {
                                    Angel.hush();
                                    Config.y2k.helper = false;
                                }
                            }
                        }
                    }
                }

                // typewriter for the bubble text
                QtObject {
                    id: typer
                    property int shown: 0
                }
                Timer {
                    interval: 30
                    running: Angel.talking && typer.shown < Angel.text.length
                    repeat: true
                    onTriggered: typer.shown = Math.min(Angel.text.length, typer.shown + 2)
                }
                Connections {
                    target: Angel
                    function onTextChanged() {
                        typer.shown = 0;
                    }
                }

                // ---- the angel ----
                Item {
                    id: angel
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: sprite.width
                    height: sprite.height + Theme.u * 4
                    PxIcon {
                        id: sprite
                        y: Theme.u * 2 + win.bob * Math.max(1, Theme.u / 2)
                        bitmap: win.frame
                        pixel: Theme.u * 2
                        body: "#ffd9c7"
                        fill3: Theme.dark ? "#ffe07a" : "#f5c542"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Angel.menuOpen)
                                Angel.hush();
                            else {
                                Angel.talking = false;
                                Angel.menuOpen = true;
                                Sounds.play("angel");
                            }
                        }
                    }
                }
            }
        }
    }
}
