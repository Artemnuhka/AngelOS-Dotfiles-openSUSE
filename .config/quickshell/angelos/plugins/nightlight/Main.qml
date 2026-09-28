import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Item {
    id: root
    property var plugin
    property bool available: false
    readonly property bool wanted: !Shell.dev && available && !!plugin && plugin.get("on", true)
    readonly property string signature: JSON.stringify(plugin ? ["wlsunset", "-t", String(plugin.get("night", 3900)), "-T", String(plugin.get("day", 6600))].concat(plugin.get("useLocation", false) ? ["-l", String(plugin.get("lat", 55.75)), "-L", String(plugin.get("lon", 37.62))] : ["-S", plugin.get("sunrise", "07:00"), "-s", plugin.get("sunset", "20:00")]) : [])
    property string applied: ""
    onSignatureChanged: debounce.restart()
    onWantedChanged: debounce.restart()
    function reconcile() {
        if (!wanted) {
            sun.running = false;
            return;
        }
        if (sun.running) {
            if (applied !== signature)
                sun.running = false;
            return;
        }
        applied = signature;
        sun.command = JSON.parse(applied);
        sun.running = true;
    }
    Process {
        running: true
        command: ["sh", "-c", "command -v wlsunset"]
        onExited: code => root.available = code === 0
    }
    Process {
        id: sun
        // Start the replacement only once the old gamma-control client exited.
        onExited: if (root.wanted)
            retry.restart()
    }
    Timer {
        id: debounce
        interval: 350
        onTriggered: root.reconcile()
    }
    Timer {
        id: retry
        interval: 1000
        onTriggered: root.reconcile()
    }
}
