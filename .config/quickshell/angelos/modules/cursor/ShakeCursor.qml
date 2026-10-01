pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Shake to find the pointer (services/CursorShake): for a moment a see-through overlay
// takes the pointer on every screen, hides the real arrow and draws the theme's arrow
// bigger at the same spot (crisp pixels), then it shrinks back and the overlay goes.
// A click while it is big only shrinks it; the next click goes through.
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
                duration: CursorShake.shaking ? 170 : 240
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

        MouseArea {
            id: catcher
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            cursorShape: Qt.BlankCursor
            onPressed: CursorShake.dismiss()
        }

        // the theme's arrow, hotspot on the pointer
        Image {
            visible: !!win.img && catcher.containsMouse
            source: win.img ? "file://" + win.img.png : ""
            smooth: false
            mipmap: false
            cache: false
            width: (win.img ? win.img.width : 0) * win.base * win.grow
            height: (win.img ? win.img.height : 0) * win.base * win.grow
            x: catcher.mouseX - (win.img ? win.img.xhot : 0) * win.base * win.grow
            y: catcher.mouseY - (win.img ? win.img.yhot : 0) * win.base * win.grow
        }
        // no picture of the theme: the pixel arrow from the icon set
        PxIcon {
            visible: !win.img && catcher.containsMouse
            name: "cursor"
            pixel: Math.max(1, Math.round(win.base * win.grow))
            ink: Theme.edge
            fill: "#ffffff"
            x: catcher.mouseX
            y: catcher.mouseY
        }

        RightClickGuard {}
    }
}
