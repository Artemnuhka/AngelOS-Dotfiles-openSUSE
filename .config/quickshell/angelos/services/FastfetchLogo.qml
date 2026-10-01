pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "../widgets/Logos.js" as Logos

// fastfetch draws the chosen emblem (Settings → Bar → Logo → "fastfetch draws this emblem"):
// scripts/fastfetch-logo.py writes ~/.config/fastfetch/logo.txt in the theme colours.
// Horns while the demon rules, like everywhere else; the heart keeps the original drawing.
Singleton {
    id: root

    readonly property string emblem: ["heart", "pill", "star", "cd", "kitty"].includes(Config.bar.logoEmblem) ? Config.bar.logoEmblem : "heart"
    readonly property bool demon: Angel.demon
    readonly property var palette: ({
            "#": Theme.hex(Theme.dark ? Theme.mix(Theme.accent, Theme.edge, 0.55) : Theme.edge),
            "o": Theme.hex(Theme.accent),
            "x": Theme.hex(demon && emblem === "star" ? Qt.color("#7a0a1e") : Theme.accent2),
            "y": demon && emblem === "star" ? "#e0203a" : Theme.hex(Theme.mix(Theme.accent3, Qt.color("#ffd84a"), 0.6)),
            "w": "#ffffff",
            "f": Theme.hex(Theme.mix(Theme.accent2, "#ffffff", 0.55)),
            "r": "#e0203a",
            "p": Theme.hex(Theme.mix(Theme.accent, "#ffffff", 0.45))
        })
    // what the file should show; empty = the original logo
    readonly property string signature: !Config.ready ? "" : Config.bar.logoFastfetch ? JSON.stringify([emblem, demon, palette]) : "restore"
    onSignatureChanged: debounce.restart()

    Timer {
        id: debounce
        interval: 2000
        onTriggered: {
            if (!root.signature)
                return;
            if (writer.running) {
                restart();
                return;
            }
            writer.command = root.signature === "restore" ? ["python3", Quickshell.shellDir + "/scripts/fastfetch-logo.py", "--restore"] : ["python3", Quickshell.shellDir + "/scripts/fastfetch-logo.py", "--emblem", root.emblem, "--rows", JSON.stringify(Logos.emblem(root.emblem, root.demon)), "--palette", JSON.stringify(root.palette)];
            writer.running = true;
        }
    }
    Process {
        id: writer
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }
}
