pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The game's debug panel (modules/debug/GameDebugWindow): everything in the game seen and
// changed at once, without playing through it — a window over `angelos game …` and
// `angelos helper …` (modules/Ipc) and what they lack. Developer mode only (Settings →
// System) or a dev instance (ANGELOS_DEV): it gives the whole story away, so a player never
// meets it — no settings page of its own, nothing in the settings search.
//   snapshot   the save and the settings copied aside (scripts/game-snapshot.py) and put back
//              with one button, the shell restarted on them: after the experiments all is as
//              it was. In hell the angel comes back first, so her pranks and the wallpaper
//              are undone before the files go back
//   overrides  a circle's look without the story (HellLook.circle), any circle's demon skin
//              in the corner, a cursor theme put on the system for a look — none of it saved
//   restart    the shell, the panel open again after it (the reopen marker in the state dir)
// The lists — circles, scenes, actions, breakage kinds, pranks, sounds, cursors — come from
// the data (story/*.json, the scenes' folder, the sound pack's folder), so new content shows
// up in the panel by itself.
Singleton {
    id: root

    readonly property bool allowed: Shell.dev || Config.developer.enabled
    property bool open: false
    readonly property bool shown: open && allowed
    property string tab: "state"
    // the last thing done, for the panel's status line
    property string log: ""
    function note(s) {
        log = new Date().toLocaleTimeString(Qt.locale(), "HH:mm:ss") + "  " + s;
        return s;
    }
    function toggle() {
        open = !open;
        return open ? "open" : "closed";
    }
    onAllowedChanged: if (!allowed)
        open = false

    // ---- overrides (never saved) ----
    // the demon in the corner wears this circle's skin ("" — the circle's own, "-" — none)
    property string skin: ""
    // hell's look of a circle without the story going there (Settings dress, menu, palette, cursor)
    function lookCircle(id) {
        HellLook.circle = id || "base";
        return note(I18n.t("облик круга: ", "the circle's look: ") + HellLook.circle);
    }
    function lookAsStory() {
        HellLook.circle = Story.inHell && Story.circle ? Story.circle : "base";
        return note(I18n.t("облик — как в сюжете", "the look follows the story"));
    }
    readonly property bool lookOverridden: HellLook.circle !== (Story.inHell && Story.circle ? Story.circle : "base")

    // ---- heaven ⇄ hell ----
    // at once: no fall, no splash, no quake, no sound (the comeback is counted, as in the game)
    function toHellNow(circle) {
        if (Angel.transition || Angel.demon)
            return note(I18n.t("уже в аду или идёт переход", "in hell already, or a switch is on"));
        Angel.hush();
        if (circle)
            Story._jumpTo = circle;
        Angel.swapAtOnce("toHell");
        return note(I18n.t("в аду: ", "in hell: ") + Story.circle);
    }
    function toHeavenNow() {
        if (Angel.transition || !Angel.demon)
            return note(I18n.t("уже в раю или идёт переход", "in heaven already, or a switch is on"));
        Angel.hush();
        Angel.swapAtOnce("ascend");
        return note(I18n.t("ангел вернулась (возвращений: ", "the angel is back (returns: ") + Story.player.returns + ")");
    }
    // into a circle without the dark and the blow: the path and the look as if entered
    function circleNow(id) {
        if (!Story.inHell)
            return toHellNow(id);
        Story.hell.path = (Story.hell.path || []).filter(x => x !== id).concat([id]);
        Story.hell.attempts = 0;
        Story.setCircle(id);
        return note(I18n.t("круг: ", "circle: ") + id);
    }

    // ---- the save, field by field ----
    function setSin(id, v) {
        const s = {};
        s[id] = Math.max(0, Math.round(v));
        Story.applySet(s);
    }
    function setClose(id, points) {
        const all = Object.assign({}, Story.hell.close || {});
        all[id] = Object.assign({}, all[id] || {}, {
            "points": Math.max(0, Math.round(points))
        });
        Story.hell.close = all;
    }
    // her talk / gift / stay ready again (their minutes forgotten)
    function closeReady(id) {
        const all = Object.assign({}, Story.hell.close || {});
        const rec = Object.assign({}, all[id] || {});
        delete rec.talkAt;
        delete rec.giftAt;
        delete rec.stayAt;
        all[id] = rec;
        Story.hell.close = all;
        Story._actedAt = ({});
    }
    // a day without a throw has passed: she thaws a step (not out of the cold route)
    function dayPassed() {
        Story.player.lastThrow = Story.now() - ((Story.angelRules.thawHours || 24) + 1) * 3600000;
        Story.player.thawAt = 0;
        Story.thaw();
        return note(I18n.t("прошли сутки: холод ", "a day passed: chill ") + Story.chill);
    }

    // ---- what she says ----
    // a line of the angel's step for a situation (story/angel.json), or of the circle's voice
    function sayFrom(list, who) {
        if (!list || !list.length)
            return note(I18n.t("нет реплик", "no lines"));
        const l = list[Math.floor(Math.random() * list.length)];
        const t = Story.render(Array.isArray(l) ? (I18n.english ? l[1] : l[0]) : I18n.label(l));
        Angel.say(t.replace("%1", Story.giftName()).replace("%m", "7"), null, 0);
        return note((who || "") + ": " + t);
    }
    // a long line, for the voice and the bubble
    function sayLong() {
        Angel.say(I18n.t("Это длинная проверочная реплика: я говорю долго, чтобы было слышно голос целиком, видно, как переносится текст в пузыре и не обрезается ли что-нибудь по краям. Раз, два, три — проверка связи.", "This is a long test line: I talk on and on so the whole voice can be heard, the bubble can be seen wrapping, and nothing gets cut at the edges. One, two, three — testing."), null, 0);
        return note(I18n.t("длинная реплика", "a long line"));
    }

    // ---- effects ----
    readonly property string screen: Angel.screenName || Shell.primaryName
    // her fist with this kind of breakage (HellLook.breakageKinds), on her screen
    function punch(kind) {
        Cracks.forceKind = kind || "";
        Angel.punched(screen, Story.calm ? "" : "crack");
        return note(I18n.t("удар: ", "a punch: ") + (kind || I18n.t("по кругу", "by the circle")));
    }
    function shatter() {
        Cracks.shatter();
        return note(I18n.t("стекло выпадает", "the glass falls out"));
    }
    function quake(kind) {
        Angel.quake(screen, kind);
        return note(I18n.t("тряска: ", "a quake: ") + kind);
    }
    function rays() {
        Angel.heaven(screen);
        return note(I18n.t("лучи и хор", "the rays and the choir"));
    }
    function circleShow(id) {
        CircleFx.run(id || Story.circle || "limbo", null, null);
        return note(I18n.t("заставка круга: ", "the circle's splash: ") + (id || Story.circle || "limbo"));
    }
    function prank(id) {
        return note(Angel.prankNow(id) ? I18n.t("проделка: ", "a prank: ") + id : I18n.t("не вышло (нужна демоница в углу): ", "didn't run (needs the demon in the corner): ") + id);
    }

    // ---- what is on disk: the sound pack's files, the demons' skins ----
    property var soundFiles: []          // full paths: the synthesised pack, then sounds/custom
    property var skins: []               // circles whose demon has her pictures (sprites/demon-<circle>/)
    function rescan() {
        lister.running = false;
        lister.running = true;
    }
    Process {
        id: lister
        command: ["sh", "-c", 'for d in "$1" "$2"; do for f in "$d"/*.ogg "$d"/*.wav "$d"/*.oga "$d"/*.mp3 "$d"/*.flac "$d"/*.opus; do [ -f "$f" ] && echo "sound $f"; done; done; for d in "$3"/demon-*/; do [ -f "$d/rig.json" ] && echo "skin $(basename "$d")"; done; exit 0', "sh", Sounds.dir, Sounds.customDir, Quickshell.shellDir + "/modules/y2k/sprites"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                root.soundFiles = lines.filter(l => l.startsWith("sound ")).map(l => l.slice(6));
                root.skins = lines.filter(l => l.startsWith("skin demon-")).map(l => l.slice(11)).filter(id => Story.order.includes(id));
            }
        }
    }
    onShownChanged: if (shown)
        rescan()

    // ---- sounds: any file of the pack (or any event, routed as the shell does) ----
    function playFile(path) {
        const name = String(path).split("/").pop().replace(/\.[^.]+$/, "");
        Quickshell.execDetached(["pw-play", "--volume", String(Sounds.volumeOf(name)), path]);
        return note("▶ " + name);
    }

    // ---- cursors: a theme on the system for a look, then back to what the game wants ----
    function cursorTry(theme) {
        Cursors.put(theme, Config.cursor.size || 24);
        return note(Shell.dev ? I18n.t("в dev-режиме курсор системы не меняется", "dev mode leaves the system cursor alone") : I18n.t("курсор: ", "cursor: ") + theme);
    }
    function cursorBack() {
        Cursors._attempt = "";
        Cursors.refresh();
        return note(I18n.t("курсор — как хочет игра", "the cursor the game wants"));
    }

    // ---- snapshot: the save and the settings aside, and back ----
    readonly property string snapScript: Quickshell.shellDir + "/scripts/game-snapshot.py"
    property var snapInfo: null          // {at, realm, circle, …} of the snapshot there is, or null
    property string snapBusy: ""         // take | restore
    function refreshSnap() {
        snapRead.running = false;
        snapRead.running = true;
    }
    Process {
        id: snapRead
        command: ["python3", root.snapScript, "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.snapInfo = JSON.parse(text).snapshot || null;
                } catch (e) {
                    root.snapInfo = null;
                }
            }
        }
    }
    function snapshot() {
        if (snapBusy)
            return "busy";
        snapBusy = "take";
        // the save's last change is on disk first (Story writes it 300 ms after a change)
        snapTake.restart();
        return note(I18n.t("снимок…", "taking a snapshot…"));
    }
    Timer {
        id: snapTake
        interval: 700
        onTriggered: {
            snapJob.command = ["python3", root.snapScript, "take"];
            snapJob.running = true;
        }
    }
    function restore() {
        if (snapBusy || !snapInfo)
            return "nothing to restore";
        snapBusy = "restore";
        Novel.stopScene();
        // in hell the angel comes back first: her pranks undone, the wallpaper given back
        if (Angel.demon || Angel.transition)
            Angel.leaveNow();
        snapPut.restart();
        return note(I18n.t("возвращаю снимок…", "restoring the snapshot…"));
    }
    Timer {
        id: snapPut
        // the settings and the save written after the angel's return land first
        interval: 1500
        onTriggered: {
            snapJob.command = ["python3", root.snapScript, "restore"];
            snapJob.running = true;
        }
    }
    Process {
        id: snapJob
        stdout: StdioCollector {
            onStreamFinished: {
                const was = root.snapBusy;
                root.snapBusy = "";
                let r = {};
                try {
                    r = JSON.parse(text);
                } catch (e) {
                    r = {
                        "error": text.trim() || "?"
                    };
                }
                if (r.error) {
                    root.note(I18n.t("снимок: ошибка — ", "snapshot: error — ") + r.error);
                    return;
                }
                root.snapInfo = r.snapshot || root.snapInfo;
                if (was === "restore") {
                    root.note(I18n.t("снимок возвращён, перезапуск…", "snapshot restored, restarting…"));
                    root.restart();
                } else {
                    root.note(I18n.t("снимок сделан", "snapshot taken"));
                }
            }
        }
    }

    // ---- the shell starts again; the panel comes back open on its tab ----
    function restart() {
        reopen.setText(tab || "state");
        later.restart();
        return note(I18n.t("перезапуск…", "restarting…"));
    }
    Timer {
        id: later
        interval: 250
        onTriggered: {
            if (Shell.dev)
                Quickshell.reload(true);
            else
                Quickshell.execDetached([Quickshell.shellDir + "/bin/angelos", "restart"]);
        }
    }
    FileView {
        id: reopen
        path: Config.stateDir + "/debug-reopen"
        printErrors: false
        blockLoading: true
    }
    Timer {
        // a beat after the start: Config (developer mode) has read its file
        running: true
        interval: 1500
        onTriggered: {
            const tab = String(reopen.text() || "").trim();
            if (tab) {
                reopen.setText("");
                root.tab = tab;
                root.open = root.allowed;
            }
            if (root.allowed)
                root.refreshSnap();
        }
    }
}
