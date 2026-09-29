pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Experimental sidebar: a bookmark tab on a screen edge opens a panel with
// toggles, media, sound, system stats and AI limits.
Singleton {
    id: root

    property bool open: false
    property bool dragging: false
    property string ghostEdge: ""
    property real ghostOffset: 0.5
    readonly property string screenName: Config.sidebar.screen || (Shell.primaryScreen ? Shell.primaryScreen.name : "")
    readonly property bool enabled: Config.sidebar.enabled && Shell.screenByName(screenName) !== null

    function toggle() {
        open = !open;
    }
    function has(section) {
        return (Config.sidebar.sections || []).includes(section);
    }
    function setSection(section, on) {
        const list = (Config.sidebar.sections || []).filter(s => s !== section);
        if (on)
            list.push(section);
        Config.sidebar.sections = list;
    }
    // nearest edge for a point on a w×h screen, and the position along it
    function snap(x, y, w, h) {
        const d = {
            "left": x,
            "right": w - x,
            "top": y,
            "bottom": h - y
        };
        const edge = Object.keys(d).reduce((a, b) => d[a] <= d[b] ? a : b);
        const along = edge === "left" || edge === "right" ? y / Math.max(1, h) : x / Math.max(1, w);
        return {
            "edge": edge,
            "offset": Math.max(0.03, Math.min(0.97, along))
        };
    }

    Connections {
        target: Shell
        function onLockedChanged() {
            root.open = false;
        }
    }
}
