pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Y2K sound pack (scripts/y2k-sounds.py synthesises it into
// ~/.local/share/angelos/sounds/y2k the first time a sound is needed).
// Events: startup notify error click shutdown angel — Settings → Y2K.
Singleton {
    id: root

    readonly property var events: ["startup", "notify", "error", "click", "shutdown", "angel"]
    readonly property string dir: Config.home + "/.local/share/angelos/sounds/y2k"
    property bool ready: false
    property var pending: []

    function enabled(name) {
        return Config.y2k.sounds && !(Config.y2k.soundOff || []).includes(name);
    }
    // play even when switched off (the settings page "listen" buttons)
    function preview(name) {
        _play(name);
    }
    function play(name) {
        if (enabled(name))
            _play(name);
    }
    function _play(name) {
        if (!events.includes(name))
            return;
        if (!ready) {
            pending = pending.concat([name]);
            make.running = true;
            return;
        }
        Quickshell.execDetached(["sh", "-c", 'f="$1/$2.ogg"; [ -f "$f" ] || f="$1/$2.wav"; exec pw-play --volume "$3" "$f"', "sh", dir, name, String(Math.max(0, Math.min(1, Config.y2k.soundVolume)))]);
    }

    // generate once if the pack is missing
    Process {
        id: check
        running: true
        command: ["sh", "-c", 'for n in startup notify error click shutdown angel; do [ -f "$1/$n.ogg" ] || [ -f "$1/$n.wav" ] || exit 1; done', "sh", root.dir]
        onExited: code => {
            if (code === 0)
                root.ready = true;
        }
    }
    Process {
        id: make
        command: ["python3", Quickshell.shellDir + "/scripts/y2k-sounds.py", root.dir]
        onExited: code => {
            if (code !== 0)
                return;
            root.ready = true;
            const p = root.pending;
            root.pending = [];
            for (const n of p.slice(-1))
                root._play(n);
        }
    }
}
