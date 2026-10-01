pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Settings → Updates: pull the dotfiles repository this system was installed
// from and run its installer (scripts/dotfiles-update.sh). Checks once a day
// when allowed; never installs by itself.
Singleton {
    id: root

    readonly property string script: Quickshell.shellDir + "/scripts/dotfiles-update.sh"
    readonly property string managedDir: Config.home + "/.local/share/angelos/dotfiles"
    property string found: ""                     // repository found on disk
    readonly property string repo: Config.expand(Config.updates.repo) || found
    property string state: "idle"                 // idle | checking | updating | cloning | done | failed
    property var log: []
    property var incoming: []
    property int behind: 0
    property int ahead: 0
    property int dirty: 0
    property string branch: ""
    property string remote: ""
    property bool trusted: true
    property string error: ""
    readonly property bool busy: state === "checking" || state === "updating" || state === "cloning"
    readonly property bool available: behind > 0
    // a new version landed on disk, but this shell keeps running the old one from
    // memory: UpdatePrompt asks to restart now or leave it for the next login
    property bool needsRestart: false
    property bool askRestart: false
    property int landed: 0                        // commits the last update brought

    function find() {
        if (!finder.running)
            finder.running = true;
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
        log = ["» " + repo];
        runner.command = ["bash", script, repo];
        runner.running = true;
    }
    function clone() {
        if (busy)
            return;
        state = "cloning";
        log = [];
        runner.command = ["bash", script, "--clone", managedDir];
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
        stdout: SplitParser {
            onRead: line => {
                // "UPDATED <old> <new> <commits>": the script's last word, not for the log
                if (line.startsWith("UPDATED ")) {
                    const p = line.split(" ");
                    if (p[1] !== p[2]) {
                        root.landed = parseInt(p[3]) || 0;
                        root.needsRestart = true;
                    }
                    return;
                }
                root.log = root.log.concat([line]).slice(-500);
            }
        }
        stderr: SplitParser {
            onRead: line => root.log = root.log.concat([line]).slice(-500)
        }
        onExited: code => {
            const cloned = root.state === "cloning";
            root.state = code === 0 ? "done" : "failed";
            root.log = root.log.concat([code === 0 ? I18n.t("✓ готово", "✓ done") : I18n.t("✕ код выхода ", "✕ exit code ") + code]);
            if (code === 0 && !cloned) {
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
