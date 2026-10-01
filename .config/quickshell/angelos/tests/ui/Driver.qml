pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import QtTest
import Quickshell
import qs.config
import qs.services
import qs.modules.settings
import qs.modules.y2k
import qs.modules.alttab
import qs.modules.bar
import qs.modules.bar.parts
import qs.widgets

// angelOS UI self-test, started by scripts/test-ui.sh (ANGELOS_TEST=1, Qt's
// offscreen platform, a throwaway HOME). Inside the real shell, so the type
// anchors of shell.qml are the ones in use:
//   pages     every settings page, simple view and Expert, loads (no errors)
//   previews  every preview scene loads and plays through its frames
//   search    settings search: 40 typical queries, average and worst time
//   rig       the helper's pictures (SpriteRig): both figures read, sized as
//             their rig.json says, swapped and played through without errors
//   alttab    the three Alt+Tab switcher styles load and follow the pick
//   bar       bar widgets (Wi-Fi, Bluetooth, wired, tray, desk sprites) load, their panels open
//   wrap      long switch labels wrap inside a narrow group instead of running past it
//   start     every Start look (the bodies of StartOverlay) loads, searches, walks with the keys, Esc closes
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
        // the Alt+Tab switcher's looks, with a stand-in for its window
        Loader {
            id: altTabStage
            property string style: ""
            active: style !== ""
            sourceComponent: style === "ngo" ? atNgo : style === "y2k" ? atY2k : atAngel
        }
        Component {
            id: atAngel
            AltTabAngel {
                host: altTabHost
            }
        }
        Component {
            id: atNgo
            AltTabNgo {
                host: altTabHost
            }
        }
        Component {
            id: atY2k
            AltTabY2k {
                host: altTabHost
            }
        }
        // bar widgets outside a real bar (the layer-shell bar needs a compositor)
        Loader {
            id: barStage
            active: false
            sourceComponent: Row {
                property alias wifi: wifiW
                property alias bt: btW
                property alias wired: wiredW
                property alias tray: trayW
                WifiButton {
                    id: wifiW
                }
                BluetoothButton {
                    id: btW
                }
                WiredButton {
                    id: wiredW
                }
                Tray {
                    id: trayW
                }
                Workspaces {
                    screenName: "TEST-1"
                }
            }
        }
        // switch labels on a page as narrow as the grimoire's right one
        Loader {
            id: wrapStage
            active: false
            sourceComponent: Column {
                id: wrapPage
                readonly property string long: "Калькулятор: 2+2·3, 15% от 200, 10 км в милях, 100 usd в rub"
                property alias group: groupW
                property alias direct: directT
                property alias inRow: rowT
                property alias row: rowW
                property alias inColumn: colT
                property alias row2: row2W
                property alias short: shortT
                property alias free: freeT
                width: Theme.u * 170
                PxGroup {
                    id: groupW
                    width: parent.width
                    title: "wrap"
                    PxToggle {
                        id: directT
                        text: wrapPage.long
                    }
                    PxToggle {
                        id: shortT
                        text: "Да"
                    }
                    SettingRow {
                        id: rowW
                        label: "Поиск"
                        PxToggle {
                            id: rowT
                            text: wrapPage.long
                        }
                    }
                    SettingRow {
                        id: row2W
                        label: "Поиск"
                        Column {
                            width: parent.width
                            PxToggle {
                                id: colT
                                text: wrapPage.long
                            }
                        }
                    }
                }
                // nothing fixes the width here: the label stays on one line
                Row {
                    PxToggle {
                        id: freeT
                        text: wrapPage.long
                    }
                }
            }
        }
        // the Start looks outside their layer-shell overlay
        Loader {
            id: startStage
            property string style: ""
            active: style !== ""
            sourceComponent: ({
                    "classic": stClassic,
                    "win11": stWin11,
                    "fullscreen": stFull,
                    "xmb": stXmb,
                    "windose": stWindose,
                    "wii": stWii,
                    "spotlight": stSpot
                })[style] || null
        }
        Component {
            id: stClassic
            StartMenuBody {}
        }
        Component {
            id: stWin11
            StartWin11 {}
        }
        Component {
            id: stFull
            StartFullscreen {
                width: 1100
                height: 780
            }
        }
        Component {
            id: stXmb
            StartXmb {
                width: 1100
                height: 780
            }
        }
        Component {
            id: stWindose
            StartWindose {}
        }
        Component {
            id: stWii
            StartWii {
                width: 1100
                height: 780
            }
        }
        Component {
            id: stSpot
            StartSpotlight {}
        }
        QtObject {
            id: altTabHost
            property var screen: null
            function appName(w) {
                return w ? w.app_id : "";
            }
            function place(w) {
                return w ? "desk " + w.workspace_id : "";
            }
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
            "StartMenu": ["classic", "win11", "fullscreen", "xmb", "windose", "wii", "spotlight"],
            "BarStyle": ["taskbar", "top", "island"],
            "DeskSwitch": WorkspaceAnim.styles.map(s => s.id),
            "OpenFx": WindowAnim.openStyles.map(s => s.id),
            "CloseFx": WindowAnim.closeStyles.map(s => s.id),
            "LockScreen": ["pixelate", "hearts", "reactions", "indicators", "stream"],
            "CaptureSkin": ["ropes", "window", "stream"]
        })

    property string phase: "wait"
    property var list: []
    property int index: -1
    property double started: 0
    property bool expertPass: false
    property bool undoFrom: false
    property var altTabStyles: []
    property var startStyles: []
    property var startSeen: []
    property bool startTried: false
    property var altTabSeen: []
    property string altTabShot: ""
    readonly property string shots: Quickshell.env("ANGELOS_TEST_SHOTS") || ""
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
            // the chibi pictures and the glitch ones (the default look), both figures each
            for (const [variant, who] of [["", "angel"], ["", "demon"], ["", "angel"], ["glitch", "angel"], ["glitch", "demon"], ["", "demon"]]) {
                rig.variant = variant;
                rig.who = who;
                const r = rig.rig;
                const name = (variant ? variant + " " : "") + who;
                if (!rig.ready)
                    seen.push(name + " FAIL: no rig");
                else if (rig.implicitWidth !== r.size[0] * rig.px || rig.implicitHeight !== r.size[1] * rig.px || rig.body.width !== r.body.w * rig.px)
                    seen.push(name + " FAIL: " + rig.implicitWidth + "×" + rig.implicitHeight + " for " + r.size);
                else
                    seen.push(name + " " + r.size[0] + "×" + r.size[1] + " " + Object.keys(r.parts).join("+"));
                for (let i = 0; i < 16; i++) {
                    rig.tick = i;
                    rig.blink = i % 3 === 0;
                    rig.talk = i % 2 === 0;
                }
                rig.flutter = !rig.flutter;
            }
            report("sprite-rig", seen.every(s => s.indexOf("FAIL") < 0), seen.join(", "));
            console.log("TEST-PAGE alttab");
            AltTab.items = [1, 2, 3, 4, 5].map(i => ({
                        "id": 9000 + i,
                        "app_id": ["kitty", "helium", "discord", "org.gnome.Nautilus", "unknown.app"][i - 1],
                        "title": "window " + i,
                        "workspace_id": i
                    }));
            AltTab.index = 1;
            altTabStyles = ["angelos", "ngo", "y2k"];
            altTabSeen = [];
            phase = "alttab";
            started = Date.now();
            return;
        }
        if (phase === "alttab") {
            if (!altTabStage.style) {
                altTabStage.style = altTabStyles[altTabSeen.length];
                started = Date.now();
                return;
            }
            if (altTabStage.status === Loader.Loading && Date.now() - started < 4000)
                return;
            const it = altTabStage.item;
            const ok = altTabStage.status === Loader.Ready && it && it.implicitWidth > 0 && it.implicitHeight > 0;
            // ANGELOS_TEST_SHOTS=<dir>: a picture of each style to look at
            if (ok && shots && !altTabShot) {
                altTabShot = "wait";
                it.width = it.implicitWidth;
                it.height = it.implicitHeight;
                const name = shots + "/alttab-" + altTabStage.style + ".png";
                it.grabToImage(r => {
                    r.saveToFile(name);
                    root.altTabShot = "done";
                });
                return;
            }
            if (altTabShot === "wait" && Date.now() - started < 3000)
                return;
            altTabShot = "";
            for (let i = 0; i < 6; i++)
                AltTab.index = (AltTab.index + 1) % AltTab.items.length;
            altTabSeen.push(altTabStage.style + (ok ? " " + Math.round(it.implicitWidth) + "×" + Math.round(it.implicitHeight) : " FAIL"));
            altTabStage.style = "";
            if (altTabSeen.length < altTabStyles.length)
                return;
            AltTab.items = [];
            report("alttab-styles", altTabSeen.every(x => x.indexOf("FAIL") < 0), altTabSeen.join(", "));
            // its layer-shell window cannot open here, but it must compile
            const host = Qt.createComponent(Quickshell.shellDir + "/modules/alttab/AltTabHost.qml");
            const hostErr = host.status === Component.Ready ? "" : host.errorString();
            // offscreen has no layer shell: that one error is expected, anything else is not
            report("alttab-host", !hostErr || /No PanelWindow backend/.test(hostErr) && hostErr.trim().split("\n").length === 1, hostErr ? hostErr.trim().split("\n")[0].replace(/^.*AltTabHost\.qml:/, "") : "compiles");
            console.log("TEST-PAGE bar-widgets");
            barStage.active = true;
            phase = "bar";
            started = Date.now();
            return;
        }
        if (phase === "bar") {
            if (barStage.status === Loader.Loading && Date.now() - started < 4000)
                return;
            const b = barStage.item;
            const ok = barStage.status === Loader.Ready && !!b && b.wifi.width > 0 && b.bt.width > 0 && b.wired.width > 0;
            // every tray density lays out; the sprites switch
            for (const d of ["compact", "airy", "spacious", "normal"])
                Config.bar.trayDensity = d;
            for (const sp of ["star", "cd", "heart"])
                Config.workspaces.sprite = sp;
            report("bar-widgets", ok, ok ? "wifi, bluetooth, wired, tray, workspaces" : "status " + barStage.status);
            barStage.active = false;
            console.log("TEST-PAGE toggle-wrap");
            wrapStage.active = true;
            phase = "wrap";
            return;
        }
        if (phase === "wrap") {
            // PxToggle wraps a long label inside PxGroup / SettingRow, keeps short and free ones on one line
            const w = wrapStage.item;
            const fits = (t, box) => t.mapToItem(box, t.width, 0).x <= box.width + 0.5;
            const wrapped = t => t.height > w.short.height + 1;
            const checks = [
                ["group", fits(w.direct, w.group) && wrapped(w.direct)],
                ["row", fits(w.inRow, w.row) && wrapped(w.inRow)],
                ["column", fits(w.inColumn, w.row2) && wrapped(w.inColumn)],
                ["short", w.short.width === w.short.implicitWidth && !wrapped(w.short)],
                ["free", w.free.width === w.free.implicitWidth && !wrapped(w.free)]
            ];
            const bad = checks.filter(c => !c[1]).map(c => c[0]);
            report("toggle-wrap", bad.length === 0, bad.length ? "overflow/one line: " + bad.join(", ") : "long labels wrap in " + Math.round(w.direct.width) + " px, short and free stay " + Math.round(w.short.height) + " px tall");
            wrapStage.active = false;
            console.log("TEST-PAGE start-styles");
            startStyles = ["classic", "win11", "fullscreen", "xmb", "windose", "wii", "spotlight"];
            startSeen = [];
            phase = "start";
            return;
        }
        if (phase === "start") {
            // one look per tick: load it, then search, walk, clear and close it with keys
            if (!startStage.style) {
                startStage.style = startStyles[startSeen.length];
                startTried = false;
                return;
            }
            // a tick after the keys: callLater work (focus) is done, unload it
            if (startTried) {
                startStage.style = "";
                if (startSeen.length < startStyles.length)
                    return;
                report("start-styles", startSeen.every(x => x.indexOf("FAIL") < 0), startSeen.join(", "));
                phase = "rmb";
                return;
            }
            startTried = true;
            const it = startStage.item;
            let closed = 0;
            const ok = startStage.status === Loader.Ready && !!it && it.width > 0 && it.height > 0;
            if (ok) {
                const onClose = () => closed++;
                it.closeRequested.connect(onClose);
                const press = (k, text) => {
                    const e = {
                        "key": k,
                        "text": text || "",
                        "modifiers": Qt.NoModifier,
                        "accepted": false
                    };
                    it.key(e);
                };
                if (it.reset)
                    it.reset();
                for (const k of [Qt.Key_Down, Qt.Key_Down, Qt.Key_Right, Qt.Key_Up, Qt.Key_Left, Qt.Key_PageDown, Qt.Key_PageUp])
                    press(k);
                if (it.setQuery)
                    it.setQuery("set");
                press(0, "t");
                press(Qt.Key_Down);
                press(Qt.Key_Escape);         // clears the search (or closes the classic one)
                press(Qt.Key_Escape);         // closes
                it.closeRequested.disconnect(onClose);
            }
            startSeen.push(startStage.style + (ok && closed > 0 ? " " + Math.round(it.width) + "×" + Math.round(it.height) : " FAIL" + (ok ? " (Esc did not close)" : "")));
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
