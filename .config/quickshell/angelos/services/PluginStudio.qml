pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The worker owns API calls and drafts; closing Settings does not lose a job.
Singleton {
    id: root

    property var session: ({messages: [], plan: null, draft: null, installed: ""})
    property var keys: ({openai: false, anthropic: false})
    property var cli: ({})              // {"claude-cli": {installed, loggedIn, method}, "codex-cli": {…}}
    property string error: ""
    property string stage: ""
    property string action: ""
    property bool busy: false
    property bool loaded: false
    property string composer: ""
    signal completed(string action)
    property bool _received: false
    property string _request: ""
    property string _enableAfterScan: ""
    property bool _addDesktop: false
    property string _screen: ""
    readonly property var plan: session.plan || null
    readonly property var draft: session.draft || null
    readonly property var providers: [
        {label: I18n.t("Claude · вход через браузер", "Claude · browser sign-in"), value: "claude-cli"},
        {label: I18n.t("Codex · вход через ChatGPT", "Codex · ChatGPT sign-in"), value: "codex-cli"},
        {label: "OpenAI API", value: "openai"},
        {label: "Anthropic API", value: "anthropic"}
    ]
    readonly property bool isCli: Config.developer.provider === "claude-cli" || Config.developer.provider === "codex-cli"
    readonly property var cliState: cli[Config.developer.provider] || ({})
    // ready to send: a saved API key, or an installed and signed-in CLI
    readonly property bool hasKey: isCli ? (!!cliState.installed && !!cliState.loggedIn) : !!keys[Config.developer.provider]
    readonly property string model: ({
            "anthropic": Config.developer.anthropicModel,
            "openai": Config.developer.openaiModel,
            "claude-cli": Config.developer.claudeCliModel,
            "codex-cli": Config.developer.codexCliModel
        })[Config.developer.provider] || ""
    function setModel(value) {
        const key = ({
                "anthropic": "anthropicModel",
                "openai": "openaiModel",
                "claude-cli": "claudeCliModel",
                "codex-cli": "codexCliModel"
            })[Config.developer.provider];
        if (key)
            Config.developer[key] = value;
    }
    // the CLIs sign in through the browser themselves; angelOS never sees the tokens
    function login() {
        const argv = Config.developer.provider === "codex-cli" ? ["codex", "login"] : ["claude", "auth", "login"];
        Quickshell.execDetached(Shell.terminalArgv(["sh", "-c", 'PATH="$HOME/.local/bin:$PATH"; "$@"; printf "\\n♡ Готово — вернись в angelOS и нажми «Проверить вход». Enter закроет окно."; read _', "sh"].concat(argv)));
    }
    readonly property string statusText: !busy ? "" : stage === "validation"
        ? I18n.t("Проверяю файлы…", "Checking files…")
        : action === "generate" ? I18n.t("ИИ пишет плагин… это может занять несколько минут.", "AI is writing your plugin… this may take a few minutes.")
        : action === "plan" ? I18n.t("ИИ разбирает запрос…", "AI is reviewing your request…")
        : I18n.t("Обрабатываю…", "Working…")

    function send(name, params) {
        if (busy || worker.running || (!Config.developer.enabled && name !== "status"))
            return false;
        error = "";
        action = name;
        stage = "";
        _received = false;
        _request = JSON.stringify(Object.assign({
            action: name,
            language: Config.appearance.language,
            provider: Config.developer.provider,
            model: model,
            maxOutputTokens: Config.developer.maxOutputTokens
        }, params || {})) + "\n";
        busy = true;
        worker.running = true;
        deadline.interval = isCli ? 660000 : 240000;
        deadline.restart();
        return true;
    }
    function refresh() {
        send("status");
    }
    function cancel() {
        // Installation is a short, atomic local operation; never interrupt it.
        if (!busy || action === "install")
            return;
        worker.signal(15);
        _request = "";
        _received = true;
        error = I18n.t("Запрос отменён. Провайдер мог уже учесть отправленный запрос.", "Request cancelled. The provider may already have counted the request.");
    }
    function install(addDesktop) {
        if (!draft)
            return;
        _addDesktop = addDesktop;
        _screen = Shell.focusedScreen ? Shell.focusedScreen.name : "";
        send("install", {digest: draft.digest});
    }
    function activateInstalled() {
        const id = _enableAfterScan;
        const p = id ? Plugins.byId(id) : null;
        if (!p)
            return;
        _enableAfterScan = "";
        Plugins.setEnabled(id, true);
        if (_addDesktop && p.desktopWidget && _screen && !DesktopWidgets.has("plugin:" + id, _screen))
            DesktopWidgets.add("plugin:" + id, _screen);
    }
    function receive(event) {
        if (event.event === "progress") {
            stage = event.stage;
            return;
        }
        _received = true;
        if (event.event === "error") {
            error = event.message;
            return;
        }
        if (event.keys !== undefined)
            keys = event.keys;
        if (event.cli !== undefined)
            cli = event.cli;
        if (event.session !== undefined)
            session = event.session;
        if (action === "plan" || action === "reset")
            composer = "";
        loaded = true;
        if (event.installed) {
            _enableAfterScan = event.installed.id;
            Plugins.reload();
        }
        completed(action);
    }
    Connections {
        target: Plugins
        function onPluginsChanged() {
            root.activateInstalled();
        }
    }
    Connections {
        target: Config.developer
        function onEnabledChanged() {
            if (!Config.developer.enabled)
                root.cancel();
        }
    }
    Timer {
        id: deadline
        interval: 240000
        onTriggered: {
            if (root.busy && root.action !== "install") {
                worker.signal(15);
                root._received = true;
                root._request = "";
                root.error = I18n.t("Превышено время ожидания. Повторите запрос.", "Request timed out. Try again.");
            }
        }
    }
    Process {
        id: worker
        command: ["python3", "-u", Quickshell.shellDir + "/scripts/plugin-studio.py"]
        stdinEnabled: true
        onStarted: {
            write(root._request);
            root._request = "";
        }
        stdout: SplitParser {
            onRead: data => {
                try {
                    root.receive(JSON.parse(data));
                } catch (e) {
                    root.error = I18n.t("Не удалось прочитать ответ мастера.", "Could not read the Studio response.");
                }
            }
        }
        stderr: StdioCollector {}
        onExited: {
            deadline.stop();
            root._request = "";
            root.busy = false;
            if (!root._received)
                root.error = I18n.t("Мастер завершился без ответа. Проверьте наличие Python 3.", "Studio exited without a response. Check that Python 3 is installed.");
        }
        onRunningChanged: {
            if (!running && root.busy) {
                // Also handles failure to start, where exited may not fire.
                Qt.callLater(() => {
                    if (!worker.running) {
                        root.busy = false;
                        root._request = "";
                        deadline.stop();
                        if (!root._received && !root.error)
                            root.error = I18n.t("Не удалось запустить мастер.", "Could not start Studio.");
                    }
                });
            }
        }
    }
}
