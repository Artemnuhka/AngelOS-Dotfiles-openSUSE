pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// The demon punched the desktop: pixel cracks spread from a corner of her screen. They lie
// on the desktop, under the windows (WlrLayer.Bottom), in the corner where they cover
// nothing you use — not the bar, not a desktop widget, not her — and never take the
// pointer; the nearer it comes, the clearer they get (Pointer, reported by the desktop). When the
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
        running: root.wanted && root.kind !== "glass" && !Motion.still
        interval: 100
        repeat: true
        onTriggered: root.clock = (root.clock + 0.1) % 1000
    }
    // the corner: tl | tr | bl | br — the one whose square overlaps the least of the bar,
    // the desktop widgets and her (ties go in this order)
    readonly property string corner: {
        const scr = Shell.screenByName(screenName);
        if (!scr)
            return "tl";
        const W = scr.width, H = scr.height;
        const side = Math.round(Math.min(W, H) * (weak ? 0.24 : 0.36));
        const bar = Theme.u * 24;
        const busy = [];
        busy.push(BarLayout.bottom ? [0, H - bar, W, bar] : [0, 0, W, bar]);
        if (Angel.screenName === screenName)
            busy.push([W - Theme.u * 176, H - Theme.u * 160, Theme.u * 176, Theme.u * 160]);
        const faces = DesktopWidgets.faces;
        for (const w of DesktopWidgets.widgets) {
            const f = faces[w.uid];
            if (f && DesktopWidgets.screenOf(w) === screenName && f.width > 0)
                busy.push([f.x, f.y, f.width, f.height]);
        }
        const overlap = (a, b) => Math.max(0, Math.min(a[0] + a[2], b[0] + b[2]) - Math.max(a[0], b[0])) * Math.max(0, Math.min(a[1] + a[3], b[1] + b[3]) - Math.max(a[1], b[1]));
        let best = "tl", bestArea = Infinity;
        for (const c of ["tl", "tr", "bl", "br"]) {
            const top = c[0] === "t", leftSide = c[1] === "l";
            const y = top ? (BarLayout.bottom ? 0 : bar) : H - side - (BarLayout.bottom ? bar : 0);
            const sq = [leftSide ? 0 : W - side, y, side, side];
            const area = busy.reduce((sum, b) => sum + overlap(sq, b), 0);
            if (area < bestArea) {
                bestArea = area;
                best = c;
            }
        }
        return best;
    }
    readonly property bool atTop: corner[0] === "t"
    readonly property bool atLeft: corner[1] === "l"
    // where her fist landed in that square: near the screen's corner
    readonly property point impact: Qt.point(atLeft ? 0.14 : 0.86, atTop ? 0.08 : 0.92)
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
                top: root.atTop
                bottom: !root.atTop
                left: root.atLeft
                right: !root.atLeft
            }
            // off the bar's edge (the exclusive zone keeps it clear anyway; Ignore here so the
            // square stays where it was put)
            readonly property int bar: Theme.u * 24
            margins {
                top: root.atTop && !BarLayout.bottom ? win.bar : 0
                bottom: !root.atTop && BarLayout.bottom ? win.bar : 0
            }
            readonly property int side: Math.round((screen ? Math.min(screen.width, screen.height) : 800) * (root.weak ? 0.24 : 0.36))
            implicitWidth: side
            implicitHeight: side
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "angelos-cracks"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            // the glass never takes the pointer: Start and the desk under it stay clickable
            mask: Region {}

            // 1 far away … 0 on the impact, stepped in eight like everything pixel; the
            // glass keeps a faint 10 % even then
            readonly property real away: {
                if (Pointer.screen !== root.screenName)
                    return 1;
                const sw = screen ? screen.width : side, sh = screen ? screen.height : side;
                const ox = root.atLeft ? 0 : sw - side;
                const oy = root.atTop ? win.margins.top : sh - side - win.margins.bottom;
                const ix = ox + side * root.impact.x, iy = oy + side * root.impact.y;
                const d = Math.hypot(Pointer.x - ix, Pointer.y - iy);
                const near = side * 0.2, far = side * 1.3;
                const k = Math.max(0, Math.min(1, (d - near) / (far - near)));
                return Math.round(k * k * (3 - 2 * k) * 8) / 8;
            }
            property real veil: 0.1 + 0.9 * away
            Behavior on veil {
                NumberAnimation {
                    duration: Motion.ms(110)
                }
            }

            BreakageArt {
                anchors.fill: parent
                kind: root.kind
                grow: root.grow
                fall: root.fall
                seed: root.seed
                weak: root.weak
                impact: root.impact
                clock: root.clock
                veil: win.veil
            }
            RightClickGuard {}
        }
    }
}
