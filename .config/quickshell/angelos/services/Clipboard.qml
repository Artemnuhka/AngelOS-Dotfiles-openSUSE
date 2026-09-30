pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// MIME-aware clipboard history via `wl-paste --watch scripts/clipboard.py capture`.
// Text entries stay in clipboard.json; images are private files under
// ~/.local/state/angelos/clipboard/ (removed together with their entry).
Singleton {
    id: root

    property var history: []      // newest first, {kind, id, mime, text|path}
    readonly property int limit: 60

    function normalize(entry) {
        if (typeof entry === "string")
            return {
                "kind": "text",
                "id": entry,
                "mime": "text/plain;charset=utf-8",
                "text": entry
            };
        return entry || {};
    }

    function key(entry) {
        return (entry.kind || "text") + ":" + (entry.id || entry.text || entry.path || "");
    }

    readonly property string helper: Quickshell.shellDir + "/scripts/clipboard.py"
    readonly property int imageCount: history.filter(h => h.kind === "image").length

    function push(entry) {
        entry = normalize(entry);
        if (!entry.id || (entry.kind === "text" && !String(entry.text || "").trim()) || (entry.kind === "image" && !entry.path))
            return;
        const dropped = history.length >= limit || history.some(h => key(h) === key(entry));
        history = [entry].concat(history.filter(h => key(h) !== key(entry))).slice(0, limit);
        saveTimer.restart();
        if (dropped)
            pruneTimer.restart();
    }

    function copy(entry) {
        if (copier.running)
            copier.running = false;
        copier.pending = normalize(entry);
        copier.running = true;
    }

    function remove(entry) {
        entry = normalize(entry);
        history = history.filter(h => key(h) !== key(entry));
        saveTimer.restart();
        pruneTimer.restart();
    }
    function clear() {
        history = [];
        saveTimer.restart();
        pruneTimer.restart();
    }
    function clearImages() {
        history = history.filter(h => h.kind !== "image");
        saveTimer.restart();
        pruneTimer.restart();
    }

    // image files no entry points to any more
    Timer {
        id: pruneTimer
        interval: 1500
        onTriggered: if (!Shell.dev)
            Quickshell.execDetached(["python3", root.helper, "prune"].concat(root.history.filter(h => h.kind === "image").map(h => h.id)))
    }

    // watchers left behind by a shell that crashed or was killed keep running
    // (and capturing twice): clear them before starting ours
    Process {
        id: sweep
        running: !Shell.dev
        command: ["pkill", "-f", "^wl-paste --watch python3 " + root.helper + " capture"]
        onExited: watcher.running = true
    }
    Process {
        id: watcher
        // The helper inspects MIME types and returns one JSON object per change.
        // setpriv: wl-paste dies together with the shell, even if the shell crashes
        command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--watch", "python3", root.helper, "capture"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    root.push(JSON.parse(line));
                } catch (e) {}
            }
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
        property var pending: ({})
        command: ["python3", root.helper, "copy"]
        stdinEnabled: true
        onStarted: {
            write(JSON.stringify(pending));
            pending = ({});
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
                const old = JSON.parse(text()) || [];
                root.history = old.map(root.normalize).filter(e => e.id || e.path).slice(0, root.limit);
            } catch (e) {}
        }
    }
}
