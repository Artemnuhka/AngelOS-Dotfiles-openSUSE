pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Widgets on the wallpaper: which, where, with what settings. Dragged by their title bar.
Singleton {
    id: root

    property bool editMode: false

    // Every widget lives twice (DesktopWidgetHost): its face in the backdrop,
    // which niri never slides — so it stays put however a workspace switch
    // starts, and shows in the overview — and an input copy at opacity 0 on
    // angelos-desktop, which slides with the workspaces. The input copy only
    // shows over the face while a button in it is hovered or pressed, or in a
    // drag / edit mode; then it steps aside for a switch:
    //   a switch the shell starts (workspace keys via `angelos ws`, the bar):
    //   prepareSwitch() hides it and waits for that frame before niri moves;
    //   a switch niri starts by itself: onWorkspaceActivated, a few frames late —
    //   only ever with the pointer on a widget's button.
    property var asideUntil: ({})            // screen -> ms: input copies hidden until
    property double asideClock: 0
    function steppedAside(screen) {
        return Niri.overviewOpen || (asideUntil[screen] || 0) > asideClock;
    }
    // how long niri's slide takes (cfg/animation.kdl: preset × slowdown) and a margin
    readonly property int switchMs: Math.round(WorkspaceAnim.slideMs * WorkspaceAnim.slowdown) + 80
    function stepAside(screen, ms) {
        const now = Date.now();
        const u = Object.assign({}, asideUntil);
        u[screen] = Math.max(u[screen] || 0, now + (ms || switchMs));
        asideUntil = u;
        asideClock = now;
        // one clock for every screen: wake up when the last of them is done, or
        // an earlier screen's end would leave a later one stepped aside for good
        let last = now;
        for (const k in u)
            last = Math.max(last, u[k]);
        settle.interval = Math.max(1, last - now + 20);
        settle.restart();
    }
    Timer {
        id: settle
        onTriggered: root.asideClock = Date.now()
    }
    Connections {
        target: Niri
        function onWorkspaceActivated(ws, focused) {
            if (ws && !Niri.overviewOpen && !WorkspaceAnim.captured && WorkspaceAnim.current.id !== "instant")
                root.stepAside(ws.output);
        }
    }

    // ---- a switch the shell starts: an input copy on show hides first ----
    property var job: null                   // {screen, go, frames}
    readonly property bool preparing: job !== null
    function shownOn(screen) {
        for (const uid of uidsFor(screen)) {
            const h = hosts[uid];
            if (h && h.visible && h.shown)
                return true;
        }
        return false;
    }
    function prepareSwitch(screen, go) {
        if (job)
            advance();                       // another key before the last one got through
        if (!screen || !shownOn(screen)) {
            go();
            return;
        }
        stepAside(screen, switchMs + 200);   // niri's own event makes it exact
        job = {
            "screen": screen,
            "go": go,
            "frames": 0
        };
        jobGuard.restart();
    }
    // Background: a frame of the desktop surface reached the screen. Two frames
    // after the change, or one and then quiet, and the copy is gone from it.
    function framePresented(screen) {
        const j = job;
        if (!j || j.screen !== screen)
            return;
        j.frames++;
        if (j.frames >= 2)
            advance();
        else
            jobQuiet.restart();
    }
    function advance() {
        const j = job;
        if (!j)
            return;
        job = null;
        jobQuiet.stop();
        jobGuard.stop();
        j.go();
    }
    Timer {
        id: jobQuiet
        interval: 14
        onTriggered: root.advance()
    }
    // no frame at all (a stalled window): go on anyway
    Timer {
        id: jobGuard
        interval: 70
        onTriggered: root.advance()
    }

    // ---- heaven ⇄ hell: the widgets burn over (DesktopWidgetHost draws it) ----
    // While the demon rules (and Y2K → Widgets in hell is on) the widgets live in
    // hell. A swap holds them until the glass breaks (Angel.holdWidgets); then they
    // burn over in burnMs — the old look goes, Theme.realm flips at the middle and
    // the new one shows. At start-up they are simply where they belong.
    readonly property bool hellWanted: Config.ready && Angel.demon && Config.y2k.hellWidgets
    property real burn: 1                    // 0 → 1 through a burn-over; 1 = settled
    property string burnTo: ""               // "hell" | "heaven" while burning
    readonly property bool burning: burnTo !== ""
    readonly property int burnMs: 1500
    property bool _realmSet: false
    onHellWantedChanged: Qt.callLater(settleRealm)
    Component.onCompleted: Qt.callLater(settleRealm)
    Connections {
        target: Config
        function onReadyChanged() {
            Qt.callLater(root.settleRealm);
        }
    }
    Connections {
        target: Angel
        function onHoldWidgetsChanged() {
            if (!Angel.holdWidgets)
                Qt.callLater(root.settleRealm);
        }
    }
    function settleRealm() {
        if (!Config.ready || Angel.holdWidgets)
            return;
        const want = hellWanted ? "hell" : "heaven";
        if (!_realmSet) {
            _realmSet = true;
            Theme.realm = want;
            return;
        }
        if (want === (burning ? burnTo : Theme.realm))
            return;
        burnTo = want;
        burnAnim.restart();
    }
    // dev/owner (`angelos helper realm`): burn over to the other side and back, for a look
    function burnPreview(to) {
        burnTo = to === "hell" || to === "heaven" ? to : (Theme.hell ? "heaven" : "hell");
        burnAnim.restart();
        return burnTo;
    }
    NumberAnimation {
        id: burnAnim
        target: root
        property: "burn"
        from: 0
        to: 1
        duration: root.burnMs
        onFinished: {
            Theme.realm = root.burnTo || Theme.realm;
            root.burnTo = "";
            // the wish may have changed while it burned (a quick toggle)
            Qt.callLater(root.settleRealm);
        }
    }
    onBurnChanged: if (burnTo && burn >= 0.5 && Theme.realm !== burnTo)
        Theme.realm = burnTo

    property var hosts: ({})                 // uid -> DesktopWidgetHost, the input copy
    property var faces: ({})                 // uid -> DesktopWidgetHost, the face
    function registerFace(uid, item) {
        const m = Object.assign({}, faces);
        m[uid] = item;
        faces = m;
    }
    function unregisterFace(uid, item) {
        if (faces[uid] !== item)
            return;
        const m = Object.assign({}, faces);
        delete m[uid];
        faces = m;
    }
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
        },
        {
            // hell's own: offered, shown and spun only while the demon rules
            "type": "hellwheel",
            "label": I18n.t("Колесо Ада", "Wheel of Hell"),
            "icon": "pentagram",
            "title": "wheel666.exe",
            "hell": true
        }
    ]
    readonly property var pluginTypes: Plugins.desktopWidgets.map(p => ({
                "type": "plugin:" + p.id,
                "label": p.name,
                "icon": p.icon || "plug",
                "title": p.desktopTitle || (p.id + ".exe"),
                "plugin": p
            }))
    // the demon's widgets (the Wheel of Hell) don't exist in heaven: not offered, not shown
    // (they stay in the settings and come back with her)
    readonly property var types: builtin.filter(t => !t.hell || Angel.hellShown).concat(pluginTypes)
    readonly property var widgets: (Config.desktop.widgets || []).filter(w => !!typeInfo(w.type))

    // "clock.exe" → "clock.sh": the ending picked in Settings → Widgets
    readonly property var suffixes: ["exe", "sh", "bin"]
    function titleOf(info) {
        if (!info)
            return "";
        const ext = suffixes.includes(Config.desktop.titleSuffix) ? Config.desktop.titleSuffix : "exe";
        return String(info.title).replace(/\.[a-z0-9]{1,4}$/i, "") + "." + ext;
    }
    // widget size: 70–130 % of its natural size
    readonly property real minScale: 0.7
    readonly property real maxScale: 1.3
    function scaleOf(w) {
        return w && w.scale ? Math.max(minScale, Math.min(maxScale, w.scale)) : 1;
    }
    function setScale(uid, s) {
        const v = Math.round(Math.max(minScale, Math.min(maxScale, s)) * 100) / 100;
        _save((Config.desktop.widgets || []).map(w => w.uid === uid ? Object.assign({}, w, {
                    "scale": v
                }) : w));
    }

    function typeInfo(t) {
        return types.find(x => x.type === t) || null;
    }
    function byUid(uid) {
        return widgets.find(w => w.uid === uid) || null;
    }
    // a widget whose monitor isn't connected (unplugged, renamed) shows on the main screen
    function screenOf(w) {
        return !w || Quickshell.screens.some(s => s.name === w.screen) ? (w ? w.screen : "") : Shell.primaryName;
    }
    function uidsFor(screen) {
        return widgets.filter(w => screenOf(w) === screen).map(w => w.uid);
    }
    // Settings → Monitor → "Move every widget here": all of them onto one screen, as they are
    function moveAllTo(screen) {
        if (!screen)
            return 0;
        const moved = (Config.desktop.widgets || []).filter(w => w.screen !== screen).length;
        _save((Config.desktop.widgets || []).map(w => w.screen === screen ? w : Object.assign({}, w, {
                    "screen": screen
                })));
        return moved;
    }
    function has(type, screen) {
        return widgets.some(w => w.type === type && w.screen === screen);
    }

    function _save(list) {
        Config.desktop.widgets = list;
    }
    function add(type, screen, x, y) {
        screen = screen || Shell.primaryName;
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
            const first = Shell.primaryName || (Quickshell.screens[0] || {}).name || "DP-1";
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
