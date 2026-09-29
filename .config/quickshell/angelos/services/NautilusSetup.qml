pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// angelOS defaults for Nautilus (scripts/nautilus-setup.py): «Open in terminal»
// and mediafix in the context menu, plus the preference defaults. Applied once
// on the first run; Settings → Default apps can re-apply or remove them.
Singleton {
    id: root

    property var status: ({})
    property string log: ""
    readonly property bool busy: worker.running
    readonly property bool installed: !!status.extensions && Object.values(status.extensions).every(v => v)

    function refresh() {
        if (!reader.running)
            reader.running = true;
    }
    function apply() {
        run(["apply"]);
    }
    function remove() {
        run(["remove"]);
    }
    function mediafix(files) {
        Quickshell.execDetached(["python3", Quickshell.shellDir + "/scripts/nautilus-setup.py", "mediafix"].concat(files || []));
    }
    function restartNautilus() {
        Quickshell.execDetached(["nautilus", "-q"]);
    }
    function run(args) {
        if (worker.running)
            return;
        worker.command = ["python3", Quickshell.shellDir + "/scripts/nautilus-setup.py"].concat(args);
        worker.running = true;
    }

    // first run: bake the defaults in (never in a dev instance)
    Timer {
        running: Config.ready && !Config.system.nautilusDefaults && !Shell.dev
        interval: 8000
        onTriggered: {
            Config.system.nautilusDefaults = true;
            root.apply();
        }
    }

    Process {
        id: reader
        running: true
        command: ["python3", Quickshell.shellDir + "/scripts/nautilus-setup.py", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.status = JSON.parse(text);
                } catch (e) {}
            }
        }
    }
    Process {
        id: worker
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text);
                    if (r.status)
                        root.status = r.status;
                    root.log = r.error ? r.error : (r.changes || r.removed || []).join("\n");
                } catch (e) {
                    root.log = text.trim();
                }
            }
        }
    }
}
