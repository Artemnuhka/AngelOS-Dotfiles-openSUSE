pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Pushes the current palette to other apps through templates (kitty, foot, gtk, niri…).
Singleton {
    id: root

    readonly property string paletteFile: Config.cacheDir + "/palette.json"
    readonly property string signature: Config.appearance.customAccent + "|" + Theme.dark + "|" + Config.appearance.flavor + "|" + Config.appearance.themeApps + "|" + (Config.appearance.disabledTemplates || []).join(",")
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
        paletteWriter.setText(JSON.stringify(Theme.exportPalette(), null, 2));
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
