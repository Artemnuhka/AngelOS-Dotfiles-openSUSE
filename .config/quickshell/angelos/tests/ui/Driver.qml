pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import qs.config
import qs.services
import qs.modules.settings
import qs.modules.y2k
import qs.widgets

// angelOS UI self-test, started by scripts/test-ui.sh (ANGELOS_TEST=1, Qt's
// offscreen platform, a throwaway HOME). Inside the real shell, so the type
// anchors of shell.qml are the ones in use:
//   pages     every settings page, simple view and Expert, loads (no errors)
//   previews  every preview scene loads and plays through its frames
//   search    settings search: 40 typical queries, average and worst time
//   rig       the helper's pictures (SpriteRig): both figures read, sized as
//             their rig.json says, swapped and played through without errors
//   rmb       a right click into the window's corner pixel does not crash Qt
// Prints "TEST <name> PASS|FAIL [detail]" and "TEST-PAGE <id>" markers (the
// script ties log errors to the page that caused them), "TEST DONE <n>" last.
Scope {
    id: root

    property int failures: 0
    function report(name, ok, detail) {
        if (!ok)
            failures++;
        console.log("TEST " + name + " " + (ok ? "PASS" : "FAIL") + (detail ? " " + detail : ""));
    }

    FloatingWindow {
        id: win
        implicitWidth: 1100
        implicitHeight: 780
        title: "angelOS self-test"
        color: Theme.desk

        SettingsView {
            id: view
            anchors.fill: parent
            hostWindow: win
        }
        PxPreview {
            id: preview
            visible: false
            width: Theme.u * 200
        }
        TestEvent {
            id: sim
        }
        SpriteRig {
            id: rig
        }
        RightClickGuard {}
    }
    // a window that never takes focus, like the shell's layer-shell panels: Qt
    // 6.11 crashes on a right click at its (0,0) unless something accepts it
    // another window takes the focus, so `bare` has no active focus item
    Window {
        id: focusThief
        width: 40
        height: 40
        visible: false
    }
    Window {
        id: bare
        width: 160
        height: 120
        visible: false
        flags: Qt.WindowDoesNotAcceptFocus
        color: Theme.desk
        RightClickGuard {}
    }

    readonly property var queries: ["обои", "звук", "крупнее", "прозрачность панели", "хоткеи", "курсор", "шрифт", "блокировка", "заставка", "уведомления", "bluetooth", "wi-fi", "монитор", "частота обновления", "раскладка", "скорость мыши", "тёмная тема", "цвет", "лирика", "виджеты", "часы", "пуск", "панель сверху", "остров", "анимация", "сердечки", "скриншот", "запись экрана", "геймпад", "плагины", "обновления", "ангел", "демон", "стрим", "wallpaper", "volume", "bigger", "shortcuts", "transparency", "notifications"]
    // variants worth playing per scene ("" = the scene's default)
    readonly property var variants: ({
            "WallpaperFx": Wallpapers.transitions.map(t => t.id),
            "StartMenu": ["classic", "win11", "fullscreen"],
            "BarStyle": ["taskbar", "top", "island"],
            "DeskSwitch": WorkspaceAnim.styles.map(s => s.id),
            "LockScreen": ["pixelate", "hearts", "reactions", "indicators", "stream"],
            "CaptureSkin": ["ropes", "window", "stream"]
        })

    property string phase: "wait"
    property var list: []
    property int index: -1
    property double started: 0
    property bool expertPass: false
    property bool undoFrom: false
    property bool undoDone: false
    property int undoSteps: 0

    Timer {
        id: tick
        interval: 20
        repeat: true
        running: true
        onTriggered: root.step()
    }
    // a whole run must not hang CI
    Timer {
        interval: 100000
        running: true
        onTriggered: {
            root.report("timeout", false, "phase " + root.phase);
            root.finish();
        }
    }

    function finish() {
        tick.stop();
        console.log("TEST DONE " + failures);
        Qt.callLater(Qt.quit);
    }

    function startPages(expert) {
        expertPass = expert;
        Config.settingsUi.expert = expert;
        const ids = view.allPages.map(p => p.id);
        list = expert ? ids : ["home", "more"].concat(ids);
        index = -1;
        phase = "pages";
        nextPage();
    }
    function nextPage() {
        index++;
        if (index >= list.length) {
            if (!expertPass)
                startPages(true);
            else
                startPreviews();
            return;
        }
        console.log("TEST-PAGE " + list[index]);
        Shell.settingsPage = list[index];
        started = Date.now();
    }
    function startPreviews() {
        const names = preview.sceneNames;
        list = [];
        for (const s of names)
            for (const v of [""].concat(variants[s] || []))
                list.push([s, v]);
        index = -1;
        phase = "previews";
        preview.visible = true;
        nextPreview();
    }
    function nextPreview() {
        index++;
        if (index >= list.length) {
            preview.visible = false;
            phase = "search";
            started = Date.now();
            return;
        }
        console.log("TEST-PAGE preview:" + list[index][0]);
        preview.scene = list[index][0];
        preview.variant = list[index][1];
        preview.frame = 0;
        started = Date.now();
    }

    function step() {
        if (phase === "wait") {
            if (Config.ready && view.allPages.length > 0)
                startPages(false);
            return;
        }
        if (phase === "pages") {
            const d = view.diagnostics();
            const ms = Date.now() - started;
            if (d.status === Loader.Loading && ms < 8000)
                return;
            const name = (expertPass ? "page-expert:" : "page:") + list[index];
            report(name, d.status === Loader.Ready, d.status === Loader.Ready ? ms + " ms" : "status " + d.status + " " + d.source);
            nextPage();
            return;
        }
        if (phase === "previews") {
            const [scene, variant] = list[index];
            if (preview.stageStatus === Loader.Loading && Date.now() - started < 4000)
                return;
            if (preview.stageStatus !== Loader.Ready) {
                report("preview:" + scene + (variant ? "/" + variant : ""), false, "status " + preview.stageStatus);
                nextPreview();
                return;
            }
            // play the scene through, a few frames per tick
            if (preview.frame < preview.frames) {
                preview.frame = Math.min(preview.frames, preview.frame + 4);
                return;
            }
            report("preview:" + scene + (variant ? "/" + variant : ""), true, "");
            nextPreview();
            return;
        }
        if (phase === "search") {
            if (!SettingsSearch.loaded) {
                SettingsSearch.load();
                if (Date.now() - started < 15000)
                    return;
            }
            let worst = 0, total = 0, empty = 0;
            for (const q of queries) {
                const t0 = Date.now();
                const r = SettingsSearch.search(q + " ", 14);   // a fresh key: no cache
                const ms = Date.now() - t0;
                worst = Math.max(worst, ms);
                total += ms;
                if (!r || r.length === 0)
                    empty++;
            }
            const avg = total / queries.length;
            report("search-speed", SettingsSearch.loaded && avg <= 15 && worst <= 60, "avg " + avg.toFixed(1) + " ms, worst " + worst + " ms");
            report("search-results", empty <= 4, empty + "/" + queries.length + " queries found nothing");
            phase = "nav";
            return;
        }
        if (phase === "nav") {
            // simple view: "Back" returns to "All sections", not to the home tiles
            Config.settingsUi.expert = false;
            Shell.settingsPage = "home";
            Shell.settingsPage = "more";
            Shell.settingsPage = "fonts";
            const label = view.backLabel;
            view.back();
            const first = Shell.settingsPage;
            view.back();
            report("nav-back", first === "more" && Shell.settingsPage === "home", "fonts → " + first + " (" + label + ") → " + Shell.settingsPage);
            // settings undo puts a changed setting back
            const before = Config.appearance.shadows;
            phase = "undo";
            started = Date.now();
            undoSteps = Config.undoStack.length;
            Config.appearance.shadows = !before;
            undoFrom = before;
            return;
        }
        if (phase === "undo") {
            // wait for the save (debounced) that records the step
            if (Config.undoStack.length <= undoSteps && !undoDone && Date.now() - started < 3000)
                return;
            if (phase === "undo" && !undoDone) {
                undoDone = true;
                Config.undo();
                started = Date.now();
                return;
            }
            if (Config.appearance.shadows !== undoFrom && Date.now() - started < 3000)
                return;
            report("settings-undo", Config.appearance.shadows === undoFrom, "shadows back to " + Config.appearance.shadows);
            // "Reset this page" brings defaults back
            Config.appearance.px = 4;
            Config.resetKeys(["appearance.px"]);
            report("settings-reset", Config.appearance.px === Config.defaults.appearance.px, "px " + Config.appearance.px);
            console.log("TEST-PAGE sprite-rig");
            phase = "rig";
            return;
        }
        if (phase === "rig") {
            // the swap flips `who` in one go; every frame of every part gets shown
            const seen = [];
            for (const who of ["angel", "demon", "angel"]) {
                rig.who = who;
                const r = rig.rig;
                if (!rig.ready)
                    seen.push(who + " FAIL: no rig");
                else if (rig.implicitWidth !== r.size[0] * rig.px || rig.implicitHeight !== r.size[1] * rig.px || rig.body.width !== r.body.w * rig.px)
                    seen.push(who + " FAIL: " + rig.implicitWidth + "×" + rig.implicitHeight + " for " + r.size);
                else
                    seen.push(who + " " + r.size[0] + "×" + r.size[1] + " " + Object.keys(r.parts).join("+"));
                for (let i = 0; i < 16; i++) {
                    rig.tick = i;
                    rig.blink = i % 3 === 0;
                    rig.talk = i % 2 === 0;
                }
                rig.flutter = !rig.flutter;
            }
            report("sprite-rig", seen.every(s => s.indexOf("FAIL") < 0), seen.join(", "));
            phase = "rmb";
            return;
        }
        if (phase === "rmb") {
            bare.visible = true;
            phase = "rmb-focus";
            return;
        }
        if (phase === "rmb-focus") {
            focusThief.visible = true;
            focusThief.requestActivate();
            phase = "rmb-click";
            started = Date.now();
            return;
        }
        if (phase === "rmb-click") {
            if (bare.activeFocusItem !== null && Date.now() - started < 1500)
                return;
            // Qt 6.11 dies on a right click into pixel (0,0) nobody accepts while
            // the window has no focus item (tests/qt/tst_rightclick_origin.qml);
            // widgets/RightClickGuard takes it
            sim.mouseClick(bare.contentItem, 0, 0, Qt.RightButton, Qt.NoModifier, -1);
            sim.mouseClick(win.contentItem, 0, 0, Qt.RightButton, Qt.NoModifier, -1);
            phase = "rmb-alive";
            return;
        }
        if (phase === "rmb-alive") {
            report("rmb-corner", true, "still alive (focus item: " + bare.activeFocusItem + ")");
            finish();
        }
    }
}
