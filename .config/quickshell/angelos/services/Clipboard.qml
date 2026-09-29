pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Text clipboard history via `wl-paste --watch` (kept in ~/.local/state/angelos/clipboard.json).
Singleton {
    id: root

    property var history: []      // newest first, strings
    readonly property int limit: 60

    // base64 -> UTF-8 string (Qt.atob is Latin-1 only and deprecated)
    readonly property string _abc: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    function decode(b64) {
        const bytes = [];
        let buf = 0, bits = 0;
        for (const ch of b64) {
            const v = _abc.indexOf(ch);
            if (v < 0)
                continue;
            buf = (buf << 6) | v;
            bits += 6;
            if (bits >= 8) {
                bits -= 8;
                bytes.push((buf >> bits) & 0xff);
            }
        }
        let out = "";
        for (let i = 0; i < bytes.length;) {
            const b = bytes[i];
            let cp, n;
            if (b < 0x80) {
                cp = b;
                n = 1;
            } else if (b >> 5 === 6) {
                cp = b & 0x1f;
                n = 2;
            } else if (b >> 4 === 14) {
                cp = b & 0x0f;
                n = 3;
            } else {
                cp = b & 0x07;
                n = 4;
            }
            for (let k = 1; k < n; k++)
                cp = (cp << 6) | ((bytes[i + k] || 0) & 0x3f);
            out += String.fromCodePoint(cp);
            i += n;
        }
        return out;
    }
    function push(text) {
        if (!text || !text.trim())
            return;
        history = [text].concat(history.filter(h => h !== text)).slice(0, limit);
        saveTimer.restart();
    }
    // via stdin: argv is readable by every process (/proc/*/cmdline)
    function copy(text) {
        if (copier.running)
            copier.running = false;
        copier.pending = text;
        copier.running = true;
    }
    function remove(text) {
        history = history.filter(h => h !== text);
        saveTimer.restart();
    }
    function clear() {
        history = [];
        saveTimer.restart();
    }

    Process {
        id: watcher
        running: !Shell.dev
        // password managers mark secrets with x-kde-passwordManagerHint: never keep those
        command: ["wl-paste", "--type", "text", "--watch", "sh", "-c", "if wl-paste --list-types 2>/dev/null | grep -qx 'x-kde-passwordManagerHint'; then cat >/dev/null; echo; else base64 -w0; echo; fi"]
        stdout: SplitParser {
            onRead: line => root.push(root.decode(line))
        }
        onExited: restart.start()
    }
    Timer {
        id: restart
        interval: 3000
        onTriggered: watcher.running = true
    }
    Process {
        id: copier
        property string pending: ""
        command: ["wl-copy"]
        stdinEnabled: true
        onStarted: {
            write(pending);
            pending = "";
            stdinEnabled = false;
        }
        onExited: stdinEnabled = true
    }

    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: store.setText(JSON.stringify(root.history))
    }
    FileView {
        id: store
        path: Config.stateDir + "/clipboard.json"
        printErrors: false
        onLoaded: {
            try {
                root.history = JSON.parse(text()) || [];
            } catch (e) {}
        }
    }
}
