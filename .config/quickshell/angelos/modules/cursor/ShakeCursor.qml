pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Shake to find the pointer (services/CursorShake): for a moment a see-through overlay draws
// the theme's arrow bigger at the pointer (crisp pixels), then it shrinks back and goes.
// Only a picture (B3): the real pointer is never moved and clicks reach what is under it.
// niri tells nobody where the pointer is, so the overlay takes input everywhere except a
// small hole around the pointer: under the pointer everything goes through to the apps;
// a stroke out of the hole is one motion event here — the exact spot — and the hole moves
// there. Until the first motion of a shake the overlay doesn't know the spot yet.
Variants {
    model: Shell.screens

    PanelWindow {
        id: win

        required property var modelData
        readonly property var img: CursorShake.image
        // the real arrow's size on screen: the theme's picture drawn at the cursor size
        readonly property real base: img ? Cursors.size / Math.max(1, img.nominal) : Cursors.size / 16
        property real grow: CursorShake.shaking ? CursorShake.zoom : 1
        Behavior on grow {
            NumberAnimation {
                duration: Motion.ms(CursorShake.shaking ? 170 : 240)
                easing.type: CursorShake.shaking ? Easing.OutBack : Easing.InOutQuad
            }
        }

        screen: modelData
        visible: CursorShake.shaking || grow > 1.02
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.namespace: "angelos-cursor"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        // the pointer's last exact spot on this screen during this shake
        property bool known: false
        property real px: 0
        property real py: 0
        readonly property int hole: Math.max(6, Theme.u * 4)
        onVisibleChanged: if (!visible)
            known = false
        mask: Region {
            x: 0
            y: 0
            width: win.width
            height: win.height
            Region {
                intersection: Intersection.Subtract
                x: win.known ? Math.round(win.px) - win.hole : -1
                y: win.known ? Math.round(win.py) - win.hole : -1
                width: win.known ? win.hole * 2 : 0
                height: win.known ? win.hole * 2 : 0
            }
        }

        MouseArea {
            id: catcher
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            function seen(x, y) {
                win.px = x;
                win.py = y;
                win.known = true;
            }
            onPositionChanged: m => seen(m.x, m.y)
            onEntered: seen(mouseX, mouseY)
            // a press can only land here in the frame before the hole caught up: the
            // effect ends at once, nothing stays in the way
            onPressed: m => {
                seen(m.x, m.y);
                CursorShake.dismiss();
            }
        }

        // the theme's arrow, hotspot on the pointer
        Image {
            visible: !!win.img && win.known
            source: win.img ? "file://" + win.img.png : ""
            smooth: false
            mipmap: false
            cache: false
            width: (win.img ? win.img.width : 0) * win.base * win.grow
            height: (win.img ? win.img.height : 0) * win.base * win.grow
            x: win.px - (win.img ? win.img.xhot : 0) * win.base * win.grow
            y: win.py - (win.img ? win.img.yhot : 0) * win.base * win.grow
        }
        // no picture of the theme: the pixel arrow from the icon set
        PxIcon {
            visible: !win.img && win.known
            name: "cursor"
            pixel: Math.max(1, Math.round(win.base * win.grow))
            ink: Theme.edge
            fill: "#ffffff"
            x: win.px
            y: win.py
        }

        RightClickGuard {}
    }
}
