pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Start menu as a layer-shell overlay: opens from the Start button, from a
// Meta tap or over IPC, takes the keyboard and closes on a click outside.
// Three looks (Settings → Bar → Start): classic Win98 list, Windows 11 panel,
// iPhone-like full screen grid. All of them animate through `reveal` (0 → 1).
Variants {
    model: Shell.screens

    PanelWindow {
        id: win

        required property var modelData
        readonly property string screenName: modelData.name
        readonly property bool open: Shell.startScreen === screenName
        readonly property string style: ["classic", "win11", "fullscreen"].includes(Config.bar.startStyle) ? Config.bar.startStyle : "classic"
        readonly property bool full: style === "fullscreen"
        property bool shown: false
        property real reveal: 0

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
                shown = true;
                if (body.item && body.item.reset)
                    body.item.reset();
                if (body.item)
                    body.item.current = -1;
                revealAnim.to = 1;
                revealAnim.duration = win.full ? 340 : 230;
                revealAnim.easing.type = win.full ? Easing.OutQuint : Easing.OutCubic;
                revealAnim.restart();
                Qt.callLater(() => keys.forceActiveFocus());
            } else if (shown) {
                revealAnim.to = 0;
                revealAnim.duration = win.full ? 200 : 140;
                revealAnim.easing.type = Easing.InCubic;
                revealAnim.restart();
            }
        }
        NumberAnimation {
            id: revealAnim
            target: win
            property: "reveal"
            onFinished: if (!win.open)
                win.shown = false
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
            item: win.full ? catcher : body
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
            Keys.onPressed: e => {
                if (body.item)
                    body.item.key(e);
            }
        }

        Loader {
            id: body
            // classic sits at the button; win11 is centred over the bar; fullscreen fills
            readonly property real restY: win.above ? win.button.y - height - Theme.u * 2 : win.button.y + win.button.height + Theme.u * 2
            x: win.full ? 0 : win.style === "win11" ? Math.round((win.width - width) / 2) : Math.max(Theme.u * 2, Math.min(win.width - width - Theme.u * 2, win.button.x))
            y: win.full ? 0 : restY + (win.style === "win11" ? (win.above ? 1 : -1) * (1 - win.reveal) * Theme.u * 24 : 0)
            opacity: win.full ? 1 : win.reveal
            // classic pops out of its corner, win11 slides
            scale: win.style === "classic" ? 0.9 + 0.1 * win.reveal : 1
            transformOrigin: win.above ? Item.BottomLeft : Item.TopLeft
            sourceComponent: win.full ? fullComp : win.style === "win11" ? win11Comp : classicComp
            onLoaded: {
                item.closeRequested.connect(Shell.closeStart);
                if (win.open && item.reset)
                    item.reset();
            }
            MouseArea {
                visible: !win.full
                anchors.fill: parent
                z: -1
            }
        }
        Component {
            id: classicComp
            StartMenuBody {}
        }
        Component {
            id: win11Comp
            StartWin11 {}
        }
        Component {
            id: fullComp
            StartFullscreen {
                reveal: win.reveal
                width: win.width
                height: win.height
            }
        }
    }
}
