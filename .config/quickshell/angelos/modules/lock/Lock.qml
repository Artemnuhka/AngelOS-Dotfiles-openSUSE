pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.config
import qs.services
import qs.widgets

// ext-session-lock screen with PAM auth.
Scope {
    id: root

    property string status: ""
    property bool busy: pam.active
    property int fails: 0
    property string buffer: ""

    function submit(pw) {
        if (pam.active)
            return;
        buffer = pw;
        status = I18n.t("проверяю…", "Checking…");
        pam.start();
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
            if (result === PamResult.Success) {
                root.status = "";
                root.fails = 0;
                Shell.locked = false;
            } else {
                root.fails++;
                root.status = root.fails > 2 ? I18n.t("ну пожааалуйста, вспомни пароль…", "Try your password again…") : I18n.t("неправильный пароль ✕", "Incorrect password ✕");
                root.shake();
            }
        }
        onError: e => {
            root.status = I18n.t("ошибка PAM: ", "PAM error: ") + e;
        }
    }

    signal shake

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
        }
    }
}
