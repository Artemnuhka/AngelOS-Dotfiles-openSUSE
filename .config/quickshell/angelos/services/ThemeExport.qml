pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Pushes the current palette to other apps through templates (kitty, foot, gtk, niri…).
Singleton {
    id: root

    readonly property string paletteFile: Config.cacheDir + "/palette.json"
    // the realm (the demon rules: hell's decorations for GTK and Helium) and the window
    // decoration settings re-render too
    readonly property string signature: Config.appearance.customAccent + "|" + Theme.dark + "|" + Config.appearance.flavor + "|" + Config.appearance.themeApps + "|" + (Config.appearance.disabledTemplates || []).join(",") + "|" + Angel.demon + "|" + Config.decor.gtkButtons + "|" + Config.decor.gtkLayout
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
        paletteWriter.setText(JSON.stringify(Object.assign(Theme.exportPalette(), decorPalette()), null, 2));
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
