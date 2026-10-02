pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Capsules (Settings → Bar → Style → Capsules): three floating pills at the top — the
// left, the centre and the right of the bar, each as wide as it needs (BarContent "capsules"
// lays the sections out, this draws a capsule behind each and takes input only there).
// In hell (BarLayout.hell): three tombstones hanging on chains from the screen's top edge,
// swaying a little, runes cut along their rims.
PanelWindow {
    id: win

    required property var modelData
    readonly property bool compact: Config.bar.compactOnVertical && modelData.width < 1300
    readonly property bool hell: BarLayout.hell
    readonly property int capHeight: Theme.u * 15
    readonly property int drop: hell ? Theme.u * 10 : Theme.u * 3       // from the screen's edge to a capsule
    readonly property int pad: Theme.u * 5                              // a capsule around its section
    readonly property bool fxLive: !Shell.fullscreenOn(modelData.name)

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: drop + capHeight + Theme.u * 3
    exclusionMode: Shell.dev ? ExclusionMode.Ignore : ExclusionMode.Normal
    exclusiveZone: implicitHeight
    color: "transparent"
    WlrLayershell.namespace: "angelos-bar"
    WlrLayershell.layer: WlrLayer.Top

    // input (and blur) only on the capsules
    mask: Region {
        item: win.cap0
        Region {
            item: win.cap1
        }
        Region {
            item: win.cap2
        }
    }
    BackgroundEffect.blurRegion: Config.appearance.blur && !win.hell ? blurRegion : null
    Region {
        id: blurRegion
        item: win.cap0
        Region {
            item: win.cap1
        }
        Region {
            item: win.cap2
        }
    }

    // the sway of the tombstones: a pixel either way, all together
    property real t: 0
    Timer {
        interval: 160
        repeat: true
        running: win.hell && win.fxLive
        onTriggered: win.t += 0.16
    }
    readonly property real sway: hell ? Math.round(Math.sin(t * 1.3)) * Theme.u : 0

    // the three capsules: where BarContent put the sections, a pad around them
    property Item cap0: null
    property Item cap1: null
    property Item cap2: null
    Repeater {
        model: 3
        onItemAdded: (i, it) => {
            if (i === 0)
                win.cap0 = it;
            else if (i === 1)
                win.cap1 = it;
            else
                win.cap2 = it;
        }
        Item {
            id: cap
            required property int index
            readonly property var sec: index === 0 ? content.leftBox : index === 1 ? content.centerBox : content.rightBox
            readonly property bool used: sec && sec.visible && sec.implicitWidth > 0
            visible: used
            x: content.x + (sec ? sec.x : 0) - win.pad
            y: win.drop
            width: used ? sec.width + win.pad * 2 : 0
            height: win.capHeight

            // heaven: a pill with a hard pixel shadow (no antialiasing: stepped pixel ends)
            Rectangle {
                visible: !win.hell && Config.appearance.shadows
                x: Theme.u * 2
                y: Theme.u * 2
                width: parent.width
                height: parent.height
                radius: height / 2
                antialiasing: false
                color: Qt.alpha("#000000", 0.35)
            }
            Rectangle {
                visible: !win.hell
                anchors.fill: parent
                radius: height / 2
                antialiasing: false
                color: Theme.panel
                border.width: Theme.u
                border.color: Theme.edge
                Rectangle {
                    x: parent.radius * 0.6
                    y: Theme.u * 2
                    width: parent.width - parent.radius * 1.2
                    height: Theme.u
                    color: Qt.alpha(Theme.hi, 0.8)
                }
            }

            // hell: a tombstone on two chains
            Item {
                visible: win.hell
                width: parent.width
                height: parent.height
                x: win.sway
                Repeater {
                    model: [Theme.u * 6, cap.width - Theme.u * 11]
                    HellChain {
                        required property var modelData
                        x: modelData
                        y: -win.drop
                        links: Math.max(1, Math.ceil(win.drop / (Theme.u * 7)))
                        rotation: -win.sway / Theme.u * 3
                    }
                }
                Canvas {
                    id: tomb
                    width: Math.ceil(parent.width / Theme.u)
                    height: Math.ceil(parent.height / Theme.u)
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
                        const W = width, H = height;
                        let s = 4241 + cap.index * 977;
                        const rnd = () => {
                            s = (s * 16807) % 2147483647;
                            return (s - 1) / 2147483646;
                        };
                        const px = (x, y, c) => {
                            ctx.fillStyle = c;
                            ctx.fillRect(x, y, 1, 1);
                        };
                        // the arch: the top corners cut round
                        const cut = y => y === 0 ? 3 : y === 1 ? 2 : y === 2 ? 1 : 0;
                        for (let y = 0; y < H; y++)
                            for (let x = cut(y); x < W - cut(y); x++) {
                                const edge = y === 0 || y === H - 1 || x === cut(y) || x === W - 1 - cut(y);
                                const g = rnd();
                                const c = edge ? "#141014" : y === 1 || x === cut(y) + 1 ? "#77727a" : y >= H - 2 ? "#2c282e" : g < 0.12 ? "#4c4850" : g > 0.9 ? "#6a656e" : "#5b5760";
                                px(x, y, c);
                            }
                        // hairline cracks
                        for (let k = 0; k < Math.max(2, W / 30); k++) {
                            let x = 4 + Math.floor(rnd() * (W - 8)), y = 2 + Math.floor(rnd() * (H - 4));
                            for (let n = 0; n < 4 + rnd() * 5; n++) {
                                px(x, y, "#262228");
                                x += rnd() < 0.5 ? 1 : -1;
                                y += rnd() < 0.6 ? 1 : 0;
                                if (y >= H - 2)
                                    break;
                            }
                        }
                        // runes cut along the top rim, glowing faintly red
                        const runes = [["#.#", "##.", "#.#"], [".#.", "###", ".#."], ["##.", "#.#", "##."], ["#.#", ".#.", "#.#"], ["###", "..#", "###"], ["#..", "###", "..#"]];
                        for (let x = 6, i = 0; x < W - 8; x += 7, i++) {
                            const r = runes[(i + cap.index * 2) % runes.length];
                            for (let yy = 0; yy < 3; yy++)
                                for (let xx = 0; xx < 3; xx++)
                                    if (r[yy][xx] === "#")
                                        px(x + xx, H - 5 + yy, i % 3 === 0 ? "#b3142b" : "#3a1418");
                        }
                    }
                }
            }
        }
    }

    BarContent {
        id: content
        anchors.fill: parent
        anchors.leftMargin: Theme.u * 6
        anchors.rightMargin: Theme.u * 6
        anchors.topMargin: win.drop
        anchors.bottomMargin: win.height - win.drop - win.capHeight
        screenName: win.modelData.name
        barWindow: win
        style: "capsules"
        compact: win.compact
        itemHeight: Theme.u * 12
    }

    RightClickGuard {}
}
