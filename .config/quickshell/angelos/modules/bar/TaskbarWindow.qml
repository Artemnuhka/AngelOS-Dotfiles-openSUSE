import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Win98 taskbar at the bottom. Auto-hide (Bar → Auto-hide): the bar slides down
// leaving a thin line at the screen edge, windows get the whole screen; the
// pointer at the bottom edge, Start or a bar menu bring it back.
// In hell (BarLayout.hell): a hot slab of obsidian with lava in its cracks and flames
// licking up along its top edge — above the bar, in headroom that takes no input and
// no room from the windows.
PanelWindow {
    id: win

    required property var modelData
    readonly property bool compact: Config.bar.compactOnVertical && modelData.width < 1300

    readonly property bool autoHide: Config.bar.autoHide
    // what keeps it up: the pointer on it, Start or one of its menus open on this screen
    readonly property bool held: hover.hovered || Shell.startScreen === modelData.name || (PopupManager.active !== null && (!PopupManager.active.outputName || PopupManager.active.outputName === modelData.name)) || PopupManager.registered.some(p => p.visible && p.outputName === modelData.name)
    property bool up: true
    onHeldChanged: {
        if (held) {
            hideLater.stop();
            up = true;
        } else if (autoHide)
            hideLater.restart();
    }
    onAutoHideChanged: {
        if (autoHide && !held)
            hideLater.restart();
        else
            up = true;
    }
    Timer {
        id: hideLater
        interval: Config.bar.autoHideMs
        onTriggered: if (win.autoHide && !win.held)
            win.up = false
    }
    // 0 = shown, 1 = tucked away below the edge
    property real tucked: autoHide && !up ? 1 : 0
    Behavior on tucked {
        NumberAnimation {
            duration: win.tucked < 0.5 ? 160 : 260
            easing.type: Easing.OutCubic
        }
    }
    // the line that stays at the edge while it hides, the pointer finds it there
    readonly property int peek: Math.max(2, Theme.u)

    readonly property bool hell: BarLayout.hell
    readonly property int barHeight: Theme.u * 20
    readonly property int headroom: hell ? Theme.u * 8 : 0

    screen: modelData
    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: barHeight + headroom
    exclusionMode: Shell.dev || autoHide ? ExclusionMode.Ignore : ExclusionMode.Normal
    exclusiveZone: barHeight
    mask: Region {
        item: hot
    }
    Item {
        id: hot
        width: parent.width
        y: Math.min(box.y, win.height - win.peek)
        height: win.height - y
    }
    color: "transparent"
    WlrLayershell.namespace: "angelos-bar"
    WlrLayershell.layer: WlrLayer.Top

    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: box
    }

    // the pointer over the taskbar, in screen coordinates (Pointer: the demon's
    // glass over the Start button clears up as it comes near)
    HoverHandler {
        id: hover
        onPointChanged: if (hovered)
            Pointer.report("bar", win.modelData.name, point.position.x, win.modelData.height - win.height + point.position.y)
        onHoveredChanged: if (!hovered)
            Pointer.left("bar", win.modelData.name)
    }

    PxBox {
        id: box
        width: parent.width
        height: win.barHeight
        y: win.headroom + Math.round(win.tucked * (win.barHeight - win.peek))
        color: win.hell ? "transparent" : Theme.panel
        hell: win.hell
        outline: false

        Rectangle {
            // top highlight line like the original taskbar
            visible: !win.hell
            width: parent.width
            height: Theme.u
            y: -box.inset
            color: Theme.hi
        }
        // hell: the slab under everything, the flames over its top edge
        HellSlab {
            visible: win.hell
            x: -box.inset
            y: -box.inset
            width: box.width
            height: box.height
            look: "lava"
            live: !Shell.fullscreenOn(win.modelData.name)
        }
        HellFlames {
            visible: win.hell
            x: -box.inset
            y: -box.inset - height + Theme.u
            width: box.width
            rows: 8
            seed: 4
            live: !Shell.fullscreenOn(win.modelData.name)
        }

        BarContent {
            anchors.fill: parent
            anchors.leftMargin: Theme.u
            anchors.rightMargin: Theme.u
            screenName: win.modelData.name
            barWindow: win
            style: "taskbar"
            compact: win.compact
            itemHeight: Theme.u * 15
        }
    }

    RightClickGuard {}
}
