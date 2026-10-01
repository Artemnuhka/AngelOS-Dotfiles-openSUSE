pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Pixel pink palette in the spirit of NEEDY GIRL OVERDOSE.
// Light = "angel" (pastel win98), dark = "overdose" (night stream).
Singleton {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property bool autoDark: {
        const h = clock.hours;
        const a = Config.appearance;
        return a.darkFrom > a.lightFrom ? (h >= a.darkFrom || h < a.lightFrom) : (h >= a.darkFrom && h < a.lightFrom);
    }
    readonly property bool dark: Config.appearance.mode === "dark" || (Config.appearance.mode === "auto" && autoDark)

    function generated(isDark) {
        const seed = Qt.color(Config.appearance.customAccent || "#c77dff");
        const floor = Qt.color(isDark ? "#12141a" : "#fffdf8");
        const ink = Qt.color(isDark ? "#fafafa" : "#202126");
        const a = isDark ? mix(seed, Qt.color("#ffffff"), 0.25) : mix(seed, Qt.color("#161820"), 0.32);
        return {
            desk: hex(mix(floor, seed, 0.06)),
            face: hex(mix(floor, seed, 0.12)),
            faceAlt: hex(mix(floor, seed, 0.2)),
            text: hex(ink),
            textDim: hex(mix(ink, floor, 0.3)),
            accent: hex(a),
            accent2: hex(mix(a, ink, 0.35)),
            title1: hex(a),
            title2: hex(a)
        };
    }
    readonly property var flavors: ({
            wallpaper: {
                name: I18n.t("Из обоев", "From wallpaper"),
                dark: generated(true),
                light: generated(false)
            },
            gruvbox: {
                "name": "Gruvbox",
                "dark": {
                    "desk": "#282828",
                    "face": "#3c3836",
                    "faceAlt": "#504945",
                    "text": "#ebdbb2",
                    "textDim": "#a89984",
                    "accent": "#fabd2f",
                    "accent2": "#83a598",
                    "title1": "#fabd2f",
                    "title2": "#83a598"
                },
                "light": {
                    "desk": "#fbf1c7",
                    "face": "#f2e5bc",
                    "faceAlt": "#ebdbb2",
                    "text": "#3c3836",
                    "textDim": "#665c54",
                    "accent": "#9d0006",
                    "accent2": "#076678",
                    "title1": "#9d0006",
                    "title2": "#076678"
                }
            },
            rosepine: {
                "name": "Ros\u00e9 Pine",
                "dark": {
                    "desk": "#191724",
                    "face": "#1f1d2e",
                    "faceAlt": "#26233a",
                    "text": "#e0def4",
                    "textDim": "#908caa",
                    "accent": "#ebbcba",
                    "accent2": "#c4a7e7",
                    "title1": "#ebbcba",
                    "title2": "#c4a7e7"
                },
                "light": {
                    "desk": "#faf4ed",
                    "face": "#fffaf3",
                    "faceAlt": "#f2e9e1",
                    "text": "#575279",
                    "textDim": "#797593",
                    "accent": "#b4637a",
                    "accent2": "#286983",
                    "title1": "#b4637a",
                    "title2": "#286983"
                }
            },
            catppuccin: {
                "name": "Catppuccin",
                "dark": {
                    "desk": "#1e1e2e",
                    "face": "#313244",
                    "faceAlt": "#45475a",
                    "text": "#cdd6f4",
                    "textDim": "#a6adc8",
                    "accent": "#cba6f7",
                    "accent2": "#89b4fa",
                    "title1": "#cba6f7",
                    "title2": "#89b4fa"
                },
                "light": {
                    "desk": "#eff1f5",
                    "face": "#e6e9ef",
                    "faceAlt": "#ccd0da",
                    "text": "#4c4f69",
                    "textDim": "#6c6f85",
                    "accent": "#8839ef",
                    "accent2": "#1e66f5",
                    "title1": "#8839ef",
                    "title2": "#1e66f5"
                }
            },
            nord: {
                "name": "Nord",
                "dark": {
                    "desk": "#2e3440",
                    "face": "#3b4252",
                    "faceAlt": "#434c5e",
                    "text": "#eceff4",
                    "textDim": "#d8dee9",
                    "accent": "#88c0d0",
                    "accent2": "#b48ead",
                    "title1": "#88c0d0",
                    "title2": "#b48ead"
                },
                "light": {
                    "desk": "#eceff4",
                    "face": "#e5e9f0",
                    "faceAlt": "#d8dee9",
                    "text": "#2e3440",
                    "textDim": "#4c566a",
                    "accent": "#5e81ac",
                    "accent2": "#8f3f71",
                    "title1": "#5e81ac",
                    "title2": "#8f3f71"
                }
            },
            dracula: {
                "name": "Dracula",
                "dark": {
                    "desk": "#282a36",
                    "face": "#343746",
                    "faceAlt": "#44475a",
                    "text": "#f8f8f2",
                    "textDim": "#b8b8d2",
                    "accent": "#bd93f9",
                    "accent2": "#ff79c6",
                    "title1": "#bd93f9",
                    "title2": "#ff79c6"
                },
                "light": {
                    "desk": "#f8f8f2",
                    "face": "#efedf7",
                    "faceAlt": "#e4dff0",
                    "text": "#282a36",
                    "textDim": "#6272a4",
                    "accent": "#7045ad",
                    "accent2": "#a52d76",
                    "title1": "#7045ad",
                    "title2": "#a52d76"
                }
            },
            tokyonight: {
                "name": "Tokyo Night",
                "dark": {
                    "desk": "#1a1b26",
                    "face": "#24283b",
                    "faceAlt": "#414868",
                    "text": "#c0caf5",
                    "textDim": "#a9b1d6",
                    "accent": "#7aa2f7",
                    "accent2": "#bb9af7",
                    "title1": "#7aa2f7",
                    "title2": "#bb9af7"
                },
                "light": {
                    "desk": "#d5d6db",
                    "face": "#e1e2e7",
                    "faceAlt": "#c4c8da",
                    "text": "#343b58",
                    "textDim": "#565f89",
                    "accent": "#34548a",
                    "accent2": "#5a4a78",
                    "title1": "#34548a",
                    "title2": "#5a4a78"
                }
            },
            solarized: {
                "name": "Solarized",
                "dark": {
                    "desk": "#002b36",
                    "face": "#073642",
                    "faceAlt": "#164956",
                    "text": "#fdf6e3",
                    "textDim": "#93a1a1",
                    "accent": "#b58900",
                    "accent2": "#2aa198",
                    "title1": "#b58900",
                    "title2": "#2aa198"
                },
                "light": {
                    "desk": "#fdf6e3",
                    "face": "#eee8d5",
                    "faceAlt": "#e1dbc8",
                    "text": "#586e75",
                    "textDim": "#657b83",
                    "accent": "#9c7100",
                    "accent2": "#007e78",
                    "title1": "#9c7100",
                    "title2": "#007e78"
                }
            },
            everforest: {
                "name": "Everforest",
                "dark": {
                    "desk": "#2d353b",
                    "face": "#343f44",
                    "faceAlt": "#475258",
                    "text": "#d3c6aa",
                    "textDim": "#9da9a0",
                    "accent": "#a7c080",
                    "accent2": "#83c092",
                    "title1": "#a7c080",
                    "title2": "#83c092"
                },
                "light": {
                    "desk": "#fdf6e3",
                    "face": "#f3ead3",
                    "faceAlt": "#e5dfc5",
                    "text": "#5c6a72",
                    "textDim": "#708089",
                    "accent": "#557529",
                    "accent2": "#287b65",
                    "title1": "#557529",
                    "title2": "#287b65"
                }
            },
            bubblegum: {
                name: "Bubblegum",
                light: {
                    accent: "#ff4fa3",
                    accent2: "#57d5ff",
                    title1: "#ff7ec0",
                    title2: "#b895ff"
                },
                dark: {
                    accent: "#ff5cad",
                    accent2: "#4fe3ff",
                    title1: "#ff4fa3",
                    title2: "#7b4dff"
                }
            },
            overdose: {
                name: "Overdose",
                light: {
                    accent: "#e8307f",
                    accent2: "#9b5cff",
                    title1: "#ff3d8b",
                    title2: "#ff8ab8"
                },
                dark: {
                    accent: "#ff2e7e",
                    accent2: "#b36bff",
                    title1: "#d4145a",
                    title2: "#5b1a8f"
                }
            },
            cyberangel: {
                name: "Cyber Angel",
                light: {
                    accent: "#ff5cad",
                    accent2: "#1fb8e6",
                    title1: "#7fdcff",
                    title2: "#ff9ad0"
                },
                dark: {
                    accent: "#ff6ec2",
                    accent2: "#3ff0ff",
                    title1: "#1a9fd6",
                    title2: "#ff4fa3"
                }
            }
        })

    readonly property var legacyBase: dark ? ({
            desk: "#1a0f24",
            face: "#241432",
            faceAlt: "#2f1a42",
            sunken: "#150b1e",
            text: "#ffe1f1",
            textDim: "#a987b8",
            titleText: "#ffffff",
            hi: "#4a2c63",
            lo: "#0e0716",
            edge: "#07030b",
            accent3: "#ffe066",
            accent4: "#a57cff",
            danger: "#ff4f6d",
            ok: "#57e3a2",
            selectText: "#1a0d24",
            shadow: "#000000",
            ansi: ["#2a1838", "#ff4f6d", "#57e3a2", "#ffe066", "#7b8cff", "#ff5cad", "#4fe3ff", "#e8cfe0", "#6b4f7d", "#ff7a93", "#8af0c0", "#fff0a0", "#a3b0ff", "#ff9fd0", "#9ff0ff", "#ffffff"]
        }) : ({
            desk: "#ffd1e8",
            face: "#fff3f9",
            faceAlt: "#ffe3f1",
            sunken: "#ffffff",
            text: "#3b1f4a",
            textDim: "#9a7aa8",
            titleText: "#ffffff",
            hi: "#ffffff",
            lo: "#e7a6cc",
            edge: "#5a2e6e",
            accent3: "#ffc93c",
            accent4: "#b895ff",
            danger: "#ff3d64",
            ok: "#2fbf7f",
            selectText: "#ffffff",
            shadow: "#5a2e6e",
            ansi: ["#3b1f4a", "#e0305a", "#1f9e6a", "#c98a00", "#4b5fd6", "#e0308a", "#1b9ec2", "#b89cb0", "#9a7aa8", "#ff5c80", "#34c28a", "#e0a82e", "#6f80f0", "#ff5cad", "#3cc0e0", "#fff3f9"]
        })
    readonly property var flavor: (flavors[Config.appearance.flavor] || flavors.overdose)[dark ? "dark" : "light"]

    readonly property var base: {
        if (!flavor.desk)
            return legacyBase;
        return Object.assign({}, legacyBase, flavor, {
            sunken: flavor.desk,
            hi: flavor.faceAlt,
            lo: flavor.desk,
            edge: flavor.desk,
            selectText: dark ? flavor.desk : "#ffffff",
            accent3: flavor.accent2,
            accent4: flavor.accent2,
            ansi: [flavor.desk, "#e36b78", "#8eaf73", "#d8b56b", flavor.accent2, flavor.accent, "#72b7b0", flavor.text, flavor.textDim, "#f58b98", "#aacf93", "#efd18b", flavor.accent2, flavor.accent, "#92d7d0", flavor.text]
        });
    }
    readonly property color menuSurface: mix(face, accent, dark ? 0.08 : 0.04)
    readonly property color menuHeader: mix(faceAlt, accent, dark ? 0.16 : 0.10)
    readonly property color menuBorder: mix(faceAlt, accent, 0.32)

    // ---- tokens ----
    readonly property color desk: base.desk
    readonly property color face: base.face
    readonly property color faceAlt: base.faceAlt
    readonly property color sunken: base.sunken
    readonly property color text: base.text
    readonly property color textDim: base.textDim
    readonly property color titleText: base.text
    readonly property color hi: base.hi
    readonly property color lo: base.lo
    readonly property color edge: base.edge
    readonly property color accent: flavor.accent
    readonly property color accent2: flavor.accent2
    readonly property color accent3: base.accent3
    readonly property color accent4: base.accent4
    readonly property color title1: flavor.title1
    readonly property color title2: flavor.title2
    readonly property color danger: base.danger
    readonly property color ok: base.ok
    readonly property color select: accent
    readonly property color selectText: base.selectText
    readonly property color shadow: base.shadow
    readonly property var ansi: base.ansi

    // translucent panel background (blur shows through)
    readonly property real panelAlpha: Config.appearance.blur ? Config.appearance.opacity : 1
    readonly property color panel: Qt.alpha(face, panelAlpha)
    readonly property color panelAlt: Qt.alpha(faceAlt, panelAlpha)

    // ---- the two dimensions: heaven and hell ----
    // The desktop widgets live in one of them: heaven (the usual look) or hell while
    // the demon rules (Y2K → Angel or demon → Widgets in hell). DesktopWidgets sets
    // `realm` midway through the widgets' burn, so a widget can simply bind to it:
    //   color: Theme.hell ? Theme.hellEmber : Theme.accent
    // Plugins declare that they draw both in manifest.json: "realms": ["heaven", "hell"].
    property string realm: "heaven"
    readonly property bool hell: realm === "hell"
    // hell's palette: obsidian, blood, embers and grimoire gold (fixed, not from the flavour)
    readonly property color hellBody: "#160609"
    readonly property color hellFace: "#2a0b10"
    readonly property color hellFaceAlt: "#3d1016"
    readonly property color hellSunken: "#0c0305"
    readonly property color hellEdge: "#050102"
    readonly property color hellHi: "#6e1a21"
    readonly property color hellLo: "#0a0204"
    readonly property color hellBlood: "#b3142b"
    readonly property color hellEmber: "#ff6a1a"
    readonly property color hellFlame: "#ffb02e"
    readonly property color hellGold: "#d9a441"
    readonly property color hellText: "#f3d9c0"
    readonly property color hellTextDim: "#a8857a"
    readonly property color hellPanel: Qt.alpha(hellBody, Math.max(0.82, panelAlpha))
    // Jacquard 24, a pixel blackletter (OFL, data/fonts): Latin only — Cyrillic falls
    // back to the body font. Crisp at 24 px and its multiples (Theme.hellPx).
    readonly property string fontHell: hellFont.status === FontLoader.Ready ? hellFont.name : fontTitle
    function hellPx(n) {
        return 24 * Math.max(1, Math.round(n || 1));
    }
    // Jacquard has Latin only: use it for text that is all ASCII, the title font otherwise
    function latin(text) {
        return /^[\x00-\x7F]*$/.test(String(text));
    }
    function roman(n) {
        n = Math.floor(n);
        if (n <= 0)
            return "N";                     // nulla, the medieval zero
        const r = [[1000, "M"], [900, "CM"], [500, "D"], [400, "CD"], [100, "C"], [90, "XC"], [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]];
        let s = "";
        for (const [v, c] of r)
            while (n >= v) {
                s += c;
                n -= v;
            }
        return s;
    }
    FontLoader {
        id: hellFont
        source: Qt.resolvedUrl("../data/fonts/Jacquard24-Regular.ttf")
    }

    // ---- metrics ----
    readonly property int u: Math.max(1, Config.appearance.px)   // one art pixel
    readonly property int fs: Math.max(1, Config.appearance.fontScale)
    readonly property int gap: u * 4
    readonly property int pad: u * 5

    // ---- fonts (sizes are native multiples so glyphs stay crisp) ----
    readonly property string defaultTitleFont: "Pixeloid Sans"
    readonly property string defaultBodyFont: "CozetteVector"
    readonly property string defaultMonoFont: "Pixeloid Mono"
    readonly property string fontTitle: Config.appearance.fontTitle || defaultTitleFont
    readonly property string fontBody: Config.appearance.fontBody || defaultBodyFont
    readonly property string fontMono: Config.appearance.fontMono || defaultMonoFont
    // glyph cell of known pixel fonts (scripts/fonts.py keeps the same numbers)
    readonly property var fontNative: ({
            "Pixeloid Sans": 9,
            "Pixeloid Mono": 9,
            "CozetteVector": 13,
            "CozetteVectorBold": 13,
            "Cozette": 13,
            "Pixelify Sans": 11,
            "Tiny5": 8,
            "Press Start 2P": 8,
            "Monocraft": 9,
            "Departure Mono": 11,
            "Silkscreen": 8
        })
    function crisp(base, family) {
        const n = fontNative[family] || 0;
        return n > 0 ? Math.max(n, Math.round(base / n) * n) : base;
    }
    readonly property int sizeTiny: crisp(9, fontTitle) * fs
    readonly property int sizeBody: crisp(13, fontBody) * fs
    readonly property int sizeTitle: crisp(18, fontTitle) * fs
    readonly property int sizeBig: crisp(27, fontTitle) * fs
    readonly property int sizeHuge: crisp(36, fontTitle) * fs
    readonly property int sizeMono: crisp(18, fontMono) * fs
    readonly property int sizeMonoSmall: crisp(13, fontMono) * fs

    // ---- motion: stepped easing feels "pixel" ----
    readonly property int fast: 140
    readonly property int normal: 220
    readonly property int slow: 380

    function mix(a, b, t) {
        // accepts colors or "#rrggbb" strings
        a = typeof a === "string" ? Qt.color(a) : a;
        b = typeof b === "string" ? Qt.color(b) : b;
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }

    function hex(c) {
        const h = v => ("0" + Math.round(v * 255).toString(16)).slice(-2);
        return "#" + h(c.r) + h(c.g) + h(c.b);
    }

    // flat palette for templates
    function exportPalette() {
        const p = {
            mode: dark ? "dark" : "light",
            flavor: Config.appearance.flavor
        };
        const keys = ["desk", "face", "faceAlt", "sunken", "text", "textDim", "titleText", "hi", "lo", "edge", "accent", "accent2", "accent3", "accent4", "title1", "title2", "danger", "ok", "select", "selectText", "shadow"];
        for (const k of keys)
            p[k] = hex(root[k]);
        for (let i = 0; i < 16; i++)
            p["color" + i] = ansi[i];
        p.bg = dark ? p.desk : p.face;
        p.fg = p.text;
        p.bgAlt = dark ? p.face : p.faceAlt;
        return p;
    }
}
