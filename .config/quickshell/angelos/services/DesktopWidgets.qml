pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Widgets on the wallpaper: which, where, with what settings. Dragged by their title bar.
Singleton {
    id: root

    property bool editMode: false

    // Widgets are drawn inside the wallpaper surface, which niri keeps in the
    // backdrop: pinned while workspaces slide, a single copy in the overview.
    // The backdrop gets no input, so invisible proxies on the angelos-desktop
    // surface take the pointer and forward it (modules/desktop/WidgetProxy.qml).
    property var hosts: ({})                 // uid -> DesktopWidgetHost (the visible copy)
    property var drag: ({
            "uid": "",
            "x": 0,
            "y": 0
        })
    function registerHost(uid, item) {
        const m = Object.assign({}, hosts);
        m[uid] = item;
        hosts = m;
    }
    function unregisterHost(uid, item) {
        if (hosts[uid] !== item)
            return;
        const m = Object.assign({}, hosts);
        delete m[uid];
        hosts = m;
    }

    readonly property var builtin: [
        {
            "type": "clock",
            "label": I18n.t("Часы", "Clock"),
            "icon": "calendar",
            "title": "clock.exe"
        },
        {
            "type": "sysmon",
            "label": I18n.t("Системный монитор", "System monitor"),
            "icon": "chip",
            "title": "sysmon.exe"
        },
        {
            "type": "cava",
            "label": I18n.t("Визуализатор cava", "cava visualizer"),
            "icon": "music",
            "title": "cava.exe"
        },
        {
            "type": "nowplaying",
            "label": I18n.t("Сейчас играет", "Now playing"),
            "icon": "play",
            "title": "music.exe"
        }
    ]
    readonly property var pluginTypes: Plugins.desktopWidgets.map(p => ({
                "type": "plugin:" + p.id,
                "label": p.name,
                "icon": p.icon || "plug",
                "title": p.desktopTitle || (p.id + ".exe"),
                "plugin": p
            }))
    readonly property var types: builtin.concat(pluginTypes)
    readonly property var widgets: (Config.desktop.widgets || []).filter(w => !!typeInfo(w.type))

    function typeInfo(t) {
        return types.find(x => x.type === t) || null;
    }
    function byUid(uid) {
        return widgets.find(w => w.uid === uid) || null;
    }
    function uidsFor(screen) {
        return widgets.filter(w => w.screen === screen).map(w => w.uid);
    }
    function has(type, screen) {
        return widgets.some(w => w.type === type && w.screen === screen);
    }

    function _save(list) {
        Config.desktop.widgets = list;
    }
    function add(type, screen, x, y) {
        const n = widgets.filter(w => w.screen === screen).length;
        _save((Config.desktop.widgets || []).concat([{
                    "uid": type.replace(/[^\w-]/g, "_") + "-" + Date.now().toString(36),
                    "type": type,
                    "screen": screen,
                    // new widgets fill a loose grid instead of piling up
                    "x": x !== undefined ? x : Theme.u * (20 + (n % 3) * 170),
                    "y": y !== undefined ? y : Theme.u * (20 + Math.floor(n / 3) * 95),
                    "settings": ({})
                }]));
    }
    function remove(uid) {
        _save((Config.desktop.widgets || []).filter(w => w.uid !== uid));
    }
    function toggle(type, screen) {
        const w = widgets.find(w => w.type === type && w.screen === screen);
        if (w)
            remove(w.uid);
        else
            add(type, screen);
    }
    function move(uid, x, y) {
        const g = Config.desktop.snap ? Theme.u * 4 : 1;
        _save((Config.desktop.widgets || []).map(w => w.uid === uid ? Object.assign({}, w, {
                    "x": Math.round(x / g) * g,
                    "y": Math.round(y / g) * g
                }) : w));
    }
    function setScreen(uid, screen) {
        _save((Config.desktop.widgets || []).map(w => w.uid === uid ? Object.assign({}, w, {
                    "screen": screen
                }) : w));
    }
    function resetPosition(uid) {
        const w = byUid(uid);
        if (!w)
            return;
        const n = widgets.filter(x => x.screen === w.screen && x.uid !== uid).length;
        move(uid, Theme.u * (20 + (n % 3) * 170), Theme.u * (20 + Math.floor(n / 3) * 95));
    }
    function removeAll(screen) {
        _save((Config.desktop.widgets || []).filter(w => screen && w.screen !== screen));
    }
    function setSetting(uid, key, value) {
        _save((Config.desktop.widgets || []).map(w => {
            if (w.uid !== uid)
                return w;
            const s = Object.assign({}, w.settings || {});
            s[key] = value;
            return Object.assign({}, w, {
                "settings": s
            });
        }));
    }

    // first run: bring over the plugin widgets that used to place themselves
    Timer {
        running: Config.ready && !Config.desktop.initialized && Plugins.plugins.length > 0
        interval: 1500
        onTriggered: {
            const first = (Quickshell.screens[0] || {}).name || "DP-1";
            const list = (Config.desktop.widgets || []).slice();
            for (const p of Plugins.desktopWidgets) {
                if (list.some(w => w.type === "plugin:" + p.id))
                    continue;
                const pref = (Config.plugins.data[p.id] || {});
                list.push({
                    "uid": "plugin_" + p.id + "-init",
                    "type": "plugin:" + p.id,
                    "screen": pref.orbScreen || pref.screen || first,
                    "x": p.id === "claude-companion" ? Theme.u * 20 : -Theme.u * 20,
                    "y": p.id === "claude-companion" ? -Theme.u * 40 : Theme.u * 30,
                    "settings": ({})
                });
            }
            Config.desktop.widgets = list;
            Config.desktop.initialized = true;
        }
    }
}
