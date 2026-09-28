pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root
    property var monitors: []
    readonly property var selectedMonitor: monitors.find(m => m.value === Config.system.monitor) || monitors[0] || null
    readonly property bool available: Config.system.monitor === "custom" ? Config.system.monitorProgram.trim() !== "" : selectedMonitor !== null
    function refresh() {
        if (!scan.running)
            scan.running = true;
    }
    function launchMonitor() {
        if (Config.system.monitor === "custom") {
            const program = Config.system.monitorProgram.trim();
            if (program)
                Shell.exec(Config.system.monitorInTerminal ? Shell.terminalArgv([program]) : [program]);
            return;
        }
        const m = selectedMonitor;
        if (m)
            Shell.exec(m.terminal ? Shell.terminalArgv([m.value]) : [m.value]);
    }
    function openDirectory(kind) {
        Shell.exec(["python3", Quickshell.shellDir + "/scripts/desktop-actions.py", "directory", kind]);
    }
    function newText() {
        Shell.exec(["python3", Quickshell.shellDir + "/scripts/desktop-actions.py", "text", "--terminal", Config.system.terminal || "kitty"]);
    }
    Process {
        id: scan
        running: true
        command: ["python3", Quickshell.shellDir + "/scripts/desktop-actions.py", "monitors"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.monitors = JSON.parse(text); }
                catch (e) { console.warn("Desktop actions:", e); }
            }
        }
    }
}
