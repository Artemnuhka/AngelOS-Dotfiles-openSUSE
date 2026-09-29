pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.widgets

// Pixel spectrum from cava (raw ASCII output).
Item {
    id: root

    property string screenName
    property var widget
    readonly property int bars: widget && widget.settings && widget.settings.bars ? widget.settings.bars : 32
    // "" = default output; otherwise a sink's node name (cava listens to its monitor)
    readonly property string source: widget && widget.settings && widget.settings.source ? widget.settings.source : ""
    property var levels: []
    property bool missing: false
    readonly property string conf: Quickshell.env("HOME") + "/.cache/angelos/cava-" + (widget ? widget.uid : "x") + ".conf"

    implicitWidth: Theme.u * 6 * bars / 2 + Theme.u * 4
    implicitHeight: Theme.u * 44

    FileView {
        id: confFile
        path: root.conf
        preload: false
        atomicWrites: true
        onSaved: proc.running = true
    }
    property bool ready: false
    function writeConf() {
        if (!ready)
            return;
        proc.running = false;
        confFile.setText(["[general]", "bars = " + bars, "framerate = 30", "sensitivity = 70", "autosens = 1", "[input]", "method = pipewire", "source = " + (root.source || "auto"), "[output]", "method = raw", "raw_target = /dev/stdout", "data_format = ascii", "ascii_max_range = 100", "bar_delimiter = 59", "frame_delimiter = 10", "channels = mono", "[smoothing]", "noise_reduction = 60", ""].join("\n"));
    }
    Component.onCompleted: {
        ready = true;
        writeConf();
    }
    onBarsChanged: writeConf()
    onSourceChanged: writeConf()

    Process {
        id: proc
        command: ["cava", "-p", root.conf]
        stdout: SplitParser {
            onRead: line => root.levels = line.split(";").filter(s => s !== "").map(n => parseInt(n) / 100)
        }
        onExited: code => {
            if (code === 127)
                root.missing = true;
            else if (root.visible)
                restart.start();
        }
    }
    Timer {
        id: restart
        interval: 2000
        onTriggered: proc.running = true
    }

    PxText {
        visible: root.missing
        anchors.centerIn: parent
        text: I18n.t("нужен cava: sudo pacman -S cava", "needs cava: sudo pacman -S cava")
        dim: true
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.u
        Repeater {
            model: root.bars
            Item {
                id: bar
                required property int index
                readonly property real v: root.levels[index] || 0
                width: Theme.u * 2
                height: root.height
                // stacked pixel blocks, pink at the bottom fading to cyan at the top
                Column {
                    anchors.bottom: parent.bottom
                    spacing: Math.max(1, Theme.u / 2)
                    Repeater {
                        model: Math.round(bar.v * 14)
                        Rectangle {
                            required property int index
                            width: bar.width
                            height: Theme.u * 2
                            color: Theme.mix(Theme.accent2, Theme.accent, (index + 1) / 14)
                        }
                    }
                }
            }
        }
    }
}
