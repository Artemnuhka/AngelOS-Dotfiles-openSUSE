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
                "body": "#0b0809",
                "plate": "#0f0a0b",
                "face": "#16100f",
                "faceAlt": "#1f1716",
                "sunken": "#070505",
                "edge": "#040303",
                "hi": "#2c211f",
                "lo": "#060404",
                "rim": "#3b2a26",
                "text": "#d9cbbd",
                "textDim": "#9c8f85",
                "accent": "#e2703f",
                "blood": "#6b2420",
                "ember": "#e2703f",
                "flame": "#c99a5e",
                "gold": "#8a7444"
            },
            "bar": {
                "texture": "stone",
                "colors": [
                    "#0c0909",
                    "#110d0d",
                    "#1a1413",
                    "#33201b"
                ],
                "scale": 10,
                "crack": 0.35,
                "glow": 0.12,
                "seed": 3
            },
            "edge": {
                "kind": "scorch",
                "colors": [
                    "#040303",
                    "#3b2a26",
                    "#e2703f",
                    "#24130f"
                ]
            },
            // the dark laid over the wallpaper (shaders/hell_backdrop.frag)
            "backdrop": {
                "dim": 0.5,
                "desat": 0.35,
                "vignette": 0.6,
                "tint": "#0b0809"
            },
            // the word after a reading on hell's widgets: "CPU · жар" — the metric first, always
            "labels": {
                "cpu": {
                    "ru": "жар",
                    "en": "heat"
                },
                "gpu": {
                    "ru": "пекло",
                    "en": "inferno"
                },
                "ram": {
                    "ru": "души",
                    "en": "souls"
                },
                "vram": {
                    "ru": "котёл",
                    "en": "cauldron"
                }
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
    readonly property var edge: look.edge
    readonly property var backdrop: look.backdrop
    // "CPU · жар": the circle's word for a reading, after its plain name
    function label(id, plain) {
        const w = look.labels ? look.labels[id] : null;
        return w ? plain + " · " + I18n.label(w) : plain;
    }

    // the rare thing seen from the corner of an eye (services/HellAmbient drives it): 0 → 1 → 0
    // over a few seconds, on the windows whose seed matches `eventTarget` — one at a time
    property real event: 0
    property int eventTarget: -1
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
