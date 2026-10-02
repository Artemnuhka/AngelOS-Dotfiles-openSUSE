import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Thin strip at the top. In hell (BarLayout.hell): dark rock with ember veins, stone fangs
// hanging off its lower edge and a few chains swinging between them — below the strip, in
// headroom that takes no input and no room from the windows.
PanelWindow {
    id: win

    required property var modelData
    readonly property bool compact: Config.bar.compactOnVertical && modelData.width < 1300

    readonly property bool hell: BarLayout.hell
    readonly property int barHeight: Theme.u * 16
    readonly property int headroom: hell ? Theme.u * 16 : 0
    readonly property bool fxLive: !Shell.fullscreenOn(modelData.name)

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: barHeight + headroom
    exclusionMode: Shell.dev ? ExclusionMode.Ignore : ExclusionMode.Normal
    exclusiveZone: barHeight
    mask: Region {
        item: strip
    }
    color: "transparent"
    WlrLayershell.namespace: "angelos-bar"
    WlrLayershell.layer: WlrLayer.Top

    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: strip
    }

    // hell: stone fangs along the lower edge, chains between them (drawn once per width)
    Canvas {
        id: fangs
        visible: win.hell
        y: win.barHeight - Theme.u
        width: Math.ceil(win.width / Theme.u)
        height: Math.ceil((win.headroom + Theme.u) / Theme.u)
        scale: Theme.u
        transformOrigin: Item.TopLeft
        smooth: false
        antialiasing: false
        renderTarget: Canvas.Image
        onWidthChanged: requestPaint()
        onVisibleChanged: if (visible)
            requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            let s = 911;
            const rnd = () => {
                s = (s * 16807) % 2147483647;
                return (s - 1) / 2147483646;
            };
            const px = (x, y, c) => {
                ctx.fillStyle = c;
                ctx.fillRect(x, y, 1, 1);
            };
            let x = 2 + Math.floor(rnd() * 4);
            while (x < width - 4) {
                const w = 3 + Math.floor(rnd() * 4);          // half-width at the root
                const len = 3 + Math.floor(rnd() * Math.min(9, height - 3));
                for (let r = 0; r < len; r++) {
                    const half = Math.max(0, Math.round(w * (1 - r / len)));
                    for (let i = -half; i <= half; i++) {
                        const edge = i === -half || i === half || r === len - 1;
                        px(x + i, r, edge ? "#0a0204" : i < 0 ? "#3a2427" : "#22141a");
                    }
                }
                // a drop of blood or a glowing tip now and then
                const tip = rnd();
                if (tip > 0.72)
                    px(x, len, tip > 0.88 ? "#ff6a1a" : "#b3142b");
                x += w * 2 + 2 + Math.floor(rnd() * 9);
            }
        }
    }
    Repeater {
        model: win.hell ? [0.13, 0.37, 0.64, 0.88] : []
        HellChain {
            required property var modelData
            required property int index
            x: Math.round(win.width * modelData / Theme.u) * Theme.u
            y: win.barHeight - Theme.u
            links: 2 + index % 2
            swing: 4
            phase: index * 1.7
        }
    }

    Rectangle {
        id: strip
        width: parent.width
        height: win.barHeight
        color: win.hell ? "transparent" : Theme.panel
        HellSlab {
            visible: win.hell
            anchors.fill: parent
            look: "stone"
            seed: 2
            live: win.fxLive
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: Theme.u
            color: win.hell ? Theme.hellEdge : Theme.dark ? Theme.edge : Theme.lo
        }
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.u
            width: parent.width
            height: Theme.u
            color: win.hell ? Theme.hellBlood : Theme.menuHeader
        }

        BarContent {
            anchors.fill: parent
            anchors.bottomMargin: Theme.u * 2
            screenName: win.modelData.name
            barWindow: win
            style: "top"
            compact: win.compact
            itemHeight: Theme.u * 12
        }
    }

    RightClickGuard {}
}
