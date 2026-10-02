pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// How hell looks right now: its palette, the stone behind the bar, the rim of windows and
// widgets — described as data in story/circles.json, one entry per circle ("base" is hell
// before any circle and what every circle starts from). The story (services) sets `circle`;
// Theme.hell* follow `palette`, so plugins that draw hell themselves change with it.
Singleton {
    id: root

    property string circle: "base"
    property var looks: ({})
    // what the shell draws if story/circles.json is missing or broken
    readonly property var fallback: ({
            "name": {
                "ru": "Ад",
                "en": "Hell"
            },
            "palette": {
                "body": "#160609",
                "plate": "#0e0406",
                "face": "#2a0b10",
                "faceAlt": "#3d1016",
                "sunken": "#0c0305",
                "edge": "#050102",
                "hi": "#6e1a21",
                "lo": "#0a0204",
                "rim": "#4a1a1c",
                "text": "#f3d9c0",
                "textDim": "#b8988a",
                "accent": "#f06a3a",
                "blood": "#b3142b",
                "ember": "#ff6a1a",
                "flame": "#ffb02e",
                "gold": "#d9a441"
            },
            "bar": {
                "texture": "stone",
                "colors": ["#120708", "#1a0b0d", "#2a0e10", "#5a1814"],
                "scale": 10,
                "crack": 0.5,
                "glow": 0.25,
                "seed": 3
            }
        })
    // a circle's entry over "base" over the fallback, objects merged key by key
    function merged(...parts) {
        const out = {};
        for (const p of parts) {
            if (!p || typeof p !== "object")
                continue;
            for (const k in p) {
                const v = p[k];
                out[k] = v && typeof v === "object" && !Array.isArray(v) && out[k] && typeof out[k] === "object" && !Array.isArray(out[k]) ? merged(out[k], v) : v;
            }
        }
        return out;
    }
    readonly property var look: merged(fallback, looks.base, circle !== "base" ? looks[circle] : null)
    readonly property var palette: look.palette
    readonly property var bar: look.bar
    readonly property var ids: Object.keys(looks).filter(k => k !== "_comment")

    // WCAG contrast of two "#rrggbb" colours (tests check every circle's text roles)
    function contrast(a, b) {
        const lum = h => {
            const c = Qt.color(h);
            const f = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
            return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
        };
        const x = lum(a), y = lum(b);
        return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
    }

    FileView {
        path: Quickshell.shellDir + "/story/circles.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.looks = JSON.parse(text());
            } catch (e) {
                console.warn("story/circles.json: " + e);
            }
        }
    }
}
