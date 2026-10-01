pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services

// Settings → Updates against a stand-in dotfiles-update.sh (tests/updates/run.sh):
// the script's answers come from a plan, one per run, and each step checks what
// services/Updates.qml (and the page) made of them. Prints "TEST <name> PASS|FAIL
// [detail]", then "TEST DONE <failures>".
Scope {
    id: root

    property int failures: 0
    function report(name, ok, detail) {
        if (!ok)
            failures++;
        console.log("TEST " + name + " " + (ok ? "PASS" : "FAIL") + (detail ? " " + detail : ""));
    }
    function find(item, pred) {
        if (!item)
            return null;
        if (pred(item))
            return item;
        for (const c of item.children) {
            const r = find(c, pred);
            if (r)
                return r;
        }
        return null;
    }
    function shownText(needle) {
        return !!find(pageLoader.item, it => it.visible && typeof it.text === "string" && it.text.indexOf(needle) >= 0);
    }
    function state() {
        return "state=" + Updates.state + " run=" + Updates.lastRun + " last=" + Updates.lastStatus + " stage=" + Updates.failedStage + " restart=" + Updates.needsRestart + " failure=" + Updates.failure;
    }

    FloatingWindow {
        id: win
        implicitWidth: 900
        implicitHeight: 1400
        title: "angelOS updates test"
        color: Theme.desk
        Loader {
            id: pageLoader
            anchors.fill: parent
            active: false
            source: Quickshell.shellDir + "/modules/settings/pages/UpdatesPage.qml"
        }
    }

    // each step: start something, wait until Updates is idle again, check
    property int step: -1
    property int waited: 0
    readonly property var steps: [
        {
            "name": "dirty-repo",
            "run": () => Updates.update(),
            "check": () => {
                report("dirty-repo-failed", Updates.lastRun === "failed" && Updates.failure.indexOf("3") >= 0, state());
                report("dirty-repo-no-restore", !Updates.canRestore && !Updates.needsRestart && !Updates.askRestart, state());
                report("page-dirty-message", (pageLoader.active = true) && shownText("код 3"));
            }
        },
        {
            "name": "install-fails",
            "run": () => Updates.update(),
            "check": () => {
                report("install-fails-state", Updates.lastRun === "failed" && Updates.failedStage === "install" && Updates.lastStatus === "failed", state());
                report("install-fails-not-installed", !Updates.needsRestart && !Updates.askRestart && Updates.landed === 0, state());
                report("install-fails-offers-restore", Updates.canRestore && Updates.backupDir.endsWith("20260101-120000-update"), "backup=" + Updates.backupDir);
                pageLoader.active = true;
            }
        },
        {
            "name": "page",
            "runs": false,
            "run": () => {},
            "check": () => {
                report("page-loads", pageLoader.status === Loader.Ready, "status=" + pageLoader.status);
                report("page-says-not-installed", shownText("Обновление не установлено") || shownText("The update is not installed"));
                report("page-shows-stage-and-backup", (shownText("установщик завершился") || shownText("the installer failed")) && shownText("20260101-120000-update"));
                report("page-offers-restore", !!find(pageLoader.item, it => it.visible && it.text === I18n.t("Вернуть как было до обновления", "Restore the state before the update")));
                report("page-no-restart-offer", !shownText("Новая версия установлена") && !shownText("The new version is installed"));
            }
        },
        {
            "name": "claims-then-fails",
            "run": () => Updates.update(),
            "check": () => {
                // "UPDATED" came first, then the validation failed: not an installed update
                report("updated-line-ignored-on-failure", Updates.lastRun === "failed" && Updates.failedStage === "niri-validate" && !Updates.needsRestart && Updates.landed === 0, state());
            }
        },
        {
            "name": "restore-fails",
            "run": () => Updates.restore(),
            "check": () => {
                report("restore-fails-state", Updates.lastRun === "restore-failed" && Updates.lastStatus === "restore-failed" && Updates.failure.indexOf("niri") >= 0, state());
                report("restore-fails-still-offered", Updates.canRestore, state());
                report("page-says-restore-failed", shownText("Вернуть не получилось") || shownText("The restore failed"));
            }
        },
        {
            "name": "restore-ok",
            "run": () => Updates.restore(),
            "check": () => {
                report("restore-ok-state", Updates.lastRun === "restored" && Updates.lastStatus === "restored" && Updates.restored && !Updates.canRestore, state());
                report("restore-ok-conflicts", Updates.conflicts.length === 1 && Updates.conflicts[0].endsWith("layout.kdl"), JSON.stringify(Updates.conflicts));
                // the snapshot is newer than this instance: it still runs the old code, no restart
                report("restore-ok-no-needless-restart", !Updates.needsRestart && !Updates.askRestart, state());
                report("page-lists-conflict", shownText("layout.kdl"));
            }
        },
        {
            "name": "update-ok",
            "run": () => Updates.update(),
            "check": () => {
                report("update-ok-state", Updates.lastRun === "ok" && Updates.lastStatus === "ok" && !Updates.failure && !Updates.canRestore, state());
                report("update-ok-restart-offered", Updates.needsRestart && Updates.askRestart && Updates.landed === 2 && !Updates.restored, state());
                report("page-says-installed", shownText("Новая версия установлена") || shownText("The new version is installed"));
            }
        }
    ]

    // a run starts only on an idle Updates (the page starts a check when it opens,
    // and update() ignores clicks while one runs), and it must really have run
    property bool started: false
    property bool sawRun: false
    Connections {
        target: Updates
        function onStateChanged() {
            if (Updates.state === "updating" || Updates.state === "restoring")
                root.sawRun = true;
        }
    }
    Timer {
        interval: 150
        running: true
        repeat: true
        onTriggered: {
            if (root.step < 0) {
                // the repository found by --find, the record read by --last
                if (!Updates.repo || ++root.waited < 10)
                    return;
                root.step = 0;
                root.started = false;
                return;
            }
            const s = root.steps[root.step];
            if (!root.started) {
                if (Updates.busy)
                    return;
                root.sawRun = false;
                root.waited = 0;
                root.started = true;
                s.run();
                return;
            }
            if (Updates.busy || (s.runs !== false && !root.sawRun) || ++root.waited < 4)
                return;
            s.check();
            root.started = false;
            if (++root.step >= root.steps.length) {
                stop();
                console.log("TEST DONE " + root.failures);
                Qt.callLater(Qt.quit);
            }
        }
    }
    Timer {
        interval: 60000
        running: true
        onTriggered: {
            root.report("timeout", false, "step " + root.step);
            console.log("TEST DONE " + root.failures);
            Qt.quit();
        }
    }
}
