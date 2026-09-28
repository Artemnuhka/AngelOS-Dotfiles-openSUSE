pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Plugin registry. A plugin is a folder with manifest.json (see docs/PLUGINS.md):
//   ~/.config/angelos/plugins/<id>/   (user)
//   <shell>/plugins/<id>/              (bundled examples)
Singleton {
    id: root

    readonly property string bundledDir: Quickshell.shellDir + "/plugins"
    readonly property string userDir: Config.pluginsDir
    property var plugins: []
    property bool scanning: scanner.running

    // JsonAdapter can emit map changes even when membership is unchanged.
    // Keep service/component models stable across unrelated settings saves.
    readonly property string enabledIds: JSON.stringify(plugins.filter(p => isEnabled(p)).map(p => p.id))
    readonly property var enabledPlugins: JSON.parse(enabledIds).map(id => byId(id)).filter(p => !!p)
    readonly property var menuEntries: {
        const out = [];
        for (const p of enabledPlugins)
            for (const m of (p.menu || []))
                out.push(Object.assign({
                    "plugin": p.id
                }, m));
        return out;
    }
    readonly property var menuComponents: enabledPlugins.filter(p => !!p.menuComponent)
    readonly property var barWidgets: enabledPlugins.filter(p => !!p.barWidget)
    readonly property var desktopWidgets: enabledPlugins.filter(p => !!p.desktopWidget)
    readonly property var services: enabledPlugins.filter(p => !!p.main)
    readonly property var settingsPages: enabledPlugins.filter(p => !!p.settings)
    readonly property var launcherProviders: enabledPlugins.filter(p => !!p.launcher)

    function isEnabled(p) {
        const e = (Config.plugins.enabled || {})[p.id];
        return e === undefined ? p.enabledByDefault !== false : !!e;
    }
    function setEnabled(id, on) {
        Config.setIn(Config.plugins, "enabled", id, !!on);
    }
    function byId(id) {
        return plugins.find(p => p.id === id) || null;
    }
    function url(p, rel) {
        return "file://" + p.dir + "/" + rel;
    }
    function settingsOf(id) {
        return (Config.plugins.data || {})[id] || {};
    }
    function saveSettings(id, obj) {
        Config.setIn(Config.plugins, "data", id, obj);
    }

    // context object handed to every plugin component as `plugin`
    property var _ctx: ({})
    function context(p) {
        if (_ctx[p.id] && _ctx[p.id].dir === p.dir)
            return _ctx[p.id];
        const c = {
            "id": p.id,
            "dir": p.dir,
            "manifest": p,
            "url": rel => url(p, rel),
            "settings": () => settingsOf(p.id),
            "get": (key, def) => {
                const s = settingsOf(p.id);
                return s[key] === undefined ? def : s[key];
            },
            "set": (key, value) => {
                const s = Object.assign({}, settingsOf(p.id));
                s[key] = value;
                saveSettings(p.id, s);
            }
        };
        _ctx[p.id] = c;
        return c;
    }

    function run(entry) {
        if (entry.exec)
            Quickshell.execDetached(["sh", "-c", entry.exec]);
        if (entry.settings)
            Shell.openSettings(entry.settings);
        if (entry.url)
            Quickshell.execDetached(["xdg-open", entry.url]);
    }

    function reload() {
        scanner.running = false;
        scanner.running = true;
    }

    // scaffold a new plugin from plugins/_template
    function create(id, name) {
        id = id.replace(/[^a-z0-9_-]/gi, "-").toLowerCase();
        if (!id)
            return;
        creator.command = ["sh", "-c", 'set -e; d="$2/$3"; [ -e "$d" ] && exit 3; mkdir -p "$2"; cp -r "$1/_template" "$d"; sed -i "s/__ID__/$3/g; s/__NAME__/$4/g" "$d"/manifest.json "$d"/*.qml', "sh", bundledDir, userDir, id, name || id];
        creator.running = true;
    }
    signal created(string id, bool ok)

    Process {
        id: creator
        onExited: code => {
            root.created(creator.command[6], code === 0);
            root.reload();
        }
    }

    Component.onCompleted: reload()
    Connections {
        target: Quickshell
        function onReloadCompleted() {
            root.reload();
        }
    }

    Process {
        id: scanner
        command: ["sh", "-c", 'for f in "$1"/*/manifest.json "$2"/*/manifest.json; do [ -f "$f" ] || continue; case "$f" in */_template/*) continue;; esac; printf "%s\\t" "$(dirname "$f")"; tr -d "\\n\\r" < "$f"; echo; done', "sh", root.bundledDir, root.userDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;
                    const dir = line.slice(0, tab);
                    try {
                        const m = JSON.parse(line.slice(tab + 1));
                        m.dir = dir;
                        m.id = m.id || dir.split("/").pop();
                        m.bundled = dir.startsWith(root.bundledDir);
                        m.name = m.name || m.id;
                        map[m.id] = m; // user plugins (scanned last) override bundled ones
                    } catch (e) {
                        console.warn("angelOS plugin: bad manifest in", dir, e);
                    }
                }
                root.plugins = Object.values(map).sort((a, b) => a.name.localeCompare(b.name));
            }
        }
    }
}
