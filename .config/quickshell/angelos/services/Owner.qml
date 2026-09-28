pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Owner-only features (dotfiles pull/publish) exist only when BOTH are present:
//   <shell>/owner/                  — never published (see owner/checks.sh)
//   ~/.config/angelos/owner         — marker with `remote=<git url>`, never published
// In the public version neither exists, so none of this shows up.
Singleton {
    id: root

    readonly property string dir: Quickshell.shellDir + "/owner"
    readonly property string markerPath: Config.dir + "/owner"
    property bool hasDir: false
    property bool hasMarker: false
    property string remote: ""
    readonly property bool enabled: hasDir && hasMarker
    // background jobs live here so an update keeps running when the settings page closes
    readonly property var jobs: jobsLoader.item

    Process {
        running: true
        command: ["test", "-f", root.dir + "/DotfilesJobs.qml"]
        onExited: code => root.hasDir = code === 0
    }
    FileView {
        path: root.markerPath
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.hasMarker = true;
            const m = text().match(/^remote=(.+)$/m);
            root.remote = m ? m[1].trim() : "";
        }
        onLoadFailed: root.hasMarker = false
    }
    LazyLoader {
        id: jobsLoader
        active: root.enabled
        source: "file://" + root.dir + "/DotfilesJobs.qml"
    }
}
