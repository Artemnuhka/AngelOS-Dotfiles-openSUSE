pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Start menu as a layer-shell overlay: opens from the Start button, from a
// Meta tap or over IPC, takes the keyboard and closes on a click outside.
Variants {
    model: Shell.screens

    PanelWindow {
        id: win

        required property var modelData
        readonly property string screenName: modelData.name
        readonly property bool open: Shell.startScreen === screenName
        property bool shown: false

        screen: modelData
        visible: shown
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "angelos-start"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: open ? (Shell.dev ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive) : WlrKeyboardFocus.None

        onOpenChanged: {
            if (open) {
                body.current = -1;
                shown = true;
                popIn.restart();
                Qt.callLater(() => keys.forceActiveFocus());
            } else if (shown) {
                popOut.restart();
            }
        }

        // where the Start button of this screen sits (layer shell does not tell
        // us the bar position, so it is derived from the bar window's anchors)
        readonly property rect button: {
            const b = Shell.startButtons[screenName];
            if (!b || !b.item || !b.window)
                return Qt.rect(Theme.u * 2, height - Theme.u * 20, Theme.u * 40, Theme.u * 18);
            const w = b.window, it = b.item;
            const p = it.mapToItem(w.contentItem, 0, 0);
            const bottom = w.anchors && w.anchors.bottom && !w.anchors.top;
            const wy = bottom ? height - w.height - (w.margins ? w.margins.bottom : 0) : (w.margins ? w.margins.top : 0);
            const wx = w.anchors && w.anchors.left && w.anchors.right ? 0 : (width - w.width) / 2;
            return Qt.rect(wx + p.x, wy + p.y, it.width, it.height);
        }
        readonly property bool above: button.y > height / 2

        mask: Region {
            item: win.open ? catcher : null
        }
        BackgroundEffect.blurRegion: Config.appearance.blur && win.shown ? blurRegion : null
        Region {
            id: blurRegion
            item: body
        }

        MouseArea {
            id: catcher
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: Shell.closeStart()
        }

        Item {
            id: keys
            focus: true
            Keys.onPressed: e => body.key(e)
        }

        StartMenuBody {
            id: body
            x: Math.max(Theme.u * 2, Math.min(win.width - width - Theme.u * 2, win.button.x))
            y: win.above ? win.button.y - height - Theme.u * 2 : win.button.y + win.button.height + Theme.u * 2
            transformOrigin: win.above ? Item.BottomLeft : Item.TopLeft
            onCloseRequested: Shell.closeStart()
            MouseArea {
                anchors.fill: parent
                z: -1
            }
        }

        // stepped "pixel" pop, same rhythm as the workspace popup
        SequentialAnimation {
            id: popIn
            PropertyAction {
                target: body
                property: "opacity"
                value: 1
            }
            PropertyAction {
                target: body
                property: "scale"
                value: 0.7
            }
            PauseAnimation {
                duration: 30
            }
            PropertyAction {
                target: body
                property: "scale"
                value: 0.92
            }
            PauseAnimation {
                duration: 30
            }
            PropertyAction {
                target: body
                property: "scale"
                value: 1.03
            }
            PauseAnimation {
                duration: 40
            }
            PropertyAction {
                target: body
                property: "scale"
                value: 1
            }
        }
        SequentialAnimation {
            id: popOut
            PropertyAction {
                target: body
                property: "scale"
                value: 0.9
            }
            PauseAnimation {
                duration: 30
            }
            PropertyAction {
                target: body
                property: "opacity"
                value: 0.4
            }
            PauseAnimation {
                duration: 30
            }
            ScriptAction {
                script: if (!win.open)
                    win.shown = false
            }
        }
    }
}
