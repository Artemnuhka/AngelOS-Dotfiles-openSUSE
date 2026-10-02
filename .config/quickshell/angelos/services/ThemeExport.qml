pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "AngelLines.js" as Lines

// Pushes the current palette to other apps through templates (kitty, foot, gtk, niri…).
Singleton {
    id: root

    readonly property string paletteFile: Config.cacheDir + "/palette.json"
    // the realm (the demon rules: hell's decorations for GTK and Helium) and the window
    // decoration settings re-render too
    readonly property string signature: Config.appearance.customAccent + "|" + Theme.dark + "|" + Config.appearance.flavor + "|" + Config.appearance.themeApps + "|" + (Config.appearance.disabledTemplates || []).join(",") + "|" + Angel.demon + "|" + Config.decor.gtkButtons + "|" + Config.decor.gtkLayout + "|" + Config.y2k.hellTerminal + "|" + Config.y2k.hellApps + "|" + Config.appearance.qtStyle + "|" + I18n.english
    property string lastLog: ""
    property var entries: []

    onSignatureChanged: if (Config.ready)
        debounce.restart()
    Component.onCompleted: listEntries.running = true

    // first render once settings are loaded
    Timer {
        running: Config.ready
        interval: 1200
        onTriggered: root.apply()
    }

    function apply() {
        if (!Config.appearance.themeApps || Shell.dev)
            return;
        paletteWriter.setText(JSON.stringify(Object.assign(Theme.exportPalette(), decorPalette(), terminalPalette(), appsPalette()), null, 2));
    }

    // window decorations (templates gtk3-decor/gtk4-decor, scripts/gtk-live.py, Helium):
    // heaven's title bars like angelOS's own windows, hell's in obsidian and blood
    function decorPalette() {
        const hell = Angel.demon;
        const h = c => Theme.hex(c);
        return {
            "realm": hell ? "hell" : "heaven",
            "decorGtk": Config.decor.gtkButtons ? "1" : "",
            "decorButtons": /^[a-z,]*$/.test(Config.decor.gtkLayout || "") ? Config.decor.gtkLayout : "maximize,close",
            "decorHeader": h(hell ? Theme.mix(Theme.hellFaceAlt, Theme.hellBlood, 0.35) : Theme.menuHeader),
            "decorFace": h(hell ? Theme.hellFace : Theme.face),
            "decorFaceAlt": h(hell ? Theme.hellFace : Theme.faceAlt),
            "decorHover": h(hell ? Theme.hellFaceAlt : Theme.mix(Theme.face, Theme.accent, 0.25)),
            "decorHi": h(hell ? Theme.hellHi : Theme.hi),
            "decorLo": h(hell ? Theme.hellLo : Theme.lo),
            "decorEdge": h(hell ? Theme.hellEdge : Theme.edge),
            "decorText": h(hell ? Theme.hellText : (Theme.dark ? Theme.text : Theme.edge)),
            "decorTextDim": h(hell ? Theme.hellTextDim : Theme.textDim),
            "decorTitle": h(hell ? Theme.hellFlame : Theme.text),
            "decorDanger": h(hell ? Theme.hellBlood : Theme.danger)
        };
    }

    // the terminals (kitty, foot, Alacritty: templates with "terminal": true) while the demon
    // rules (Y2K → Terminal in hell): `term` overrides their colours with hell's — obsidian,
    // bone, blood, embers, brimstone — `kittyExtra` adds an ember cursor trail and a charred
    // background (scripts/terminal-hell.py paints it, writes the realm for the fish greeting)
    readonly property bool terminalHell: Angel.demon && Config.y2k.hellTerminal
    function terminalPalette() {
        const bgImage = Config.home + "/.local/share/angelos/terminal/hell.png";
        if (!terminalHell)
            return {
                "termRealm": "heaven",
                "term": ({}),
                "hellLines": [],
                "kittyExtra": "# heaven: kitty's own defaults\ncursor_trail 0\ncursor_blink_interval -1\nbackground_image none\nbackground_tint 0.0"
            };
        return {
            "termRealm": "hell",
            "term": {
                "mode": "dark",
                "bg": "#0e0306",
                "fg": "#f3d9c0",
                "bgAlt": "#2a0b10",
                "accent": "#ff6a1a",
                "accent2": "#ffb02e",
                "selectText": "#160609",
                "textDim": "#a8857a",
                "lo": "#3d1016",
                "color0": "#160609",
                "color1": "#b3142b",
                "color2": "#7d9b32",
                "color3": "#d9a441",
                "color4": "#6c4ab6",
                "color5": "#c2185b",
                "color6": "#4fb3a9",
                "color7": "#c9a99a",
                "color8": "#5a2a2f",
                "color9": "#e8404f",
                "color10": "#b5d44c",
                "color11": "#ffb02e",
                "color12": "#9b7bf0",
                "color13": "#ff4f8b",
                "color14": "#8ae0d4",
                "color15": "#f3d9c0"
            },
            "hellLines": Lines.demonTerminal.map(l => I18n.english ? l[1] : l[0]),
            "kittyExtra": "# hell (Settings → Y2K → Terminal in hell): embers trail the cursor, a charred background\ncursor_trail 3\ncursor_trail_decay 0.08 0.35\ncursor_trail_start_threshold 1\ncursor_blink_interval 0.6 ease-in-out\nbackground_image " + bgImage + "\nbackground_image_layout scaled\nbackground_tint 0.55"
        };
    }

    // GTK and Qt apps (templates with "apps": true, scripts/qt-theme.py) while the demon
    // rules (Y2K → Apps in hell): the whole app in hell's colours, not only its title bar
    readonly property bool appsHell: Angel.demon && Config.y2k.hellApps
    function appsPalette() {
        return {
            "appsRealm": appsHell ? "hell" : "heaven",
            "qtStyle": Config.appearance.qtStyle ? "1" : "",
            "apps": !appsHell ? ({}) : {
                "mode": "dark",
                "bg": "#160609",
                "bgAlt": "#2a0b10",
                "fg": "#f3d9c0",
                "textDim": "#a8857a",
                "accent": "#d63a24",
                "accent2": "#ff6a1a",
                "accent3": "#ffb02e",
                "selectText": "#fff3e6",
                "danger": "#ff2a3d",
                "ok": "#7d9b32",
                "face": "#2a0b10",
                "faceAlt": "#3d1016",
                "sunken": "#0c0305",
                "hi": "#6e1a21",
                "lo": "#0a0204",
                "edge": "#050102",
                "select": "#b3142b"
            }
        };
    }

    Timer {
        id: debounce
        interval: 500
        onTriggered: root.apply()
    }

    FileView {
        id: paletteWriter
        path: root.paletteFile
        preload: false
        atomicWrites: true
        onSaved: {
            render.command = ["python3", Quickshell.shellDir + "/scripts/render-templates.py", root.paletteFile, (Config.appearance.disabledTemplates || []).join(",")];
            render.running = true;
        }
    }

    Process {
        id: render
        stdout: StdioCollector {
            onStreamFinished: root.lastLog = text
        }
        stderr: StdioCollector {
            onStreamFinished: if (text)
                console.warn("angelOS templates:", text)
        }
    }

    // list of templates for the settings page
    Process {
        id: listEntries
        command: ["sh", "-c", 'cat "$1"; for f in "$2"/*.json; do [ -f "$f" ] && { printf "\\n"; cat "$f"; }; done', "sh", Quickshell.shellDir + "/templates/templates.json", Config.templatesDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                // naive split on top-level arrays/objects is enough for our own files
                for (const chunk of text.split(/\n(?=[\[{])/)) {
                    try {
                        const d = JSON.parse(chunk);
                        for (const e of (Array.isArray(d) ? d : [d]))
                            if (!out.find(o => o.id === e.id))
                                out.push(e);
                    } catch (e) {}
                }
                root.entries = out;
            }
        }
    }
}
