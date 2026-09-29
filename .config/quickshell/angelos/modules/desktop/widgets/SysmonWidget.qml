pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.widgets

// CPU / GPU / RAM / temperatures / network in pixel meters.
Item {
    id: root

    property string screenName
    property var widget

    property real cpu: 0
    property real cpuTemp: -1
    property real ram: 0
    property string ramText: ""
    property real gpu: -1
    property real gpuTemp: -1
    property string vramText: ""
    property real rx: 0
    property real tx: 0
    property var _cpuLast: null
    property var _netLast: null
    property string cpuTempPath: ""

    implicitWidth: Theme.u * 130
    implicitHeight: col.implicitHeight

    function human(bps) {
        const k = bps / 1024;
        return k < 1024 ? k.toFixed(0) + " " + I18n.t("КБ/с", "KB/s") : (k / 1024).toFixed(1) + " " + I18n.t("МБ/с", "MB/s");
    }

    Timer {
        interval: 2000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            mem.reload();
            net.reload();
            if (root.cpuTempPath)
                temp.reload();
            if (!gpuProc.running)
                gpuProc.running = true;
        }
    }
    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0);
            if (root._cpuLast && total > root._cpuLast.t)
                root.cpu = 1 - (idle - root._cpuLast.i) / (total - root._cpuLast.t);
            root._cpuLast = {
                "t": total,
                "i": idle
            };
        }
    }
    FileView {
        id: mem
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const g = k => parseInt((t.match(new RegExp(k + ":\\s+(\\d+)")) || [0, 0])[1]);
            const total = g("MemTotal"), avail = g("MemAvailable");
            root.ram = 1 - avail / Math.max(1, total);
            root.ramText = ((total - avail) / 1048576).toFixed(1) + " / " + (total / 1048576).toFixed(0) + " " + I18n.t("ГБ", "GB");
        }
    }
    FileView {
        id: net
        path: "/proc/net/dev"
        onLoaded: {
            let rx = 0, tx = 0;
            for (const l of text().split("\n").slice(2)) {
                const m = l.trim().split(/[:\s]+/);
                if (!m[0] || m[0] === "lo" || m[0].startsWith("veth") || m[0].startsWith("docker"))
                    continue;
                rx += parseInt(m[1]) || 0;
                tx += parseInt(m[9]) || 0;
            }
            const now = Date.now();
            if (root._netLast) {
                const dt = (now - root._netLast.at) / 1000;
                root.rx = Math.max(0, (rx - root._netLast.rx) / dt);
                root.tx = Math.max(0, (tx - root._netLast.tx) / dt);
            }
            root._netLast = {
                "rx": rx,
                "tx": tx,
                "at": now
            };
        }
    }
    FileView {
        id: temp
        path: root.cpuTempPath
        printErrors: false
        onLoaded: root.cpuTemp = parseInt(text()) / 1000
    }
    // find the CPU sensor once (k10temp / coretemp / zenpower)
    Process {
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do case $(cat $h/name) in k10temp|coretemp|zenpower|cpu_thermal) echo $h/temp1_input; exit;; esac; done"]
        stdout: StdioCollector {
            onStreamFinished: root.cpuTempPath = text.trim()
        }
    }
    Process {
        id: gpuProc
        command: ["sh", "-c", "nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.split(",").map(s => parseFloat(s));
                if (v.length >= 4 && !isNaN(v[0])) {
                    root.gpu = v[0] / 100;
                    root.gpuTemp = v[1];
                    root.vramText = (v[2] / 1024).toFixed(1) + " / " + (v[3] / 1024).toFixed(0) + " " + I18n.t("ГБ", "GB");
                }
            }
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: Theme.u * 3

        Repeater {
            model: [
                {
                    "k": "CPU",
                    "v": root.cpu,
                    "t": Math.round(root.cpu * 100) + "%" + (root.cpuTemp > 0 ? "  " + Math.round(root.cpuTemp) + "°" : ""),
                    "c": Theme.accent
                },
                {
                    "k": "GPU",
                    "v": Math.max(0, root.gpu),
                    "t": root.gpu < 0 ? "—" : Math.round(root.gpu * 100) + "%" + (root.gpuTemp > 0 ? "  " + Math.round(root.gpuTemp) + "°" : ""),
                    "c": Theme.accent2
                },
                {
                    "k": "RAM",
                    "v": root.ram,
                    "t": root.ramText,
                    "c": Theme.accent4
                },
                {
                    "k": "VRAM",
                    "v": root.vramText ? parseFloat(root.vramText) / Math.max(1, parseFloat(root.vramText.split("/")[1])) : 0,
                    "t": root.vramText || "—",
                    "c": Theme.accent3
                }
            ]
            Column {
                id: r
                required property var modelData
                width: col.width
                spacing: Theme.u
                Row {
                    width: parent.width
                    PxText {
                        width: parent.width / 2
                        text: r.modelData.k
                        font.bold: true
                    }
                    PxText {
                        width: parent.width / 2
                        horizontalAlignment: Text.AlignRight
                        text: r.modelData.t
                        dim: true
                    }
                }
                PxBox {
                    width: parent.width
                    height: Theme.u * 6
                    sunken: true
                    color: Theme.sunken
                    Row {
                        anchors.fill: parent
                        spacing: Math.max(1, Theme.u / 2)
                        Repeater {
                            model: 16
                            Rectangle {
                                required property int index
                                width: parent ? (parent.width - 15 * parent.spacing) / 16 : 0
                                height: parent ? parent.height : 0
                                color: index < Math.round(r.modelData.v * 16) ? r.modelData.c : "transparent"
                            }
                        }
                    }
                }
            }
        }
        Row {
            spacing: Theme.u * 6
            PxText {
                text: "↓ " + root.human(root.rx)
                color: Theme.ok
            }
            PxText {
                text: "↑ " + root.human(root.tx)
                color: Theme.accent2
            }
        }
    }
}
