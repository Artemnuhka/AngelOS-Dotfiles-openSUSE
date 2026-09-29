pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// User settings, persisted to ~/.config/angelos/settings.json.
// Every property change is written back after a short debounce.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: home + "/.config/angelos"
    readonly property string pluginsDir: dir + "/plugins"
    readonly property string templatesDir: dir + "/templates"
    readonly property string stateDir: home + "/.local/state/angelos"
    readonly property string cacheDir: home + "/.cache/angelos"

    property bool newConfig: false
    readonly property bool ready: file.loaded || newConfig
    property alias appearance: adapter.appearance
    property alias bar: adapter.bar
    property alias wallpaper: adapter.wallpaper
    property alias workspaces: adapter.workspaces
    property alias lyrics: adapter.lyrics
    property alias setup: adapter.setup
    property alias notifications: adapter.notifications
    property alias osd: adapter.osd
    property alias launcher: adapter.launcher
    property alias voxtype: adapter.voxtype
    property alias desktop: adapter.desktop
    property alias lock: adapter.lock
    property alias plugins: adapter.plugins
    property alias dotfiles: adapter.dotfiles
    property alias system: adapter.system

    function expand(path) {
        if (!path)
            return "";
        return path.startsWith("~/") ? home + path.slice(1) : path;
    }

    // JSON maps have to be reassigned to notify the adapter.
    function setIn(obj, prop, key, value) {
        const copy = Object.assign({}, obj[prop] || {});
        if (value === undefined || value === null || value === "")
            delete copy[key];
        else
            copy[key] = value;
        obj[prop] = copy;
    }

    Timer {
        id: saveTimer
        interval: 350
        onTriggered: file.writeAdapter()
    }

    Process {
        id: mkdirs
        running: true
        command: ["mkdir", "-p", root.dir, root.pluginsDir, root.templatesDir, root.stateDir, root.cacheDir + "/lyrics"]
    }

    FileView {
        id: file
        path: root.dir + "/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: saveTimer.restart()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.newConfig = true;
                saveTimer.restart();
            }
        }

        JsonAdapter {
            id: adapter

            property JsonObject appearance: JsonObject {
                property string customAccent: "#c77dff"
                property string language: "ru"
                property string mode: "dark"        // light | dark | auto
                property int lightFrom: 8           // auto: light theme from this hour
                property int darkFrom: 20           // auto: dark theme from this hour
                property string flavor: "overdose" // bubblegum | overdose | cyberangel
                property real opacity: 0.84         // panel background opacity (blur shows through)
                property bool blur: true
                property int px: 2                  // size of one "art pixel" in screen pixels
                property int fontScale: 1           // 1 or 2 keeps pixel fonts crisp
                property bool shadows: true         // hard pixel drop shadows
                property bool themeApps: true       // render templates for kitty/foot/gtk/niri
                property var disabledTemplates: []
            }

            property JsonObject bar: JsonObject {
                property string style: "taskbar"    // taskbar | top | island
                property var screens: []            // empty = every screen
                property bool compactOnVertical: true
                property bool showWindows: true
                property bool taskLabels: false
                property int taskMinWidth: 40       // task buttons with titles, in art pixels
                property int taskMaxWidth: 90
                property string workspaceStyle: "hearts" // hearts | icons | both
                property int workspaceIcons: 3      // max app icons per workspace
                property bool allWindows: false     // taskbar: every window, not only current workspace
                property bool showMedia: true
                property bool showSeconds: false
                property string startLabel: "angelOS"
                property string logoStyle: "classic" // classic | angel
                property var layout: ({})           // {left:[], center:[], right:[]}; empty = defaults
                property var hidden: []             // widget ids removed from the bar
                property string trayTint: "accent"  // off | mono | accent — recolor tray icons to the theme
                property bool tintTasks: false      // same for window buttons
            }

            property JsonObject wallpaper: JsonObject {
                property string dir: "~/Pictures"
                property string fallback: ""
                property var outputs: ({})          // "DP-1" -> path
                property var workspaces: ({})       // "DP-1:2" -> path
                property string transition: "mosaic-dither" // mosaic-dither | mosaic | dither | none (only when the picture changes)
                property int duration: 750
                property int maxBlock: 48
            }

            property JsonObject workspaces: JsonObject {
                property string popupMode: "bar"    // bar (flash next to the hearts) | window | off
                property string popupPosition: "bottom-center"
                property bool indicator: false      // heart strip on the right edge
                property int popupMs: 650
                property bool phrases: true
                property var names: ({})            // "DP-1:1" -> "работа"
            }

            property JsonObject lyrics: JsonObject {
                property bool enabled: true         // current line in the middle of the bar
                property var screens: []            // empty = every bar
                property int offsetMs: 0
                property string artwork: "note"          // note | cover
                property bool typewriter: true
                property string preferPlayer: "spotify"
            }

            property JsonObject setup: JsonObject {
                property bool complete: false
            }

            property JsonObject notifications: JsonObject {
                property bool dnd: false
                property int timeout: 6000
                property string screen: ""          // empty = focused output
                property string position: "top-right"
                property int maxPopups: 4
            }

            property JsonObject osd: JsonObject {
                property bool enabled: true
                property bool layout: true          // show keyboard layout switches
                property string position: "bottom-center"
                property int ms: 900
            }

            property JsonObject desktop: JsonObject {
                property var widgets: []            // [{uid, type, screen, x, y, settings}]; x/y < 0 = from the right/bottom
                property bool initialized: false
                property bool snap: true
            }

            property JsonObject voxtype: JsonObject {
                property string indicator: "angelos" // angelos | classic (old GTK circle) | off
                property string position: "bottom-center"
            }

            property JsonObject launcher: JsonObject {
                property string terminal: "kitty"
                property var usage: ({})            // desktop id -> launches
            }

            property JsonObject lock: JsonObject {
                property int idleMinutes: 0         // 0 = never lock automatically
                property bool pixelate: true
            }

            property JsonObject plugins: JsonObject {
                property var enabled: ({})          // id -> bool (missing = manifest default)
                property var data: ({})             // id -> plugin settings object
            }

            property JsonObject dotfiles: JsonObject {
                property string repo: "~/PixelStreetArt_Dotfiles_Niri"
                property string command: "./install.sh"
                property string env: "DOTFILES_MODE=full SKIP_PACKAGES=1 INSTALL_VOXTYPE=0 DOWNLOAD_VOXTYPE_MODEL=0 ENABLE_SERVICES=0"
                property bool reloadNiri: true
            }

            property JsonObject system: JsonObject {
                property string terminal: "kitty"
                property string fileManager: "nautilus"
                property string monitor: "auto"
                property string monitorProgram: ""
                property bool monitorInTerminal: false
            }
        }
    }
}
