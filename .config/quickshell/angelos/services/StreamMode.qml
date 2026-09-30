pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Stream mode: while OBS streams (obs-websocket, scripts/obs-watch.py) or when
// switched on by hand, angelOS keeps out of the picture — the angel leaves the
// streamed screens, its sounds stay quiet, Do not disturb is on, and sparkles,
// the loading screen and the angel/demon effects skip the streamed screens.
// Settings → Y2K → Stream mode; `angelos stream on|off|auto`.
Singleton {
    id: root

    property bool obsUp: false
    property bool obsLive: false
    property bool obsAuth: false             // OBS asks for a password we do not have
    // switched off by hand while OBS is live: stays off until this stream ends
    property bool suppressed: false
    onObsLiveChanged: if (!obsLive)
        suppressed = false
    readonly property bool active: Config.ready && (Config.stream.manual || (Config.stream.auto && obsLive && !suppressed))
    readonly property var screens: Config.stream.screens || []

    // is this screen seen by the viewers right now?
    function onStream(name) {
        return active && (screens.length === 0 || screens.includes(name));
    }
    // effects (sparkles, loading screen, rays, cracks) on this screen
    function effectsOn(name) {
        return !(Config.stream.effects && onStream(name));
    }
    readonly property bool quiet: active && Config.stream.mute
    // the angel's screen during the stream: off the streamed screens, or none
    function angelScreen(wanted) {
        if (!active || !Config.stream.hideAngel || !wanted || !onStream(wanted.name))
            return wanted;
        return Shell.screens.find(s => !onStream(s.name)) || null;
    }

    function set(mode) {
        if (mode === "on")
            Config.stream.manual = true;
        else if (mode === "off") {
            Config.stream.manual = false;
            Config.stream.auto = false;
        } else if (mode === "auto") {
            Config.stream.manual = false;
            Config.stream.auto = true;
        } else if (mode === "toggle") {
            const on = !active;
            Config.stream.manual = on;
            suppressed = !on && obsLive;
        }
    }

    // Do not disturb for the stream; only undone when stream mode turned it on
    onActiveChanged: sync()
    Connections {
        target: Config
        function onReadyChanged() {
            root.sync();
        }
    }
    function sync() {
        if (!Config.ready)
            return;
        if (active && Config.stream.dnd && !Config.notifications.dnd) {
            Config.notifications.dnd = true;
            Config.stream.dndSet = true;
        } else if (!active && Config.stream.dndSet) {
            Config.stream.dndSet = false;
            Config.notifications.dnd = false;
        }
    }

    Process {
        id: watch
        running: Config.ready && Config.stream.auto
        command: ["python3", "-u", Quickshell.shellDir + "/scripts/obs-watch.py", "--port", String(Config.stream.port || 4455)]
        stdout: SplitParser {
            onRead: line => {
                if (line === "up") {
                    root.obsUp = true;
                    root.obsAuth = false;
                } else if (line === "down") {
                    root.obsUp = false;
                    root.obsLive = false;
                } else if (line === "live")
                    root.obsLive = true;
                else if (line === "off")
                    root.obsLive = false;
                else if (line === "auth")
                    root.obsAuth = true;
            }
        }
        onRunningChanged: if (!running) {
            root.obsUp = false;
            root.obsLive = false;
        }
    }
}
