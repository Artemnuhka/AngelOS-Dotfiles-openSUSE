pragma Singleton

import QtQuick
import Quickshell
import qs.config

// UI state shared by modules + small helpers.
Singleton {
    id: root

    property var settingsView: null
    property var barViews: ({})
    property bool setupOpen: false
    signal setupStepRequested(int step)
    property bool settingsOpen: false
    property string settingsPage: "appearance"
    property bool launcherOpen: false
    property string launcherPrefill: ""
    property bool sessionOpen: false
    property bool clipboardOpen: false
    property bool gameOpen: false            // osu!mini window (plugin osu-mini)
    property bool locked: false
    property bool lockPreview: false         // the lock screen in a normal overlay, nothing is checked
    property var lockPreviewTry: null        // (text) → plays the preview's reaction; never touches PAM
    property var polkitReregister: null
    property bool polkitRegistered: false
    readonly property bool dev: Quickshell.env("ANGELOS_DEV") === "1"
    // niri sends "angelOS [dev]" windows to the non-stream monitor (cfg/rules.kdl)
    readonly property string appTitle: dev ? "angelOS [dev]" : "angelOS"
    // demo/recording mode: popups open from IPC without an input grab
    readonly property bool demo: Quickshell.env("ANGELOS_DEMO") === "1"
    property var desktopMenus: ({})   // screen name -> DesktopMenu
    property string launcherText: ""

    function lock() {
        closeStart();
        locked = true;
    }

    // ---- Start menu: a layer-shell overlay per screen (xdg popups opened without
    // a click are dismissed by the compositor, so Meta taps could not use them) ----
    property string startScreen: ""          // screen whose Start menu is open
    property var startButtons: ({})          // screen -> {item, window} of its Start button
    function registerStartButton(screen, item, window) {
        const m = Object.assign({}, startButtons);
        m[screen] = {
            "item": item,
            "window": window
        };
        startButtons = m;
    }
    function unregisterStartButton(screen, item) {
        if (!startButtons[screen] || startButtons[screen].item !== item)
            return;
        const m = Object.assign({}, startButtons);
        delete m[screen];
        startButtons = m;
    }
    function openStart(screen) {
        screen = screen || (focusedScreen ? focusedScreen.name : "");
        if (!screen || locked)
            return;
        launcherOpen = false;
        startScreen = screen;
    }
    function closeStart() {
        startScreen = "";
    }
    function toggleStart(screen) {
        screen = screen || (focusedScreen ? focusedScreen.name : "");
        if (startScreen === screen)
            closeStart();
        else
            openStart(screen);
    }

    // ANGELOS_SCREENS=HDMI-A-1,... limits the shell to some outputs (dev runs, streaming setups)
    readonly property var onlyScreens: (Quickshell.env("ANGELOS_SCREENS") || "").split(",").filter(s => s !== "")
    readonly property var screens: dev && onlyScreens.length ? Quickshell.screens.filter(s => onlyScreens.includes(s.name)) : Quickshell.screens
    readonly property var focusedScreen: screens.find(s => s.name === Niri.focusedOutput) || screens[0]
    // the widest screen: the main landscape monitor next to portrait side screens
    readonly property var primaryScreen: screens.reduce((best, s) => !best || s.width > best.width ? s : best, null)

    function screenByName(name) {
        return screens.find(s => s.name === name) || null;
    }

    function openSettings(page) {
        if (page)
            settingsPage = page;
        settingsOpen = true;
    }
    function toggleSettings(page) {
        if (settingsOpen && (!page || page === settingsPage))
            settingsOpen = false;
        else
            openSettings(page);
    }
    function exec(cmd) {
        Quickshell.execDetached(cmd);
    }
    function sh(script) {
        Quickshell.execDetached(["sh", "-c", script]);
    }
    // argv to run a command in the configured terminal (kitty/foot take the program directly)
    function terminalArgv(argv) {
        const t = Config.system.terminal || "kitty";
        const base = t.split("/").pop();
        if (!argv || argv.length === 0)
            return [t];
        if (base === "kitty" || base === "foot")
            return [t].concat(argv);
        if (base === "wezterm")
            return [t, "start", "--"].concat(argv);
        return [t, "-e"].concat(argv);
    }
    function terminal(cmd) {
        exec(terminalArgv(cmd ? ["sh", "-c", cmd] : []));
    }
    function openPath(path) {
        exec(["xdg-open", Config.expand(path)]);
    }
}
