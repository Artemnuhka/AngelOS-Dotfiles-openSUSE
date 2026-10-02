pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// The demon punched the screen: pixel cracks spread from the Start button in
// the bottom-left corner of her screen (over the bar). The glass stays while
// she rules and never takes the pointer: the nearer the pointer comes, the
// clearer it gets (Pointer — reported by the desktop and the taskbar). When the
// angel comes back the glass breaks and the shards fall out (Angel.shattered).
// Settings → Y2K → Angel or demon: cracks full | weak | off, and what she breaks
// (Config.y2k.breakage): glass (these pixel cracks) | tv (a smashed TV: a hole with snow
// and dead LCD lines) | burn (a hole burnt through, hellfire inside) | claws (four glowing
// gashes) | sigil (a pentagram burnt into the glass) | random (another one each punch) —
// all but the glass drawn by shaders/breakage.frag. Hidden under fullscreen windows and
// on streamed screens.
Scope {
    id: root

    property string screenName: ""
    property bool on: false                  // cracks on the glass
    property bool falling: false             // the angel is back: shards drop out
    property real grow: 0                    // 0..1 how far the cracks have spread
    property real fall: 0                    // 0..1 of the drop
    property int seed: 1
    readonly property bool weak: Config.y2k.cracks === "weak"
    // what this punch broke: glass | tv | burn | claws | sigil
    readonly property var kinds: ["glass", "tv", "burn", "claws", "sigil"]
    property string kind: "glass"
    function pickKind() {
        const b = Config.y2k.breakage;
        if (b === "random") {
            const others = kinds.filter(k => k !== kind);
            return others[Math.floor(Math.random() * others.length)];
        }
        return kinds.includes(b) ? b : "glass";
    }
    // a new choice in the settings shows at once
    Connections {
        target: Config.y2k
        function onBreakageChanged() {
            if (root.on && !root.falling && Config.y2k.breakage !== "random")
                root.kind = root.pickKind();
        }
    }
    // the shader's clock, stepped in its own way (10 fps inside)
    property real clock: 0
    Timer {
        running: root.wanted && root.kind !== "glass"
        interval: 100
        repeat: true
        onTriggered: root.clock = (root.clock + 0.1) % 1000
    }
    // where her fist landed, in the corner square: on the Start button
    readonly property point impact: Qt.point(0.14, 0.92)
    readonly property bool wanted: on && Config.y2k.cracks !== "off" && screenName !== "" && StreamMode.effectsOn(screenName) && !Shell.fullscreenOn(screenName) && !Shell.locked

    Connections {
        target: Angel
        function onPunched(name, sound) {
            root.screenName = name;
            root.seed = Math.floor(Math.random() * 100000) + 1;
            root.kind = root.pickKind();
            root.falling = false;
            root.fall = 0;
            root.grow = 0;
            root.on = true;
            anim.restart();
            if (sound)
                Sounds.play(sound);
        }
        function onShattered(name) {
            root.shatter();
        }
        // the character changed some other way (settings): the glass goes with her
        function onDemonChanged() {
            if (!Angel.demon && !Angel.transition)
                root.on = false;
        }
        // the angel is back but the glass could not fall out where she is (stream mode, a
        // fullscreen game): it must not stay in heaven
        function onTransitionChanged() {
            if (!Angel.transition && !Angel.demon)
                leftover.restart();
        }
    }
    Timer {
        id: leftover
        interval: 1600
        onTriggered: if (root.on && !root.falling && !Angel.demon)
            root.on = false
    }
    function shatter() {
        if (!on || falling)
            return;
        falling = true;
        anim.restart();
    }
    // stepped like everything pixel: 12 fps
    Timer {
        id: anim
        interval: 83
        repeat: true
        onTriggered: {
            if (root.falling) {
                root.fall = Math.min(1, root.fall + interval / 450);
                if (root.fall >= 1) {
                    stop();
                    root.on = false;
                    root.falling = false;
                }
            } else {
                root.grow = Math.min(1, root.grow + interval / 500);
                if (root.grow >= 1)
                    stop();
            }
        }
    }

    LazyLoader {
        active: root.wanted && !!Shell.screenByName(root.screenName)

        PanelWindow {
            id: win
            screen: Shell.screenByName(root.screenName)
            anchors {
                bottom: true
                left: true
            }
            readonly property int side: Math.round((screen ? Math.min(screen.width, screen.height) : 800) * (root.weak ? 0.24 : 0.36))
            implicitWidth: side
            implicitHeight: side
            // right in the corner, over the bar: she hit the Start button
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "angelos-cracks"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            // the glass never takes the pointer: Start and the desk under it stay clickable
            mask: Region {}

            // 1 far away … 0 on the impact, stepped in eight like everything pixel; the
            // glass keeps a faint 10 % even then
            readonly property real away: {
                if (Pointer.screen !== root.screenName)
                    return 1;
                const s = screen ? screen.height : side;
                const ix = side * root.impact.x, iy = s - side + side * root.impact.y;
                const d = Math.hypot(Pointer.x - ix, Pointer.y - iy);
                const near = side * 0.2, far = side * 1.3;
                const k = Math.max(0, Math.min(1, (d - near) / (far - near)));
                return Math.round(k * k * (3 - 2 * k) * 8) / 8;
            }
            property real veil: 0.1 + 0.9 * away
            Behavior on veil {
                NumberAnimation {
                    duration: 110
                }
            }

            readonly property int px: Math.max(2, Theme.u * 2)
            // everything but the glass: a hole in a TV, a burnt hole, claws, a sigil
            ShaderEffect {
                visible: root.kind !== "glass"
                anchors.fill: parent
                opacity: (root.weak ? 0.75 : 1) * win.veil
                fragmentShader: Qt.resolvedUrl("../../shaders/breakage.frag.qsb")
                property real kind: root.kinds.indexOf(root.kind)
                property real cells: win.width / win.px
                property real t: root.clock
                property real grow: root.grow
                property real fall: root.fall
                property real seed: root.seed % 997
                property real weak: root.weak ? 1 : 0
                property real ix: root.impact.x
                property real iy: root.impact.y
            }
            Canvas {
                id: canvas
                visible: root.kind === "glass"
                width: Math.ceil(win.width / win.px)
                height: Math.ceil(win.height / win.px)
                scale: win.px
                transformOrigin: Item.TopLeft
                smooth: false
                antialiasing: false
                renderTarget: Canvas.Image
                opacity: (root.weak ? 0.55 : 0.9) * win.veil * (1 - root.fall)
                y: root.fall * root.fall * win.height * 0.35

                // the crack pattern for this punch: rays from the impact, a few
                // branches and two broken rings, each segment with the moment it appears
                readonly property var segments: {
                    let s = root.seed;
                    const rnd = () => {
                        s = (s * 16807) % 2147483647;
                        return (s - 1) / 2147483646;
                    };
                    const W = width, H = height;
                    const cx = Math.round(W * root.impact.x), cy = Math.round(H * root.impact.y);
                    const maxR = Math.hypot(W, H) * 0.75;
                    const out = [];
                    const rays = [];
                    const n = root.weak ? 6 : 9;
                    for (let i = 0; i < n; i++) {
                        let a = -Math.PI * 0.95 + (i + rnd() * 0.6) / n * Math.PI * 1.9;
                        let x = cx, y = cy, r = 0;
                        const len = maxR * (0.45 + rnd() * 0.55);
                        const pts = [[x, y]];
                        while (r < len) {
                            a += (rnd() - 0.5) * 0.7;
                            const step = 2 + rnd() * 4;
                            const nx = x + Math.cos(a) * step, ny = y + Math.sin(a) * step;
                            out.push([x, y, nx, ny, r / maxR]);
                            if (rnd() < 0.18) {
                                // a short branch
                                let ba = a + (rnd() < 0.5 ? -1 : 1) * (0.5 + rnd() * 0.6), bx = nx, by = ny;
                                for (let k = 0; k < 3 + rnd() * 4; k++) {
                                    const bnx = bx + Math.cos(ba) * 3, bny = by + Math.sin(ba) * 3;
                                    out.push([bx, by, bnx, bny, (r + k * 3) / maxR]);
                                    bx = bnx;
                                    by = bny;
                                    ba += (rnd() - 0.5) * 0.6;
                                }
                            }
                            x = nx;
                            y = ny;
                            r = Math.hypot(x - cx, y - cy);
                            pts.push([x, y]);
                        }
                        rays.push(pts);
                    }
                    // spider-web rings: join the rays where they cross two radii
                    for (const ring of [0.1, 0.24]) {
                        const R = maxR * ring;
                        const hits = rays.map(p => p.find(q => Math.hypot(q[0] - cx, q[1] - cy) >= R)).filter(q => !!q);
                        for (let i = 0; i + 1 < hits.length; i++)
                            if (rnd() < 0.8)
                                out.push([hits[i][0], hits[i][1], hits[i + 1][0], hits[i + 1][1], ring + 0.05]);
                    }
                    return out;
                }
                readonly property int step: Math.floor(root.grow * 12)
                onStepChanged: requestPaint()
                onSegmentsChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    const g = root.grow;
                    // pixel lines (Bresenham): a dark edge under a bright one
                    const line = (x0, y0, x1, y1, style, dx, dy) => {
                        ctx.fillStyle = style;
                        x0 = Math.round(x0);
                        y0 = Math.round(y0);
                        x1 = Math.round(x1);
                        y1 = Math.round(y1);
                        const sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1;
                        const ax = Math.abs(x1 - x0), ay = -Math.abs(y1 - y0);
                        let err = ax + ay;
                        for (let guard = 0; guard < 64; guard++) {
                            ctx.fillRect(x0 + dx, y0 + dy, 1, 1);
                            if (x0 === x1 && y0 === y1)
                                break;
                            const e2 = 2 * err;
                            if (e2 >= ay) {
                                err += ay;
                                x0 += sx;
                            }
                            if (e2 <= ax) {
                                err += ax;
                                y0 += sy;
                            }
                        }
                    };
                    for (const s of segments)
                        if (s[4] <= g)
                            line(s[0], s[1], s[2], s[3], Qt.rgba(0.05, 0.02, 0.06, 0.55), 1, 1);
                    for (const s of segments)
                        if (s[4] <= g)
                            line(s[0], s[1], s[2], s[3], Qt.rgba(1, 1, 1, 0.85), 0, 0);
                    // the impact: crushed glass
                    const cx = Math.round(width * root.impact.x), cy = Math.round(height * root.impact.y);
                    ctx.fillStyle = Qt.rgba(1, 1, 1, 0.9);
                    for (const d of [[0, 0], [1, 0], [0, 1], [-1, 0], [0, -1], [2, -1], [-1, 2], [1, 1], [-2, -1]])
                        ctx.fillRect(cx + d[0], cy + d[1], 1, 1);
                }
            }
            RightClickGuard {}
        }
    }
}
