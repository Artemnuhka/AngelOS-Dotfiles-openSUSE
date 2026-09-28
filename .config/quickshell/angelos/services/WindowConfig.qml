pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property int gaps: 16
    property string center: "never"
    property string log: ""
    readonly property bool busy: writer.running
    function save(changes) {
        if (writer.running)
            return;
        writer.command = ["python3", Quickshell.shellDir + "/scripts/window-config.py", JSON.stringify(changes)];
        writer.running = true;
    }
    Process {
        id: reader
        running: true
        command: ["python3", Quickshell.shellDir + "/scripts/window-config.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const v = JSON.parse(text);
                    root.gaps = v.gaps;
                    root.center = v.center;
                } catch (e) {
                    root.log = String(e);
                }
            }
        }
    }
    Process {
        id: writer
        stdout: StdioCollector {
            onStreamFinished: root.log = text.trim()
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim())
                root.log = text.trim()
        }
        onExited: reader.running = true
    }
}
