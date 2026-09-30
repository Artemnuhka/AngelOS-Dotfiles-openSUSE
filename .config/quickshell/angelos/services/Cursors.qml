pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Cursor theme: one theme everywhere (niri, GTK, Qt, X11/XWayland, Steam, Flatpak).
// scripts/cursors.py downloads/builds the themes and writes every config.
Singleton {
    id: root

    readonly property string theme: Config.cursor.theme || Quickshell.env("XCURSOR_THEME") || ""
    readonly property int size: Config.cursor.theme ? Config.cursor.size : (parseInt(Quickshell.env("XCURSOR_SIZE")) || 24)
    property var catalog: []
    property var other: []              // cursor themes found on the system
    property var status: ({})           // where which theme is set
    property string log: ""
    property string working: ""         // id / theme being installed or applied
    readonly property bool busy: worker.running
    readonly property string script: Quickshell.shellDir + "/scripts/cursors.py"

    function refresh() {
        if (!lister.running)
            lister.running = true;
    }
    function colors() {
        return ["--accent", Theme.hex(Theme.accent), "--edge", Theme.hex(Theme.edge), "--light", "#fff4fb"];
    }
    function install(id, thenApply) {
        if (worker.running)
            return;
        working = id;
        log = "";
        worker.after = thenApply ? id : "";
        worker.command = ["python3", script, "install", id].concat(colors());
        worker.running = true;
    }
    function apply(themeName, sz) {
        if (worker.running)
            return;
        Config.cursor.theme = themeName;
        Config.cursor.size = sz;
        if (Shell.dev) {
            log = I18n.t("В dev-режиме системные настройки курсора не меняются", "Dev mode does not change the system cursor");
            return;
        }
        working = themeName;
        log = "";
        worker.after = "";
        worker.command = ["python3", script, "apply", themeName, String(sz)].concat(Config.cursor.flatpak ? [] : ["--no-flatpak"]);
        worker.running = true;
    }
    // angelOS Pixel follows the accent: rebuild, then make niri reload the files
    function recolor() {
        install("angelos", true);
    }

    Process {
        id: lister
        running: true
        command: ["python3", root.script, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text);
                    if (r.error)
                        return;
                    root.catalog = r.catalog;
                    root.other = r.other;
                    root.status = r.status || {};
                } catch (e) {}
            }
        }
    }
    Process {
        id: worker
        property string after: ""
        stdout: StdioCollector {
            onStreamFinished: {
                let r = {};
                try {
                    r = JSON.parse(text);
                } catch (e) {
                    root.log = text.trim().slice(-300);
                }
                if (r.error)
                    root.log = I18n.t("Ошибка: ", "Error: ") + r.error;
                else if (r.done)
                    root.log = I18n.t("Готово: ", "Applied: ") + r.done.join(", ") + I18n.t(". Steam и открытые X11-программы подхватят курсор после перезапуска.", ". Steam and running X11 apps pick it up after a restart.");
                else if (r.theme && worker.after) {
                    // freshly built: apply it (a size nudge makes niri reload the same theme name)
                    const t = r.theme, sz = Config.cursor.size || 24;
                    Qt.callLater(() => {
                        if (Config.cursor.theme === t && !Shell.dev) {
                            worker.command = ["python3", root.script, "apply", t, String(sz + 1)];
                            worker.after = "";
                            worker.nudgeBack = sz;
                            worker.running = true;
                        } else {
                            root.apply(t, sz);
                        }
                    });
                }
            }
        }
        property int nudgeBack: 0
        onExited: {
            if (nudgeBack > 0) {
                const sz = nudgeBack;
                nudgeBack = 0;
                Qt.callLater(() => root.apply(Config.cursor.theme, sz));
                return;
            }
            root.working = "";
            root.refresh();
        }
    }
}
