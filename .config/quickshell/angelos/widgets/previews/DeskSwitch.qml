pragma ComponentBehavior: Bound

import QtQuick
import qs.config

// Workspace switch transitions (services/WorkspaceAnim): soft | dash | dissolve |
// heart | ender | instant. Two little desks drawn as a grid of art pixels; each
// cell shows the old or the new desk depending on the style.
Scene {
    id: root

    readonly property int cols: 28
    readonly property int rows: 16
    readonly property real k: seg(0.2, 0.75)          // 0..1 through the switch
    readonly property real cw: width / cols
    readonly property real ch: height / rows
    readonly property color deskA: Theme.mix(Theme.desk, Theme.accent, 0.25)
    readonly property color deskB: Theme.mix(Theme.desk, Theme.accent2, 0.3)

    // what each desk shows at (u, v) in 0..1
    function old(u, v) {
        if (u > 0.12 && u < 0.62 && v > 0.18 && v < 0.82)
            return v < 0.28 ? Theme.title1 : Theme.face;
        return deskA;
    }
    function neu(u, v) {
        if (u > 0.5 && u < 0.9 && v > 0.12 && v < 0.52)
            return v < 0.21 ? Theme.title2 : Theme.face;
        if (u > 0.08 && u < 0.44 && v > 0.48 && v < 0.9)
            return v < 0.57 ? Theme.title1 : Theme.faceAlt;
        return deskB;
    }
    function hash(i, j) {
        const s = Math.sin(i * 127.1 + j * 311.7) * 43758.5453;
        return s - Math.floor(s);
    }
    function heart(u, v, r) {
        const x = (u - 0.5) / Math.max(0.001, r) * 1.6;
        const y = (0.45 - v) / Math.max(0.001, r) * 1.8 + 0.25;
        return Math.pow(x * x + y * y - 1, 3) - x * x * y * y * y <= 0;
    }
    // the "heart" style takes the desk sprite's shape (Config.workspaces.sprite)
    function star(u, v, r) {
        const x = Math.abs((u - 0.5) / Math.max(0.001, r) * 1.6), y = Math.abs((v - 0.5) / Math.max(0.001, r) * 0.9);
        return Math.sqrt(x) + Math.sqrt(y) <= 1;
    }
    function disc(u, v, r) {
        const d = Math.hypot((u - 0.5) * 1.78, v - 0.5) / Math.max(0.001, r);
        return d <= 0.9 && d >= 0.2 * (1 - k);
    }
    function shape(u, v, r) {
        const sp = Config.workspaces.sprite;
        return sp === "star" ? star(u, v, r * 1.6) : sp === "cd" ? disc(u, v, r) : heart(u, v, r);
    }
    function cell(i, j) {
        const u = (i + 0.5) / cols, v = (j + 0.5) / rows;
        const p = steps(k, 10);
        switch (variant) {
        case "dash":
        case "soft":
        case "":
            {
                // niri's vertical slide: the old desk leaves upwards
                const e = variant === "dash" ? (p < 0.4 ? p * 0.25 : 0.1 + (p - 0.4) / 0.6 * 0.9) : ease(p);
                const vv = v + e;
                return vv < 1 ? old(u, vv) : neu(u, vv - 1);
            }
        case "dissolve":
            return hash(i, j) < p ? neu(u, v) : old(u, v);
        case "heart":
            return shape(u, v, p * 1.3) ? neu(u, v) : old(u, v);
        case "ender":
            {
                const h = hash(i, j);
                if (h < p - 0.15)
                    return neu(u, v);
                if (h < p + 0.1)
                    return (i + j + Math.floor(t * 30)) % 3 === 0 ? "#b04dff" : "#2a0f3d";
                return old(u, v);
            }
        default:
            return p < 0.5 ? old(u, v) : neu(u, v);
        }
    }

    Repeater {
        model: root.cols * root.rows
        Rectangle {
            required property int index
            readonly property int i: index % root.cols
            readonly property int j: Math.floor(index / root.cols)
            x: Math.floor(i * root.cw)
            y: Math.floor(j * root.ch)
            width: Math.ceil(root.cw)
            height: Math.ceil(root.ch)
            color: root.cell(i, j)
        }
    }
}
