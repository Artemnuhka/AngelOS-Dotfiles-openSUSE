pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Apps for the Start menu styles: search, pinned, frequent, launching.
Singleton {
    id: root

    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => String(a.name).localeCompare(String(b.name)))
    readonly property var usage: Config.launcher.usage || {}
    readonly property var frequent: apps.filter(a => (usage[a.id] || 0) > 0).sort((a, b) => (usage[b.id] || 0) - (usage[a.id] || 0))
    // pinned by hand first, topped up with the most used apps
    readonly property var pinned: {
        const ids = Config.bar.startPinned || [];
        const list = ids.map(id => apps.find(a => a.id === id)).filter(a => !!a);
        for (const a of frequent) {
            if (list.length >= 18)
                break;
            if (!list.includes(a))
                list.push(a);
        }
        for (const a of apps) {
            if (list.length >= 12)
                break;
            if (!list.includes(a))
                list.push(a);
        }
        return list;
    }

    function isPinned(app) {
        return (Config.bar.startPinned || []).includes(app.id);
    }
    function togglePin(app) {
        const ids = (Config.bar.startPinned || []).slice();
        const i = ids.indexOf(app.id);
        if (i >= 0)
            ids.splice(i, 1);
        else
            ids.push(app.id);
        Config.bar.startPinned = ids;
    }
    function score(app, q) {
        const name = (app.name || "").toLowerCase();
        if (!q)
            return 1;
        if (name.startsWith(q))
            return 100 - name.length / 10;
        if (name.includes(q))
            return 70 - name.indexOf(q);
        const extra = ((app.genericName || "") + " " + String(app.keywords || "") + " " + (app.id || "")).toLowerCase();
        if (extra.includes(q))
            return 40;
        let i = 0;
        for (const ch of name)
            if (ch === q[i])
                i++;
        return i === q.length ? 20 - name.length / 20 : -1;
    }
    function search(text) {
        const q = String(text || "").trim().toLowerCase();
        if (!q)
            return apps;
        return apps.map(a => ({
                    "a": a,
                    "s": score(a, q) + Math.min(30, (usage[a.id] || 0) * 2)
                })).filter(r => r.s > 0).sort((x, y) => y.s - x.s).map(r => r.a);
    }
    function launch(app) {
        if (!app)
            return;
        const u = Object.assign({}, Config.launcher.usage || {});
        u[app.id] = (u[app.id] || 0) + 1;
        Config.launcher.usage = u;
        if (app.runInTerminal)
            Shell.exec(Shell.terminalArgv(app.command), app.workingDirectory);
        else if (app.command && app.command.length)
            Shell.exec(app.command, app.workingDirectory);
        else
            app.execute();
    }
    readonly property string userName: Quickshell.env("USER") || "angel"
}
