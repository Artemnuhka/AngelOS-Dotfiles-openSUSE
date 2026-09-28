pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Resolves which wallpaper a screen shows (per workspace > per output > fallback).
Singleton {
    id: root

    property var images: []
    readonly property string dir: Config.expand(Config.wallpaper.dir)

    function key(output, idx) {
        return output + ":" + idx;
    }

    function resolve(output, idx) {
        const w = Config.wallpaper;
        const p = (w.workspaces || {})[key(output, idx)] || (w.outputs || {})[output] || w.fallback || images[0] || "";
        return Config.expand(p);
    }

    function setForOutput(output, path) {
        Config.setIn(Config.wallpaper, "outputs", output, path);
    }
    function setForWorkspace(output, idx, path) {
        Config.setIn(Config.wallpaper, "workspaces", key(output, idx), path);
    }
    function setEverywhere(path) {
        Config.wallpaper.fallback = path;
        Config.wallpaper.outputs = ({});
        Config.wallpaper.workspaces = ({});
    }
    function random(output) {
        if (images.length === 0)
            return;
        const p = images[Math.floor(Math.random() * images.length)];
        if (output)
            setForOutput(output, p);
        else
            setEverywhere(p);
    }

    function scan() {
        scanner.running = false;
        scanner.running = true;
    }

    onDirChanged: scan()
    Component.onCompleted: scan()

    Process {
        id: scanner
        command: ["find", "-L", root.dir, "-maxdepth", "3", "-type", "f", "(", "-iname", "*.png", "-o", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.webp", "-o", "-iname", "*.gif", "-o", "-iname", "*.bmp", ")", "-not", "-path", "*/Screenshots/*"]
        stdout: StdioCollector {
            onStreamFinished: root.images = text.split("\n").filter(l => l !== "").sort()
        }
    }
}
