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
    readonly property string taskmgrId: "angelos.taskmgr"
    function launchMonitor() {
        if (Config.system.monitor === "custom") {
            const program = Config.system.monitorProgram.trim();
            if (program)
                Shell.exec(Config.system.monitorInTerminal ? Shell.terminalArgv([program], taskmgrId) : [program]);
            return;
        }
        const m = selectedMonitor;
        if (m)
            Shell.exec(m.terminal ? Shell.terminalArgv([m.value], taskmgrId) : [m.value]);
    }

    // ---- the task manager always floats at a set size (niri rule in cfg/angelos-windows.kdl) ----
    readonly property var sizes: ({
            "compact": ["fixed 900", "fixed 560"],
            "medium": ["fixed 1200", "fixed 760"],
            "large": ["fixed 1500", "fixed 950"],
            "tall": ["proportion 0.4", "proportion 0.9"]
        })
    // every known monitor's window, so switching programs needs no new rule
    readonly property var monitorAppIds: [taskmgrId].concat(...monitors.map(m => String(m.appId || "").split("|"))).filter((a, i, all) => a && all.indexOf(a) === i)
    readonly property var taskmgrSpec: {
        if (!Config.system.monitorFloat)
            return null;
        const s = Config.system;
        const wh = s.monitorSize === "custom" ? ["fixed " + Math.max(320, Math.min(7680, s.monitorWidth)), "fixed " + Math.max(240, Math.min(4320, s.monitorHeight))] : sizes[s.monitorSize] || sizes.medium;
        return {
            "appIds": monitorAppIds,
            "width": wh[0],
            "height": wh[1],
            "place": s.monitorPlace === "corner" ? "corner" : "center"
        };
    }
    onTaskmgrSpecChanged: if (monitors.length)
        ruleTimer.restart()
    Timer {
        id: ruleTimer
        interval: 1200
        // dev runs never touch the live niri config
        onTriggered: if (!Shell.dev)
            WindowConfig.setTaskManager(root.taskmgrSpec)
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
