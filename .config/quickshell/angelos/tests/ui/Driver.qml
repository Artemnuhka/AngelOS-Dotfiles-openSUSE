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
import "../../novel/NovelCore.js" as Core
import "../../services/Intents.js" as Intents

// angelOS UI self-test, started by scripts/test-ui.sh (ANGELOS_TEST=1, Qt's
// offscreen platform, a throwaway HOME). Inside the real shell, so the type
// anchors of shell.qml are the ones in use:
//   pages     every settings page loads in each settings skin (no errors), the sidebar is
//             always there; sub-pages (advanced groups) open on their own; ◀ ▶ history
//   views     every settings view (sidebar, Control Panel, Properties, tiles) in each skin:
//             its home, a page, a plugin's page, the search, the keyboard, `settings <page>`
//   previews  every preview scene loads and plays through its frames
//   search    settings search: 40 typical queries, average and worst time
//   rig       the helper's pictures (SpriteRig): both figures read, sized as
//             their rig.json says, swapped and played through without errors
//   alttab    the Alt+Tab switcher styles (and hell's own) load and follow the pick
//   bar       bar widgets (Wi-Fi, Bluetooth, wired, tray, desk sprites) load, their panels open
//   wrap      long switch labels wrap inside a narrow group instead of running past it
//   start     every Start look (the bodies of StartOverlay) loads, searches, walks with the keys, Esc closes
//   hell      the built-in desktop widgets and a hell window frame load in heaven and in hell,
//             the widgets burn over and back, the six hell cursors are in the catalog
//   game      the save (services/Story) loads, all nine circles and every scene are valid
//             data, each circle has its trial; a fall lands on the heaviest sin, a right
//             answer goes a circle deeper, the pact gets out with its mark; the game turns
//             off and on again
//   game-exit the way out of hell with the game's clock moved instead of waited (issue #31):
//             too early → the minutes left; ten minutes later → the trial; a time saved in
//             the future, a scene that no longer exists, limbo across a restart, a player
//             stuck under the old rules (a broken plea counter) — none blocks the way out;
//             pleas are understood in any wording, with typos and the wrong layout
//   pace      into hell through the portal shows the circle; back and forth within
//             story/game.json's pace.quickSwitch is instant, later the whole show again (C1)
//   walls     heaven's wallpaper stays as it is in hell, a pick in hell lasts for its circle,
//             an older save is untangled, hell's accent is its own (C2)
//   cava      the cava widget (over a stand-in cava) starts, and starts again after it was
//             hidden and shown with the same config (B4: the lock, sleep, a fullscreen game)
//   rmb       a right-click menu opens where the button went down (B2); a right click into
//             the window's corner pixel does not crash Qt
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
        // A built-in app window without a skin override follows the selected Windose look.
        PxWindow {
            id: appWindow
            visible: false
            width: Theme.u * 180
            height: Theme.u * 120
            title: "angelOS app"
            Column {
                spacing: Theme.u * 6
                PxText {
                    text: "angelOS app"
                    kind: "big"
                }
                PxField {
                    placeholder: "Search…"
                    width: Theme.u * 115
                }
                PxButton {
                    id: appAction
                    text: "Action"
                }
            }
        }
        PxPreview {
            id: preview
            visible: false
            width: Theme.u * 200
        }
        TestEvent {
            id: sim
        }
        // a right-click menu area (the wallpaper's, a widget's, the bar's)
        ContextClick {
            id: ctxClick
            width: 400
            height: 300
            z: -100
            visible: false          // only for its check: the corner-pixel test needs nobody there
            property var got: null
            onMenu: (x, y) => got = Qt.point(x, y)
        }
        SpriteRig {
            id: rig
        }
        // the Alt+Tab switcher's looks, with a stand-in for its window
        Loader {
            id: altTabStage
            property string style: ""
            active: style !== ""
            sourceComponent: style === "ngo" ? atNgo : style === "y2k" ? atY2k : style === "hell" ? atHell : atAngel
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
        Component {
            id: atHell
            AltTabHell {
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
        // the desktop widgets' content in heaven and in hell (Theme.realm), and a hell frame
        // (hidden: cava must not start its audio tap here)
        Loader {
            id: hellStage
            property string kind: ""
            visible: false
            active: kind !== "" && kind !== "frame"
            source: active ? Quickshell.shellDir + "/modules/desktop/widgets/" + kind + "Widget.qml" : ""
        }
        // the cava widget for real, over test-ui.sh's stand-in cava (it prints frames like
        // the real one): hidden and shown again it must come back (B4)
        Loader {
            id: cavaStage
            active: false
            width: 200
            height: 100
            source: Quickshell.shellDir + "/modules/desktop/widgets/CavaWidget.qml"
            onLoaded: {
                item.screenName = "selftest";
                item.widget = {
                    "uid": "selftest",
                    "settings": {}
                };
            }
        }
        Loader {
            id: frameStage
            active: hellStage.kind === "frame"
            sourceComponent: PxWindow {
                hell: true
                compact: true
                title: "clock.exe"
                width: Theme.u * 120
                height: Theme.u * 60
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
            "BarStyle": ["taskbar", "top", "island", "dock", "capsules", "windose"],
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
    property int navStep: 0
    property string navNote: ""
    property var settingsSkins: ["classic", "windose", "stream"]
    property int settingsSkinIndex: 0
    property bool settingsShotPending: false
    property string settingsShotFlavor: ""
    property string settingsShotMode: ""
    property bool undoFrom: false
    property var altTabStyles: []
    property var startStyles: []
    property var startSeen: []
    property bool startTried: false
    property string startShot: ""
    property var hellSteps: []
    property var hellSeen: []
    property bool hellLoaded: false
    property var altTabSeen: []
    property string altTabShot: ""
    readonly property string shots: Quickshell.env("ANGELOS_TEST_SHOTS") || ""
    property bool undoDone: false
    property int cavaFirst: 0
    property int paceRuns: 0
    property bool paceSlow: false
    property int undoSteps: 0
    // views: [view, skin] cases and where in one case the driver is
    property var viewCases: []
    property int viewCase: -1
    property int viewStep: 0
    property var viewNote: null

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
        expertPass = false;
        Config.settingsUi.skin = settingsSkins[settingsSkinIndex];
        const ids = view.allPages.map(p => p.id);
        list = ["home"].concat(ids);
        index = -1;
        phase = "pages";
        nextPage();
    }
    function nextPage() {
        index++;
        if (index >= list.length) {
            if (settingsSkinIndex + 1 < settingsSkins.length) {
                settingsSkinIndex++;
                startPages(false);
            }
            else
                startViews();
            return;
        }
        console.log("TEST-PAGE " + list[index]);
        Shell.settingsPage = list[index];
        started = Date.now();
    }
    function startViews() {
        viewCases = [];
        for (const v of ["sidebar", "controlpanel", "properties", "tiles"])
            for (const skin of settingsSkins)
                viewCases.push([v, skin]);
        viewCase = -1;
        phase = "views";
        nextViewCase();
    }
    function nextViewCase() {
        viewCase++;
        viewStep = 0;
        if (viewCase >= viewCases.length) {
            Config.settingsUi.view = "sidebar";
            Config.settingsUi.skin = "classic";
            view.setQuery("");
            if (shots)
                startSettingsShots();
            else
                startPreviews();
            return;
        }
        const [v, skin] = viewCases[viewCase];
        console.log("TEST-PAGE view:" + v + ":" + skin);
        Config.settingsUi.skin = skin;
        Config.settingsUi.view = v;
        Shell.settingsPage = "home";
        Shell.settingsSub = "";
        started = Date.now();
    }
    // one step of a view case; true when it is done (passed or reported)
    function viewTick() {
        const [v, skin] = viewCases[viewCase];
        const name = "view:" + v + ":" + skin;
        const d = view.diagnostics();
        const ms = Date.now() - started;
        const ready = d.viewStatus === Loader.Ready && d.view === v && (d.atHome || d.status === Loader.Ready);
        const waiting = ms < 6000;
        const next = () => {
            viewStep++;
            started = Date.now();
        };
        if (viewStep === 0) {
            // the home: the folder / the tiles show their own, the others a page
            if (!ready && waiting)
                return;
            report(name + ":home", ready && d.atHome === (v === "controlpanel" || v === "tiles"), "status " + d.viewStatus + "/" + d.status + ", at home " + d.atHome);
            Shell.settingsPage = "sound";
            next();
        } else if (viewStep === 1) {
            if ((!ready || d.page !== "sound") && waiting)
                return;
            const locs = view.sectionLocs.map(l => l.page + (l.sub ? "›" + l.sub : ""));
            report(name + ":page", ready && d.page === "sound" && (v !== "properties" || locs.length >= 2), locs.join(", "));
            const pl = Plugins.settingsPages[0];
            viewNote = pl ? pl.id : "";
            Shell.settingsPage = pl ? "plugin:" + pl.id : "lyrics";
            next();
        } else if (viewStep === 2) {
            if ((!ready || (viewNote && d.plugin !== viewNote)) && waiting)
                return;
            report(name + ":plugin", ready && (!viewNote || d.plugin === viewNote), viewNote ? "plugin " + d.plugin : "no plugin pages");
            view.setQuery("обои");
            next();
        } else if (viewStep === 3) {
            if (view.results.length === 0 && waiting)
                return;
            const r = view.results[0];
            report(name + ":search", !!r && !!view.viewItem && !!view.viewItem.resultsSlot, view.results.length + " results");
            viewNote = r ? r.page : "";
            view.openResult(r);
            next();
        } else if (viewStep === 4) {
            if ((!ready || d.page !== viewNote) && waiting)
                return;
            report(name + ":open-result", ready && d.page === viewNote && d.query === "", "page " + d.page);
            // the keyboard: from the home (or the account) the view's own keys move on
            Shell.settingsPage = "home";
            next();
        } else if (viewStep === 5) {
            if (!ready && waiting)
                return;
            const before = Shell.settingsPage + "|" + Shell.settingsSub;
            let ok;
            if (v === "controlpanel" || v === "tiles") {
                ok = view.navKeyForTest(Qt.Key_Down) && view.navKeyForTest(Qt.Key_Right) && view.navKeyForTest(Qt.Key_Return);
                ok = ok && !view.atHome;
            } else {
                ok = view.navKeyForTest(Qt.Key_Down);
                ok = ok && Shell.settingsPage + "|" + Shell.settingsSub !== before;
            }
            report(name + ":keys", ok, before + " → " + Shell.settingsPage + "|" + Shell.settingsSub);
            // `angelos settings lyrics`
            Shell.settingsOpen = true;
            Shell.openSettings("lyrics");
            next();
        } else if (viewStep === 6) {
            if ((!ready || d.page !== "lyrics") && waiting)
                return;
            report(name + ":settings-cli", ready && d.page === "lyrics", "page " + d.page);
            nextViewCase();
        }
    }
    function startSettingsShots() {
        settingsShotFlavor = Config.appearance.flavor;
        settingsShotMode = Config.appearance.mode;
        list = [];
        for (const skin of settingsSkins)
            for (const page of ["home", "appearance", "updates"])
                list.push([skin, page]);
        list.push(["windose", "home", "chosen"]);
        list.push(["stream", "home", "narrow"]);
        index = -1;
        phase = "settings-shots";
        nextSettingsShot();
    }
    function nextSettingsShot() {
        index++;
        settingsShotPending = false;
        if (index >= list.length) {
            win.implicitWidth = 1100;
            win.implicitHeight = 780;
            win.width = 1100;
            win.height = 780;
            Config.appearance.flavor = settingsShotFlavor;
            Config.appearance.mode = settingsShotMode;
            Config.settingsUi.skin = "windose";
            settingsShotPending = true;
            appWindow.visible = true;
            appWindow.grabToImage(r => {
                r.saveToFile(shots + "/windose-app-window.png");
                appWindow.visible = false;
                startPreviews();
            });
            return;
        }
        const [skin, page, size] = list[index];
        Config.settingsUi.skinChosen = size === "chosen";
        win.implicitWidth = size === "narrow" ? 720 : 1100;
        win.implicitHeight = size === "narrow" ? 480 : 780;
        win.width = size === "narrow" ? 720 : 1100;
        win.height = size === "narrow" ? 480 : 780;
        Config.settingsUi.skin = skin;
        Config.appearance.flavor = page === "appearance" ? "nord" : page === "updates" ? "gruvbox" : "overdose";
        Config.appearance.mode = page === "appearance" ? "light" : "dark";
        Shell.settingsPage = page;
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
            if (Config.ready && view.allPages.length > 0) {
                report("settings-default-classic", Config.settingsUi.skin === "classic" && view.skin === "classic",
                       "saved default " + Config.settingsUi.skin + ", view " + view.skin);
                // a settings.json from before the views (no settingsUi.view): the sidebar stays
                report("settings-default-sidebar", Config.settingsUi.view === "sidebar" && view.viewId === "sidebar",
                       "saved " + Config.settingsUi.view + ", shown " + view.viewId);
                Config.settingsUi.skin = "windose";
                report("windose-app-windows", appWindow.skin === "windose" && appWindow.windose && appWindow.settingsSkin === "windose" && appAction.settingsSkin === "windose",
                       "unconfigured app skin " + appWindow.skin);
                Config.settingsUi.skin = "classic";
                report("classic-app-windows", appWindow.skin === "" && !appWindow.windose && appWindow.settingsSkin === "classic" && appAction.settingsSkin === "classic",
                       "unconfigured app skin " + appWindow.skin);
                const oldFlavor = Config.appearance.flavor;
                Config.appearance.flavor = "gruvbox";
                const windoseA = String(Theme.windoseRose);
                const streamA = String(Theme.streamBg);
                Config.appearance.flavor = "nord";
                const windoseB = String(Theme.windoseRose);
                const streamB = String(Theme.streamBg);
                Config.appearance.flavor = oldFlavor;
                report("settings-palette", windoseA !== windoseB && streamA !== streamB,
                       "Windose " + windoseA + " → " + windoseB + ", Stream " + streamA + " → " + streamB);
                startPages(false);
            }
            return;
        }
        if (phase === "pages") {
            const d = view.diagnostics();
            const ms = Date.now() - started;
            if (d.status === Loader.Loading && ms < 8000)
                return;
            const name = "page:" + settingsSkins[settingsSkinIndex] + ":" + list[index];
            report(name, d.status === Loader.Ready && view.frame.skin === settingsSkins[settingsSkinIndex] && d.settingsSkin === settingsSkins[settingsSkinIndex],
                   d.status === Loader.Ready ? ms + " ms, page skin " + d.settingsSkin : "status " + d.status + " " + d.source);
            if (list[index] === "home" || list[index] === "appearance")
                report("sidebar:" + settingsSkins[settingsSkinIndex] + ":" + list[index], d.sidebarVisible === true);
            nextPage();
            return;
        }
        if (phase === "views") {
            viewTick();
            return;
        }
        if (phase === "settings-shots") {
            if (settingsShotPending)
                return;
            const d = view.diagnostics();
            if (d.status !== Loader.Ready || d.page !== list[index][1] || Date.now() - started < 120)
                return;
            const [skin, page, size] = list[index];
            const file = shots + "/settings-" + skin + "-" + page + (size ? "-" + size : "") + ".png";
            settingsShotPending = true;
            view.grabToImage(r => {
                r.saveToFile(file);
                nextSettingsShot();
            });
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
            // ◀ ▶: account → sound → its sub-page System sounds → its "Clicks" group, back
            // twice lands on sound, forward once on System sounds again
            if (navStep === 0) {
                Shell.settingsPage = "account";
                navStep = 1;
                return;
            }
            const go = [["sound", ""], ["sfx", ""], ["bar", "Иконки"]];
            if (navStep <= go.length) {
                Shell.settingsPage = go[navStep - 1][0];
                Shell.settingsSub = go[navStep - 1][1];
                navStep++;
                return;
            }
            if (navStep === go.length + 1) {
                const it = view.diagnostics();
                const pg = view.pageItem;
                // the sub-page: its heading is the group, the page's other groups stepped aside
                const others = pg && pg.advancedGroups ? pg.advancedGroups.filter(c => c.title !== "Иконки") : [];
                report("subpage", it.sub === "Иконки" && !!pg && pg.focusGroup === "Иконки" && others.length > 0 && others.every(c => !c.visible), "bar › " + it.sub + ", " + others.filter(c => c.visible).length + " other groups still shown");
                view.back();
                navStep++;
                return;
            }
            if (navStep === go.length + 2) {
                view.back();
                navStep++;
                return;
            }
            if (navStep === go.length + 3) {
                const afterBack = Shell.settingsPage;
                view.forward();
                navStep++;
                navNote = afterBack;
                return;
            }
            report("nav-back", navNote === "sound" && Shell.settingsPage === "sfx" && view.sectionOf("sfx") === "sound", "bar›Иконки → ◀ ◀ " + navNote + " → ▶ " + Shell.settingsPage + " (section " + view.sectionOf(Shell.settingsPage) + ")");
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
            altTabStyles = ["angelos", "ngo", "y2k", "hell"];
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
                started = Date.now();
                return;
            }
            // a tick after the keys: callLater work (focus) is done, unload it
            if (startTried) {
                startStage.style = "";
                if (startSeen.length < startStyles.length)
                    return;
                report("start-styles", startSeen.every(x => x.indexOf("FAIL") < 0), startSeen.join(", "));
                console.log("TEST-PAGE hell-widgets");
                hellSteps = [];
                for (const k of ["Clock", "Sysmon", "Cava", "NowPlaying", "Hellwheel", "frame"])
                    for (const r of ["heaven", "hell"])
                        hellSteps.push([k, r]);
                hellSeen = [];
                phase = "hell";
                return;
            }
            const it = startStage.item;
            const ok = startStage.status === Loader.Ready && !!it && it.width > 0 && it.height > 0;
            // ANGELOS_TEST_SHOTS=<dir>: a picture of each look as it opens
            if (ok && shots && !startShot) {
                startShot = "wait";
                const name = shots + "/start-" + startStage.style + ".png";
                it.grabToImage(r => {
                    r.saveToFile(name);
                    root.startShot = "done";
                });
                return;
            }
            if (startShot === "wait" && Date.now() - started < 3000)
                return;
            startShot = "";
            startTried = true;
            let closed = 0;
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
        if (phase === "hell") {
            // one widget and realm per tick: load it, next tick measure it
            const st = hellSteps[hellSeen.length];
            if (!hellLoaded) {
                Theme.realm = st[1];
                hellStage.kind = st[0];
                hellLoaded = true;
                return;
            }
            const stage = st[0] === "frame" ? frameStage : hellStage;
            const it = stage.item;
            hellSeen.push(st[0] + "/" + st[1] + (stage.status === Loader.Ready && it && (it.implicitWidth > 0 || it.width > 0) ? "" : " FAIL"));
            hellStage.kind = "";
            hellLoaded = false;
            if (hellSeen.length < hellSteps.length)
                return;
            Theme.realm = "heaven";
            report("hell-widgets", hellSeen.every(x => x.indexOf("FAIL") < 0), hellSeen.filter(x => x.indexOf("FAIL") >= 0).join(", ") || hellSeen.length + " loads");
            // every look of hell (story/circles.json): text, dim text and the accent read on
            // the plate and on the bar's button face (WCAG 4.5:1)
            const lookIds = HellLook.ids.length ? HellLook.ids : ["base"];
            const weak = [];
            for (const id of lookIds) {
                const pal = HellLook.merged(HellLook.fallback, HellLook.looks.base, id !== "base" ? HellLook.looks[id] : null).palette;
                const face = Theme.hex(Theme.mix(pal.rim, pal.face, 0.4));
                for (const role of ["text", "textDim", "accent"])
                    for (const [gname, ground] of [["plate", pal.plate], ["face", face]]) {
                        const c = HellLook.contrast(pal[role], ground);
                        if (c < 4.5)
                            weak.push(id + ": " + role + " on " + gname + " " + c.toFixed(2));
                    }
            }
            report("hell-contrast", HellLook.ids.length > 0 && weak.length === 0, weak.join(", ") || lookIds.length + " looks, text/dim/accent ≥ 4.5:1");
            // a burn there and back (DesktopWidgets.burnPreview) must land in heaven again
            DesktopWidgets.burnPreview("hell");
            started = Date.now();
            phase = "hell-burn";
            return;
        }
        if (phase === "hell-burn") {
            if ((DesktopWidgets.burning || Theme.realm !== "heaven") && Date.now() - started < DesktopWidgets.burnMs * 2 + 2500)
                return;
            const hellCursors = Cursors.hellish.length;
            report("hell-burn", !DesktopWidgets.burning && Theme.realm === "heaven" && hellCursors === 6, "burnt over and back in " + (Date.now() - started) + " ms, " + hellCursors + " hell cursors");
            phase = "game";
            started = Date.now();
            return;
        }
        if (phase === "game") {
            if (!Novel.loaded && Date.now() - started < 8000)
                return;
            report("game-save", Story.ready && Story.player.character === "angel" && Story.enabled, "save " + Story.file + (Story.ready ? "" : " not loaded"));
            const missing = Story.order.filter(id => !HellLook.looks[id] || HellLook.looks[id].n !== Story.order.indexOf(id) + 1);
            report("game-circles", Story.order.length === 9 && missing.length === 0, missing.length ? "missing or misnumbered: " + missing.join(", ") : "9 circles in order");
            const bad = [];
            for (const id of Object.keys(Novel.scenes))
                for (const v of Core.validate(Novel.scenes[id]))
                    if (v.level === "error")
                        bad.push(id + "/" + v.node + ": " + v.text);
            report("game-scenes", Object.keys(Novel.scenes).length > 0 && bad.length === 0, bad.join("; ") || Object.keys(Novel.scenes).length + " scenes valid");
            const noTrial = Story.order.filter(id => !Object.keys(Novel.scenes).some(sid => {
                    const ev = Novel.eventOf(Novel.scenes[sid]);
                    return ev && ev.trigger === "trial" && Core.evalCond(ev.cond, Object.assign(Story.ctxVars(), {
                        "circle": id
                    }), []);
                }));
            report("game-trials", noTrial.length === 0, noTrial.length ? "no trial in " + noTrial.join(", ") : "every circle has its trial");
            // a fall lands on the heaviest sin among the circles no fall began in
            Story.applySet({
                "greed": "+2",
                "wrath": "+1"
            });
            const first = Story.circleForFall();
            Story.hell.fallCircles = ["greed"];
            const second = Story.circleForFall();
            Story.hell.fallCircles = [];
            report("game-fall", first === "greed" && second === "wrath", "greed 2, wrath 1 → " + first + ", then " + second);
            // into hell without the show: greed, then a circle deeper, then the pact
            Story.player.character = "demon";
            Story.fell("greed");
            const inGreed = Story.circle === "greed" && HellLook.circle === "greed" && Theme.hellAccent.toString() === Qt.color(HellLook.looks.greed.palette.accent).toString();
            Story.deeper();
            report("game-deeper", inGreed && Story.circle === "wrath" && Story.depth === 2, "greed (" + inGreed + ") → " + Story.circle + ", path " + JSON.stringify(Story.hell.path));
            Story.outcome("pact");
            started = Date.now();
            phase = "game-out";
            return;
        }
        if (phase === "game-out") {
            if ((Story.inHell || Angel.transition) && Date.now() - started < 12000)
                return;
            report("game-pact", !Story.inHell && Story.marked && Story.circle === "" && HellLook.circle === "base" && Story.hell.outcomes.length === 1, "out by " + (Story.hell.outcomes[0] || {}).kind + " in " + (Date.now() - started) + " ms, marked " + Story.marked);
            Story.setEnabled(false);
            const off = !Story.enabled && !Angel.demon && !Angel.shown && !Novel.enabled;
            Story.setEnabled(true);
            report("game-off", off && Story.enabled, "off: no angel, demon or novel; on again");
            Story.reset();
            report("game-reset", Object.keys(Story.vars).length === 0 && !Story.hell.pact && (Story.hell.outcomes || []).length === 0, "the save starts over");
            phase = "game-exit";
            return;
        }
        if (phase === "game-exit") {
            // in hell without the show; the clock is moved, never waited for
            Story.player.character = "demon";
            Story.fell("limbo");
            Story.player.lastPlea = Story.now();
            const early = Story.attempt(false);
            Story.clockShift += 11 * 60000;
            const later = Story.attempt(false);
            const asked = Novel.sceneBusy;
            const twice = Story.attempt(false);
            Novel.stopScene();
            report("exit-wait", early === "wait" && later === "trial" && asked && twice === "busy", "too early → " + early + ", 11 min later → " + later + ", again while it waits → " + twice);
            // the clock went back: the last try is "in the future"
            Story.player.lastPlea = Story.now() + 3 * 3600000;
            const future = Story.attempt(false);
            Novel.stopScene();
            report("exit-future", future === "trial" && Story.player.lastPlea <= Story.now(), "a try saved 3 h ahead → " + future);
            // the save points at a scene an update renamed
            Story.clockShift += 11 * 60000;
            Novel.state = Object.assign({}, Novel.state, {
                "game": {
                    "scene": "trial-renamed",
                    "node": "ask",
                    "wait": "show"
                }
            });
            const stale = Story.attempt(false);
            Novel.stopScene();
            report("exit-stale", stale === "trial", "a scene that is gone → " + stale);
            // any wording of "let me out", typos and the wrong keyboard layout too
            const pleas = ["верни ангела", "как вернуться", "хочу в рай", "отпусти меня", "умоляю", "привет, верни ангела", "как отсюда выбраться", "вирни ангила", "dthyb fyutkf", "хочу домой", "let me out", "bring the angel back", "I want to go back to heaven", "please"];
            const notPleas = ["расскажи шутку", "как сделать крупнее", "это верно", "поменяй обои"];
            const missed = pleas.filter(s => !Intents.weak(s, "plea")).concat(notPleas.filter(s => Intents.weak(s, "plea")).map(s => "not: " + s));
            Story.clockShift += 11 * 60000;
            Angel.answer("привет, верни ангела");
            const typed = Novel.sceneBusy;
            Novel.stopScene();
            report("exit-words", missed.length === 0 && typed, missed.length ? "misread: " + missed.join("; ") : pleas.length + " pleas and " + notPleas.length + " other questions read right; typed → the trial " + typed);
            // limbo across a restart: the angel finds the player once enough time has passed
            Story.outcome("limbo");
            Story.hell.limboSince = Story.now() - 11 * 60000;
            Story.freeIfDue(true);
            started = Date.now();
            phase = "exit-limbo";
            return;
        }
        if (phase === "exit-limbo") {
            if ((Story.inHell || Angel.transition) && Date.now() - started < 12000)
                return;
            report("exit-limbo", !Story.inHell && !Story.hell.limbo, "limbo of 11 min at a start → " + (Story.inHell ? "still in hell" : "out") + " in " + (Date.now() - started) + " ms");
            // a player stuck under the old rules: settings.json's y2k with a broken counter
            Story.reset();
            Story.migrateFrom({
                "character": "demon",
                "pleas": "garbage",
                "lastPlea": 99999999999999,
                "returns": "x"
            }, null);
            Story.repairClock();
            const stuck = Story.inHell && Story.hell.amnesty && Story.player.lastPlea === 0;
            Story.freeIfDue(true);
            started = Date.now();
            phase = "exit-amnesty";
            report("exit-migrate", stuck, "old save in hell: amnesty " + Story.hell.amnesty + ", last try " + Story.player.lastPlea);
            return;
        }
        if (phase === "exit-amnesty") {
            if ((Story.inHell || Angel.transition) && Date.now() - started < 14000)
                return;
            report("exit-amnesty", !Story.inHell && !Story.hell.amnesty && Story.player.returns === 1 && (Story.hell.outcomes || []).some(o => o.kind === "amnesty"), "let out in " + (Date.now() - started) + " ms, returns " + Story.player.returns);
            Story.clockShift = 0;
            Story.reset();
            // C1: into hell through the portal, with the show and the circle's splash
            paceRuns = CircleFx.runs;
            Angel.lastSwitchAt = 0;
            Angel._portal = true;
            Angel.startSwap("toHell");
            started = Date.now();
            phase = "pace";
            return;
        }
        if (phase === "pace") {
            if (Angel.transition && Date.now() - started < 8000)
                return;
            const shown = Angel.demon && CircleFx.runs === paceRuns + 1;
            // back and forth right after: at once, no splash, no burn
            Angel.startSwap("ascend");
            const out = !Angel.demon && !Angel.transition;
            Angel.startSwap("toHell");
            const back = Angel.demon && !Angel.transition && CircleFx.runs === paceRuns + 1;
            report("pace-quick", shown && out && back, "portal → the circle's splash " + shown + "; out and in again within " + Story.quickSwitchMs / 1000 + " s: at once " + (out && back) + ", splashes " + (CircleFx.runs - paceRuns));
            // later than the threshold: the whole show again
            Angel.lastSwitchAt = Date.now() - Story.quickSwitchMs - 1000;
            Angel.startSwap("ascend");
            paceSlow = Angel.transition === "ascend";
            started = Date.now();
            phase = "pace-slow";
            return;
        }
        if (phase === "pace-slow") {
            if ((Angel.transition || DesktopWidgets.burning) && Date.now() - started < 10000)
                return;
            report("pace-slow", paceSlow && !Angel.demon && Theme.realm === "heaven", "a switch " + (Story.quickSwitchMs / 1000 + 1) + " s after the last: the full show " + paceSlow + ", heaven again " + (Theme.realm === "heaven"));
            Story.reset();
            phase = "walls";
            return;
        }
        // C2: heaven's wallpaper is never touched in hell; a pick in hell lasts for its circle
        if (phase === "walls") {
            const heaven = "/tmp/selftest-heaven.png", hellPic = "/tmp/selftest-hell.png", pickPic = "/tmp/selftest-pick.png";
            const keep = [Config.wallpaper.fallback, Config.wallpaper.outputs, Config.wallpaper.workspaces, Config.y2k.hellPicture, Config.appearance.customAccent];
            Wallpapers.setEverywhere(heaven);
            Config.y2k.hellPicture = hellPic;
            Story.player.character = "demon";
            Story.fell("greed");
            Angel.hellLook(true);
            const inHell = Wallpapers.resolve("S", 1) === hellPic && Config.wallpaper.fallback === heaven;
            Wallpapers.setForOutput("S", pickPic);
            const picked = Wallpapers.resolve("S", 1) === pickPic && Config.wallpaper.fallback === heaven && !(Config.wallpaper.outputs || {}).S;
            Story.setCircle("wrath");
            const nextCircle = Wallpapers.resolve("S", 1) === hellPic;
            const accent0 = Config.appearance.customAccent;
            PaletteGenerator.apply("#123456", false);
            const accents = Config.appearance.customAccent === accent0 && Config.appearance.customAccentHell === "#123456";
            Angel.hellLook(false);
            Story.player.character = "angel";
            const back = Wallpapers.resolve("S", 1) === heaven && !Story.player.hellWall;
            report("walls-apart", inHell && picked && nextCircle && back, "in hell " + inHell + ", a pick changes hell only " + picked + ", the next circle puts its own " + nextCircle + ", heaven's back " + back);
            report("walls-accent", accents, "hell's accent from its picture kept apart from heaven's " + accents);
            // an older save: hell sat in Config.wallpaper, heaven's in angelSaved
            Story.player.character = "demon";
            Story.player.angelSaved = {
                "fallback": heaven,
                "outputs": {},
                "workspaces": {},
                "mode": "light"
            };
            Config.wallpaper.fallback = "/tmp/selftest-old-hell.png";
            Angel.untangleWall();
            const untangled = Config.wallpaper.fallback === heaven && !!Story.player.hellWall && Story.player.hellWall.fallback === "/tmp/selftest-old-hell.png" && Story.player.angelSaved.mode === "light" && Story.player.angelSaved.fallback === undefined;
            report("walls-old-save", untangled, "heaven's wallpaper given back " + (Config.wallpaper.fallback === heaven) + ", the old hell kept as hell's " + !!Story.player.hellWall);
            Story.player.character = "angel";
            Story.player.hellWall = null;
            Story.player.angelSaved = null;
            Config.wallpaper.fallback = keep[0];
            Config.wallpaper.outputs = keep[1];
            Config.wallpaper.workspaces = keep[2];
            Config.y2k.hellPicture = keep[3];
            Config.appearance.customAccent = keep[4];
            Config.appearance.customAccentHell = "";
            Story.reset();
            cavaStage.active = true;
            started = Date.now();
            phase = "cava";
            return;
        }
        // B4: cava started, hidden (the lock, sleep, a fullscreen game), shown again with the
        // same config — it must start again and print frames
        if (phase === "cava") {
            const w = cavaStage.item;
            if ((!w || w.starts < 1 || Date.now() - w.lastFrame > 500) && Date.now() - started < 8000)
                return;
            if (!w) {
                report("cava-back", false, "the cava widget did not load");
                phase = "rmb";
                return;
            }
            cavaFirst = w.starts;
            w.visible = false;
            started = Date.now();
            phase = "cava-hidden";
            return;
        }
        if (phase === "cava-hidden") {
            if (Date.now() - started < 600)
                return;
            cavaStage.item.visible = true;
            started = Date.now();
            phase = "cava-back";
            return;
        }
        if (phase === "cava-back") {
            const w = cavaStage.item;
            const back = w.starts > cavaFirst && Date.now() - w.lastFrame < 500;
            if (!back && Date.now() - started < 6000)
                return;
            report("cava-back", back && !w.missing, "started " + cavaFirst + "×, hidden and shown → " + w.starts + "×, frames " + (back ? "again" : "stopped") + " after " + (Date.now() - started) + " ms" + (w.missing ? " (cava missing)" : ""));
            cavaStage.active = false;
            phase = "rmb";
            return;
        }
        if (phase === "rmb") {
            // B2: with a menu open, Qt on Wayland reports the release relative to that
            // popup — the menu must open where the button went down
            ctxClick.got = null;
            ctxClick.visible = true;
            sim.mousePress(ctxClick, 50, 60, Qt.RightButton, Qt.NoModifier, -1);
            sim.mouseRelease(ctxClick, 300, 200, Qt.RightButton, Qt.NoModifier, -1);
            ctxClick.visible = false;
            const at = ctxClick.got;
            report("menu-at-press", !!at && at.x === 50 && at.y === 60, "down at 50,60, up at 300,200 → menu at " + (at ? at.x + "," + at.y : "none"));
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
