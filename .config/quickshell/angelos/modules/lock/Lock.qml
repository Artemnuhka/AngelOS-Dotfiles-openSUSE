pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.config
import qs.services
import qs.widgets

// ext-session-lock screen with PAM auth, plus a preview that shows the same
// screen in an ordinary overlay (no session lock, password is not checked).
Scope {
    id: root

    property string status: ""
    property bool busy: pam.active || unlocking
    property int fails: 0
    property string buffer: ""
    property bool unlocking: false         // PAM said yes; the goodbye animation plays
    property real lockedAt: 0
    property bool caps: false
    readonly property bool previewing: Shell.lockPreview && !Shell.locked
    readonly property bool shown: Shell.locked || previewing

    signal shake
    signal success
    signal typed(int length, bool added)

    function submit(pw) {
        if (busy)
            return;
        if (previewing) {
            // preview only: nothing is checked, an empty field shows the failure
            if (pw === "")
                fail();
            else
                succeed();
            return;
        }
        buffer = pw;
        status = I18n.t("проверяю…", "Checking…");
        pam.start();
    }
    function fail() {
        fails++;
        status = fails > 2 ? I18n.t("ну пожааалуйста, вспомни пароль…", "Try your password again…") : I18n.t("неправильный пароль ✕", "Incorrect password ✕");
        shake();
    }
    function succeed() {
        status = "";
        fails = 0;
        unlocking = true;
        success();
        goodbye.restart();
    }
    Timer {
        id: goodbye
        interval: Config.lock.reactions ? 650 : 0
        onTriggered: {
            root.unlocking = false;
            if (root.previewing)
                Shell.lockPreview = false;
            else
                Shell.locked = false;
        }
    }

    Component.onCompleted: Shell.lockPreviewTry = text => {
        if (!root.previewing)
            return;
        for (let i = 1; i <= text.length; i++)
            root.typed(i, true);
        root.submit(text);
    }
    Connections {
        target: Shell
        function onLockedChanged() {
            if (Shell.locked) {
                root.lockedAt = Date.now();
                root.status = "";
                Shell.lockPreview = false;
            }
        }
        function onLockPreviewChanged() {
            if (Shell.lockPreview) {
                root.lockedAt = Date.now();
                root.status = "";
                root.fails = 0;
            }
        }
    }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellDir + "/pam"
        config: "angelos-lock"
        onResponseRequiredChanged: {
            if (responseRequired) {
                respond(root.buffer);
                root.buffer = "";
            }
        }
        onCompleted: result => {
            root.buffer = "";
            if (result === PamResult.Success)
                root.succeed();
            else
                root.fail();
        }
        onError: e => {
            root.buffer = "";
            root.status = I18n.t("ошибка PAM: ", "PAM error: ") + e;
        }
    }

    // Caps Lock from the keyboard LEDs (a lock screen has no other way to know)
    Process {
        running: root.shown && Config.lock.indicators
        command: ["sh", "-c", "while :; do cat /sys/class/leds/*::capslock/brightness 2>/dev/null | tr -d '\\n'; echo; sleep 0.3; done"]
        stdout: SplitParser {
            onRead: line => root.caps = /[1-9]/.test(line)
        }
    }

    // ---- lock before sleep, and on `loginctl lock-session` ----
    // logind waits for a "delay" inhibitor before suspending, so the lock surface
    // is up and confirmed by niri before the machine sleeps; waking up never
    // shows the desktop. The inhibitor is released once the lock is secure and
    // taken again after resume.
    readonly property bool sleepLock: Config.lock.onSleep && !Shell.dev
    property bool sleeping: false
    // logind object path of this session (sd_bus_path_encode: "3" -> "_33")
    readonly property string sessionPath: {
        const id = Quickshell.env("XDG_SESSION_ID") || "";
        if (!id)
            return "";
        let out = "";
        for (let i = 0; i < id.length; i++) {
            const c = id[i];
            if (/[A-Za-z0-9]/.test(c) && !(i === 0 && /[0-9]/.test(c)))
                out += c;
            else
                out += "_" + ("0" + c.charCodeAt(0).toString(16)).slice(-2);
        }
        return "/org/freedesktop/login1/session/" + out;
    }
    // if the lock cannot come up, sleep must still happen (logind waits at most
    // InhibitDelayMaxSec anyway); this lets go a little earlier
    property bool sleepTimedOut: false
    onSleepingChanged: {
        sleepTimedOut = false;
        if (sleeping)
            sleepGrace.restart();
    }
    Timer {
        id: sleepGrace
        interval: 4000
        onTriggered: root.sleepTimedOut = true
    }
    Process {
        id: inhibitor
        // held while awake; let go once the lock is confirmed (or after 4 s)
        running: root.sleepLock && !(root.sleeping && (lock.secure || root.sleepTimedOut))
        stdinEnabled: true           // `cat` exits with the pipe, so nothing is left behind
        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=angelOS", "--why=Lock the screen before sleep", "cat"]
    }
    Process {
        id: logind
        running: root.sleepLock
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1"]
        stdout: SplitParser {
            onRead: line => {
                const sleep = line.match(/\.Manager\.PrepareForSleep \((true|false)/);
                if (sleep) {
                    if (sleep[1] === "true") {
                        root.sleeping = true;
                        Shell.lock();
                    } else {
                        root.sleeping = false;
                        Shell.resumed();
                        // in case the lock could not come up before sleeping
                        if (!Shell.locked)
                            Shell.lock();
                    }
                } else if (root.sessionPath && line.startsWith(root.sessionPath + ":") && /\.Session\.Lock \(\)/.test(line)) {
                    Shell.lock();
                }
            }
        }
        onExited: if (root.sleepLock)
            logindRestart.start()
    }
    Timer {
        id: logindRestart
        interval: 2000
        onTriggered: logind.running = root.sleepLock
    }

    // idle auto-lock
    IdleMonitor {
        enabled: Config.lock.idleMinutes > 0
        timeout: Math.max(1, Config.lock.idleMinutes) * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle)
            Shell.lock()
    }

    WlSessionLock {
        id: lock
        locked: Shell.locked

        WlSessionLockSurface {
            id: surface
            color: Theme.desk

            LockScreen {
                anchors.fill: parent
                screenName: surface.screen ? surface.screen.name : ""
                primary: surface.screen === Shell.focusedScreen || Quickshell.screens.length === 1
                lockScope: root
            }

            RightClickGuard {}
        }
    }

    // preview: Settings → Lock screen, or `angelos lockPreview`
    Variants {
        model: root.previewing ? Shell.screens : []
        PanelWindow {
            id: previewWin
            required property var modelData
            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: Theme.desk
            WlrLayershell.namespace: "angelos-lock-preview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: Shell.dev ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive

            LockScreen {
                anchors.fill: parent
                screenName: previewWin.modelData.name
                primary: previewWin.modelData === Shell.focusedScreen || Shell.screens.length === 1
                lockScope: root
                preview: true
            }

            RightClickGuard {}
        }
    }
}
