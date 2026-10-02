pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.modules.bar.parts

// One bar widget by id ("clock", "tray", "plugin:cat", …).
Loader {
    id: root

    required property string wid
    required property var bar          // BarContent: screenName, barWindow, above, compact, itemHeight, …
    property bool fillTasks: false
    property real lyricsMax: Theme.u * 150
    // the dense right side: narrower buttons (widgets built on PxButton)
    property bool dense: false
    onLoaded: if (item && item.hpad !== undefined)
        item.hpad = Qt.binding(() => root.dense ? Theme.u * 2 : -1)

    readonly property bool tall: wid === "start" || wid === "tasks" || wid === "media" || wid === "lyrics"
    // Windows 11-like centred taskbar: the window buttons as wide as they need, shrinking when crowded
    property bool centered: false
    Layout.fillWidth: (fillTasks || centered) && wid === "tasks"
    // compact "Windows": grows only as far as its buttons need, the next widgets follow right after (issue #16)
    Layout.maximumWidth: wid === "tasks" && (centered || (fillTasks && Config.bar.tasksWidth === "compact")) && item ? Math.max(Theme.u * 16, item.naturalWidth) : Number.POSITIVE_INFINITY
    Layout.minimumWidth: wid === "tasks" ? Theme.u * 16 : -1
    Layout.preferredWidth: wid === "tasks" ? (centered && item ? Math.max(Theme.u * 16, item.naturalWidth) : fillTasks ? Theme.u * 16 : Theme.u * 120) : -1
    Layout.preferredHeight: tall ? bar.itemHeight : -1
    Layout.alignment: Qt.AlignVCenter
    // Never bind a parent's visibility to its child's effective visibility:
    // once hidden during a track change, both can otherwise stay hidden.
    visible: {
        if (wid === "tasks")
            return Config.bar.showWindows;
        // network indicators show only where there is such hardware
        if (wid === "wifi")
            return Wifi.available && Wifi.hasWifi && Config.network.showWifi;
        if (wid === "bluetooth")
            return Bt.available && Config.network.showBluetooth;
        if (wid === "wired")
            return Wifi.available && !!Wifi.wiredDevice && Config.network.showWired;
        if (wid === "media")
            return Config.bar.showMedia && !!Lyrics.player && Lyrics.title !== "";
        if (wid === "lyrics")
            return Config.lyrics.enabled && Lyrics.visibleToggle && Lyrics.hasLyrics && (!Config.lyrics.screens.length || Config.lyrics.screens.includes(bar.screenName)) && lyricsMax >= Theme.u * 50;
        return true;
    }

    // guided tips find bar elements by "bar:<id>"
    Component.onCompleted: if (bar && bar.barWindow)
        Tour.register("bar:" + wid, root, bar.barWindow)
    Component.onDestruction: Tour.unregister("bar:" + wid, root)

    sourceComponent: {
        switch (wid) {
        case "start":
            return startC;
        case "workspaces":
            return wsC;
        case "tasks":
            return tasksC;
        case "lyrics":
            return lyricsC;
        case "media":
            return mediaC;
        case "tray":
            return trayC;
        case "layout":
            return layoutC;
        case "volume":
            return volumeC;
        case "bell":
            return bellC;
        case "wifi":
            return wifiC;
        case "bluetooth":
            return btC;
        case "wired":
            return wiredC;
        case "clock":
            return clockC;
        default:
            return wid.startsWith("plugin:") ? pluginC : null;
        }
    }

    Component {
        id: startC
        StartButton {
            small: root.bar.compact || (root.bar.style !== "taskbar" && root.bar.style !== "windose")
            above: root.bar.above
            screenName: root.bar.screenName
            barWindow: root.bar.barWindow
        }
    }
    Component {
        id: wsC
        Workspaces {
            screenName: root.bar.screenName
        }
    }
    Component {
        id: tasksC
        Tasks {
            screenName: root.bar.screenName
            above: root.bar.above
            iconsOnly: root.bar.compact || root.bar.style === "island" || root.bar.style === "dock" || !Config.bar.taskLabels
            dock: root.bar.style === "dock"
            visible: Config.bar.showWindows
        }
    }
    Component {
        id: lyricsC
        BarLyrics {
            screenName: root.bar.screenName
            maxWidth: root.lyricsMax
            fixedWidth: true
        }
    }
    Component {
        id: mediaC
        Media {
            maxWidth: root.bar.compact ? 0 : Theme.u * 130
            showTitle: !root.bar.lyricsShown
            visible: Config.bar.showMedia && !!Lyrics.player && Lyrics.title !== ""
        }
    }
    Component {
        id: trayC
        Tray {
            above: root.bar.above
        }
    }
    Component {
        id: layoutC
        KbLayout {}
    }
    Component {
        id: volumeC
        Volume {
            above: root.bar.above
            showPercent: !root.bar.compact && (root.bar.style === "taskbar" || root.bar.style === "windose")
        }
    }
    Component {
        id: bellC
        Bell {}
    }
    Component {
        id: wifiC
        WifiButton {
            above: root.bar.above
        }
    }
    Component {
        id: btC
        BluetoothButton {
            above: root.bar.above
        }
    }
    Component {
        id: wiredC
        WiredButton {
            above: root.bar.above
        }
    }
    Component {
        id: clockC
        Clock {
            screenName: root.bar.screenName
            above: root.bar.above
            showDate: root.bar.style === "taskbar" || root.bar.style === "windose"
        }
    }
    Component {
        id: pluginC
        Loader {
            readonly property var p: Plugins.byId(root.wid.slice(7))
            // a new path after the plugin was changed (Plugin Studio): load the new files
            readonly property string src: p ? Plugins.url(p, p.barWidget) : ""
            function load() {
                if (p && !item)
                    setSource(src, {
                        "plugin": Plugins.context(p),
                        "screenName": root.bar.screenName,
                        "barWindow": root.bar.barWindow
                    });
            }
            onPChanged: load()
            onSrcChanged: if (item) {
                source = "";
                load();
            }
            Component.onCompleted: load()
        }
    }
}
