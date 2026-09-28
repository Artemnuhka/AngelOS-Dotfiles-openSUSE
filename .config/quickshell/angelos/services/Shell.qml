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
    property bool settingsOpen: false
    property string settingsPage: "appearance"
    property bool launcherOpen: false
    property string launcherPrefill: ""
    property bool sessionOpen: false
    property bool clipboardOpen: false
    property bool locked: false
    property var polkitReregister: null
    property bool polkitRegistered: false
    readonly property bool dev: Quickshell.env("ANGELOS_DEV") === "1"

    function lock() {
        locked = true;
    }

    // ANGELOS_SCREENS=HDMI-A-1,... limits the shell to some outputs (dev runs, streaming setups)
    readonly property var onlyScreens: (Quickshell.env("ANGELOS_SCREENS") || "").split(",").filter(s => s !== "")
    readonly property var screens: dev && onlyScreens.length ? Quickshell.screens.filter(s => onlyScreens.includes(s.name)) : Quickshell.screens
    readonly property var focusedScreen: screens.find(s => s.name === Niri.focusedOutput) || screens[0]

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
