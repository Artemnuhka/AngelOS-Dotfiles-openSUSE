pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Settings → Updates: pull the dotfiles repository this system was installed
// from and run its installer (scripts/dotfiles-update.sh). Checks once a day
// when allowed; never installs by itself. An update counts as installed only
// when the script exits 0 after its "UPDATED" line; anything else is a failure
// with the stage, the text and the snapshot to go back to (restore()).
Singleton {
    id: root

    readonly property string script: Quickshell.shellDir + "/scripts/dotfiles-update.sh"
    readonly property string managedDir: Config.home + "/.local/share/angelos/dotfiles"
    property string found: ""                     // repository found on disk
    readonly property string repo: Config.expand(Config.updates.repo) || found
    property string state: "idle"                 // idle | checking | updating | cloning | restoring | done | restored | failed
    property var log: []
    property var incoming: []
    property int behind: 0
    property int ahead: 0
    property int dirty: 0
    property string branch: ""
    property string remote: ""
    property bool trusted: true
    property string error: ""
    readonly property bool busy: state === "checking" || state === "updating" || state === "cloning" || state === "restoring"
    readonly property bool available: behind > 0
    // a new version landed on disk, but this shell keeps running the old one from
    // memory: UpdatePrompt asks to restart now or leave it for the next login
    property bool needsRestart: false
    property bool askRestart: false
    property int landed: 0                        // commits the last update brought
    // after a restore the prompt says "the previous version is back"
    property bool restored: false

    // the last attempt, as the script recorded it (survives a restart of the shell)
    property string lastStatus: ""                // ok | failed | started (cut short) | restored | restore-failed
    property string failedStage: ""               // install, niri-validate, …
    property string failure: ""                   // what went wrong, in words
    property string backupDir: ""                 // its snapshot
    property var conflicts: []                    // files kept on restore: changed again after the update
    // how the last run in this session ended (state goes back to idle with the check after it)
    property string lastRun: ""                   // "" | ok | failed | restored | restore-failed
    readonly property bool failedUpdate: lastStatus === "failed" || lastStatus === "started"
    readonly property bool canRestore: !!backupDir && (failedUpdate || lastStatus === "restore-failed")
    function stageText(stage) {
        const t = {
            "snapshot": I18n.t("не удалось сделать резервную копию — ничего не менялось", "the snapshot could not be taken — nothing was changed"),
            "pull": I18n.t("git не смог подтянуть новую версию", "git could not fetch the new version"),
            "install": I18n.t("установщик завершился с ошибкой", "the installer failed"),
            "niri-integration": I18n.t("не удалось подключить angelOS к niri", "angelOS could not be wired into niri"),
            "niri-validate": I18n.t("конфиг niri не прошёл проверку", "the niri config failed validation"),
            "niri-missing": I18n.t("niri не найден — конфиг нельзя проверить", "niri is not installed — the config cannot be checked"),
            "snapshot-started": I18n.t("обновление прервалось на середине", "the update was cut short")
        };
        return t[stage] || I18n.t("обновление не удалось", "the update failed");
    }
    property var _pending: null                   // "UPDATED …" seen; it counts once the exit code is 0
    property string _mode: ""                     // what the runner is doing: update | clone | restore
    property bool _snapshot: false                // this run took a snapshot (so the record is about it)
    // shell.qml touches this singleton at start-up: when this instance began
    readonly property double bornAt: Date.now()
    // started after the snapshot <stamp>-update was taken, so it runs files of that update
    function runsFilesOf(dir) {
        const m = String(dir).match(/(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})(?:-\d+)?-update\/?$/);
        return !m || bornAt > new Date(+m[1], +m[2] - 1, +m[3], +m[4], +m[5], +m[6]).getTime();
    }

    function find() {
        if (!finder.running)
            finder.running = true;
        readLast();
    }
    function readLast() {
        if (!lastReader.running)
            lastReader.running = true;
    }
    function check() {
        if (busy || !repo)
            return;
        state = "checking";
        error = "";
        checker.command = ["bash", script, "--check", repo];
        checker.running = true;
    }
    function update() {
        if (busy || !repo)
            return;
        state = "updating";
        lastRun = "";
        _mode = "update";
        _pending = null;
        error = "";
        failure = "";
        failedStage = "";
        conflicts = [];
        _snapshot = false;
        log = ["» " + repo];
        runner.command = ["bash", script, repo];
        runner.running = true;
    }
    function clone() {
        if (busy)
            return;
        state = "cloning";
        _mode = "clone";
        log = [];
        runner.command = ["bash", script, "--clone", managedDir];
        runner.running = true;
    }
    // back to how things were before the last attempt (its snapshot)
    function restore() {
        if (busy || !backupDir)
            return;
        state = "restoring";
        lastRun = "";
        _mode = "restore";
        failure = "";
        conflicts = [];
        log = ["» " + I18n.t("возвращаю как было: ", "restoring: ") + backupDir];
        runner.command = ["bash", script, "--restore", backupDir];
        runner.running = true;
    }
    function restartShell() {
        askRestart = false;
        // `angelos restart` restarts the live instance: never from a dev one
        if (Shell.dev) {
            console.log("angelOS dev: restart skipped");
            return;
        }
        Quickshell.execDetached([Quickshell.shellDir + "/bin/angelos", "restart"]);
    }
    function restartLater() {
        askRestart = false;
    }

    Process {
        id: finder
        running: true
        command: ["bash", root.script, "--find"]
        stdout: StdioCollector {
            onStreamFinished: root.found = text.trim()
        }
    }
    Process {
        id: lastReader
        command: ["bash", root.script, "--last"]
        stdout: StdioCollector {
            onStreamFinished: {
                const conf = [];
                let status = "", stage = "", dir = "", msg = "";
                for (const l of text.split("\n")) {
                    const parts = l.split(" ");
                    const k = parts.shift();
                    if (k === "LAST") {
                        status = parts[0] || "";
                        stage = parts[1] === "-" ? "" : parts[1] || "";
                        dir = parts[2] || "";
                    } else if (k === "MESSAGE")
                        msg = parts.join(" ");
                    else if (k === "CONFLICT")
                        conf.push(parts.join(" "));
                }
                // a runner result from this session is newer than the record it is read with
                if (root.busy)
                    return;
                const bad = status === "failed" || status === "started" || status === "restore-failed";
                root.lastStatus = status;
                root.backupDir = dir;
                root.failedStage = status === "started" ? "snapshot-started" : bad ? stage : "";
                root.failure = bad ? (msg || root.stageText(root.failedStage)) : "";
                root.conflicts = conf;
            }
        }
    }
    Process {
        id: checker
        stdout: StdioCollector {
            onStreamFinished: {
                const inc = [];
                for (const l of text.split("\n")) {
                    const parts = l.split(" ");
                    const k = parts.shift();
                    const v = parts.join(" ");
                    if (k === "BRANCH")
                        root.branch = v;
                    else if (k === "BEHIND")
                        root.behind = parseInt(v) || 0;
                    else if (k === "AHEAD")
                        root.ahead = parseInt(v) || 0;
                    else if (k === "DIRTY")
                        root.dirty = parseInt(v) || 0;
                    else if (k === "REMOTE")
                        root.remote = v;
                    else if (k === "TRUSTED")
                        root.trusted = v === "1";
                    else if (k === "IN")
                        inc.push(v);
                    else if (k === "ERR")
                        root.error = v;
                }
                root.incoming = inc;
                Config.updates.lastCheck = new Date().toISOString();
                Config.updates.available = root.behind;
            }
        }
        onExited: code => {
            root.state = code === 0 ? "idle" : "failed";
            if (code !== 0 && !root.error)
                root.error = I18n.t("не удалось связаться с репозиторием", "could not reach the repository");
            root.maybeNotify();
        }
    }
    Process {
        id: runner
        // the protocol lines of scripts/dotfiles-update.sh; the rest goes to the log
        stdout: SplitParser {
            onRead: line => {
                const p = line.split(" ");
                const rest = n => p.slice(n).join(" ");
                if (p[0] === "UPDATED") {
                    // only a claim until the exit code backs it
                    root._pending = {
                        "changed": p[1] !== p[2],
                        "commits": parseInt(p[3]) || 0
                    };
                    return;
                }
                if (p[0] === "BACKUP") {
                    root.backupDir = rest(1);
                    root._snapshot = true;
                }
                else if (p[0] === "FAILED") {
                    root.failedStage = p[1] || "";
                    root.failure = rest(2) || root.stageText(root.failedStage);
                } else if (p[0] === "RESTORE-FAILED")
                    root.failure = rest(2) || I18n.t("восстановление не удалось", "the restore failed");
                else if (p[0] === "CONFLICT")
                    root.conflicts = root.conflicts.concat([rest(1)]);
                else if (p[0] === "RESTORED")
                    root._pending = {
                        "files": parseInt(p[1]) || 0,
                        "shell": p[3] === "1"
                    };
                root.log = root.log.concat([line]).slice(-500);
            }
        }
        stderr: SplitParser {
            onRead: line => root.log = root.log.concat([line]).slice(-500)
        }
        onExited: code => {
            const mode = root._mode;
            const pending = root._pending;
            root._pending = null;
            root._mode = "";
            root.log = root.log.concat([code === 0 ? I18n.t("✓ готово", "✓ done") : I18n.t("✕ код выхода ", "✕ exit code ") + code]);
            if (mode === "restore") {
                if (code === 0) {
                    root.state = "restored";
                    root.lastRun = "restored";
                    root.lastStatus = "restored";
                    root.failure = "";
                    root.failedStage = "";
                    root.restored = true;
                    // the shell's own files went back; this instance only runs code that is
                    // gone now if it started after the failed update (else it still has the old one)
                    if (pending && pending.shell && root.runsFilesOf(root.backupDir))
                        root.needsRestart = true;
                    if (root.needsRestart)
                        root.askRestart = true;
                } else {
                    root.state = "failed";
                    root.lastRun = "restore-failed";
                    root.lastStatus = "restore-failed";
                    if (!root.failure)
                        root.failure = I18n.t("восстановление не удалось, код ", "the restore failed, code ") + code;
                }
                root.readLast();
                Qt.callLater(root.check);
                return;
            }
            if (mode === "update" && (code !== 0 || !pending)) {
                // whatever was printed, this is not an installed update
                root.state = "failed";
                root.lastRun = "failed";
                if (!root.failure)
                    root.failure = code === 0 ? I18n.t("скрипт не сообщил об успешной установке", "the script did not report a finished install") : I18n.t("обновление не удалось, код ", "the update failed, code ") + code;
                // stopped before its snapshot (local edits, untrusted origin, no network):
                // nothing changed, and the record of an earlier attempt must not
                // replace this message
                if (root._snapshot) {
                    root.lastStatus = "failed";
                    root.find();
                } else if (!finder.running) {
                    finder.running = true;
                }
                Qt.callLater(root.check);
                return;
            }
            root.state = code === 0 ? "done" : "failed";
            if (code === 0 && mode === "update") {
                root.lastRun = "ok";
                root.lastStatus = "ok";
                root.failure = "";
                root.failedStage = "";
                root.restored = false;
                if (pending.changed) {
                    root.landed = pending.commits;
                    root.needsRestart = true;
                }
                // the installer ships default binds / cursor: put the user's choices back
                WorkspaceAnim.reapply();
                if (Cursors.hellOn)
                    Cursors.put(Config.cursor.hell, Config.cursor.size);
                else if (Config.cursor.theme)
                    Cursors.apply(Config.cursor.theme, Config.cursor.size);
                // also after a "nothing new" run while an earlier update still waits
                if (root.needsRestart)
                    root.askRestart = true;
            }
            root.find();
            Qt.callLater(root.check);
        }
    }

    // ---- once a day, only telling ----
    property string notifiedFor: ""
    function maybeNotify() {
        if (behind <= 0 || !incoming.length || Shell.dev)
            return;
        const head = incoming[0].split(" ")[0];
        if (head === notifiedFor)
            return;
        notifiedFor = head;
        Quickshell.execDetached(["notify-send", "-a", "angelOS", "-i", "system-software-update", I18n.t("Доступно обновление angelOS", "An angelOS update is available"), I18n.t("Новых изменений: ", "New changes: ") + behind + I18n.t(". Настройки → Обновления.", ". Settings → Updates.")]);
    }
    Timer {
        interval: 90 * 1000
        running: Config.ready && Config.updates.autoCheck
        repeat: true
        onTriggered: {
            interval = 6 * 3600 * 1000;
            const last = Date.parse(Config.updates.lastCheck || "") || 0;
            if (Date.now() - last > 22 * 3600 * 1000)
                root.check();
        }
    }
}
