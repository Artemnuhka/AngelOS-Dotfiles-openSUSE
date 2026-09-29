pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

PxPage {
    id: page

    heading: I18n.t("Мастер плагинов", "Plugin Studio")
    subtitle: I18n.t("Опиши идею → ответь на вопросы → проверь результат → установи. ИИ получает правила angelOS: тему, размеры, настройки и жизненный цикл плагинов.", "Describe an idea → answer questions → review → install. AI receives the angelOS rules for themes, sizing, settings and plugin lifecycle.")
    property bool connectionOpen: !PluginStudio.hasKey
    property bool historyOpen: false
    property bool resetConfirm: false
    property bool addDesktop: true
    property string selectedFile: "manifest.json"
    readonly property var plan: PluginStudio.plan
    readonly property var draft: PluginStudio.draft
    readonly property var spec: plan ? plan.spec : null
    readonly property bool installed: !!PluginStudio.session.installed
    readonly property var questions: plan ? plan.questions : []
    readonly property var files: draft ? draft.files || [] : []
    readonly property string code: (files.find(f => f.path === selectedFile) || files[0] || {}).content || ""
    readonly property var messages: (PluginStudio.session.messages || []).map(m => {
        if (m.role === "user")
            return {role: I18n.t("Ты", "You"), text: m.content};
        try {
            return {role: "angelOS", text: JSON.parse(m.content).summary};
        } catch (e) {
            return {role: "angelOS", text: ""};
        }
    })

    function submit() {
        PluginStudio.send("plan", {prompt: prompt.text.trim()});
    }
    function answer(question, value) {
        PluginStudio.composer += (PluginStudio.composer ? "\n" : "") + question + " — " + value;
        prompt.input.forceActiveFocus();
    }
    function kindLabel(kind) {
        return ({
            desktop: I18n.t("Виджет рабочего стола", "Desktop widget"),
            bar: I18n.t("Виджет панели", "Bar widget"),
            service: I18n.t("Фоновый сервис", "Background service"),
            menu: I18n.t("Меню рабочего стола", "Desktop menu"),
            launcher: I18n.t("Поиск в лаунчере", "Launcher search")
        })[kind] || kind;
    }
    Component.onCompleted: if (!PluginStudio.busy)
        PluginStudio.refresh()
    Connections {
        target: PluginStudio
        function onCompleted(action) {
            if (action === "save_key")
                page.connectionOpen = false;
            const section = action === "plan" ? planGroup : action === "generate" || action === "review" ? resultGroup : action === "install" ? installedGroup : null;
            if (section)
                Qt.callLater(() => page.contentY = Math.max(0, Math.min(section.y, page.contentHeight - page.height)));
        }
        function onErrorChanged() {
            if (PluginStudio.error)
                Qt.callLater(() => page.contentY = Math.max(0, page.contentHeight - page.height));
        }
    }

    Flow {
        width: parent.width
        spacing: Theme.u * 3
        Repeater {
            model: [I18n.t("1 · Идея", "1 · Idea"), I18n.t("2 · План", "2 · Plan"), I18n.t("3 · Результат", "3 · Review"), I18n.t("4 · Установка", "4 · Install")]
            PxButton {
                required property string modelData
                required property int index
                text: modelData
                compact: true
                checked: index === (page.installed ? 3 : page.draft ? 2 : page.plan ? 1 : 0)
                enabled: false
                opacity: 1
            }
        }
    }

    PxGroup {
        title: I18n.t("Подключение ИИ", "AI connection")
        icon: "sparkle"
        width: parent.width
        Flow {
            width: parent.width
            spacing: Theme.u * 4
            PxText {
                readonly property var p: PluginStudio.providers.find(x => x.value === Config.developer.provider)
                text: (p ? p.label : Config.developer.provider) + " · " + (PluginStudio.model || I18n.t("модель по умолчанию", "default model")) + " · " + (PluginStudio.isCli ? (!PluginStudio.cliState.installed ? I18n.t("CLI не установлен", "CLI not installed") : PluginStudio.cliState.loggedIn ? I18n.t("вход выполнен ♡", "signed in ♡") : I18n.t("нужно войти", "sign-in needed")) : (PluginStudio.hasKey ? I18n.t("ключ сохранён", "key saved") : I18n.t("нужен API-ключ", "API key needed")))
                wrapMode: Text.Wrap
                width: Math.min(implicitWidth, parent.width)
            }
            PxButton {
                compact: true
                text: page.connectionOpen ? I18n.t("Свернуть", "Collapse") : I18n.t("Настроить", "Configure")
                onClicked: page.connectionOpen = !page.connectionOpen
            }
        }
        Column {
            visible: page.connectionOpen
            width: parent.width
            spacing: Theme.u * 5
            enabled: !PluginStudio.busy
            SettingRow {
                label: I18n.t("Провайдер", "Provider")
                PxCombo {
                    width: parent.width
                    model: PluginStudio.providers
                    currentValue: Config.developer.provider
                    onActivated: value => {
                        apiKey.text = "";
                        Config.developer.provider = value;
                        PluginStudio.refresh();
                    }
                }
            }
            SettingRow {
                label: PluginStudio.isCli ? I18n.t("Модель", "Model") : I18n.t("Модель · API ID", "Model · API ID")
                hint: PluginStudio.isCli ? I18n.t("пусто — модель по умолчанию в CLI", "Empty uses the CLI default") : ""
                PxField {
                    width: parent.width
                    text: PluginStudio.model
                    placeholder: Config.developer.provider === "claude-cli" ? "sonnet / opus" : Config.developer.provider === "codex-cli" ? I18n.t("как в ~/.codex/config.toml", "as in ~/.codex/config.toml") : ""
                    onEdited: PluginStudio.setModel(text.trim())
                }
            }

            // ---- browser sign-in through the official CLI ----
            Column {
                visible: PluginStudio.isCli
                width: parent.width
                spacing: Theme.u * 3
                PxText {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: PluginStudio.hasKey ? Theme.ok : Theme.textDim
                    text: !PluginStudio.cliState.installed ? (Config.developer.provider === "codex-cli" ? I18n.t("Codex CLI не найден. Установи: sudo pacman -S openai-codex (или npm i -g @openai/codex).", "Codex CLI not found. Install it: sudo pacman -S openai-codex (or npm i -g @openai/codex).") : I18n.t("Claude Code не найден. Установи его: https://claude.com/claude-code", "Claude Code not found. Install it from https://claude.com/claude-code")) : PluginStudio.cliState.loggedIn ? I18n.t("Вход выполнен", "Signed in") + (PluginStudio.cliState.method ? " (" + PluginStudio.cliState.method + ")" : "") + " ♡" : I18n.t("Не выполнен вход.", "Not signed in.")
                }
                Flow {
                    width: parent.width
                    spacing: Theme.u * 3
                    PxButton {
                        visible: !!PluginStudio.cliState.installed
                        text: PluginStudio.cliState.loggedIn ? I18n.t("Войти заново", "Sign in again") : I18n.t("Войти через браузер", "Sign in via browser")
                        icon: "lock"
                        accent: !PluginStudio.cliState.loggedIn
                        onClicked: PluginStudio.login()
                    }
                    PxButton {
                        text: I18n.t("Проверить вход", "Check sign-in")
                        icon: "refresh"
                        onClicked: PluginStudio.refresh()
                    }
                }
                PxText {
                    width: parent.width
                    wrapMode: Text.Wrap
                    dim: true
                    text: Config.developer.provider === "codex-cli" ? I18n.t("Запросы идут через твой Codex CLI и расходуют лимиты ChatGPT-подписки (или провайдера из ~/.codex/config.toml). Codex запускается без shell, веб-поиска, MCP и computer use, в пустой папке и только на чтение.", "Requests go through your Codex CLI and use your ChatGPT plan limits (or the provider in ~/.codex/config.toml). Codex runs without shell, web search, MCP or computer use, in an empty read-only folder.") : I18n.t("Запросы идут через Claude Code и расходуют лимиты подписки Claude. Claude запускается без инструментов, MCP и твоих настроек/хуков, в пустой папке. API-ключ из окружения не используется.", "Requests go through Claude Code and use your Claude plan limits. Claude runs without tools, MCP or your settings/hooks, in an empty folder. An API key in the environment is ignored.")
                }
            }

            // ---- API key (paid API access) ----
            Column {
                visible: !PluginStudio.isCli
                width: parent.width
                spacing: Theme.u * 5
                SettingRow {
                    label: "API key"
                    hint: PluginStudio.hasKey ? I18n.t("Сохранён. Вставь новый, чтобы заменить.", "Saved. Paste a new key to replace it.") : ""
                    PxField {
                        id: apiKey
                        width: parent.width
                        password: true
                        placeholder: Config.developer.provider === "anthropic" ? "Anthropic API key" : "OpenAI API key"
                    }
                }
                Flow {
                    width: parent.width
                    spacing: Theme.u * 3
                    PxButton {
                        text: I18n.t("Сохранить ключ", "Save key")
                        icon: "lock"
                        enabled: apiKey.text.trim().length > 0
                        onClicked: {
                            if (PluginStudio.send("save_key", {key: apiKey.text.trim()}))
                                apiKey.text = "";
                        }
                    }
                    PxButton {
                        text: I18n.t("Удалить ключ", "Delete key")
                        enabled: PluginStudio.hasKey
                        onClicked: PluginStudio.send("delete_key")
                    }
                }
                SettingRow {
                    label: I18n.t("Лимит ответа", "Output limit")
                    hint: I18n.t("Токенов на генерацию", "Tokens per generation")
                    PxSpin {
                        from: 2048
                        to: 32000
                        stepSize: 1000
                        value: Config.developer.maxOutputTokens
                        onMoved: value => Config.developer.maxOutputTokens = value
                    }
                }
                PxText {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: I18n.t("Нужен ключ API с отдельным балансом; запросы платные. Без ключа выбери «вход через браузер» — тогда хватит подписки Claude или ChatGPT. Ключ хранится локально в закрытом файле, отдельно от плагинов. Провайдер получает диалог и документацию angelOS.", "An API key uses separate, paid API billing. Without one, pick a browser sign-in provider — a Claude or ChatGPT subscription is enough. The key stays in a private local file, separate from plugins. The provider receives the conversation and angelOS documentation.")
                    dim: true
                }
            }
        }
    }

    PxGroup {
        title: I18n.t("Твоя идея", "Your idea")
        icon: "heart"
        width: parent.width
        visible: !page.installed
        PxTextArea {
            id: prompt
            text: PluginStudio.composer
            onEdited: PluginStudio.composer = text
            width: parent.width
            implicitHeight: Theme.u * 65
            readOnly: PluginStudio.busy
            placeholder: page.plan ? I18n.t("Ответь на вопросы или напиши, что изменить в плане…", "Answer the questions or describe changes to the plan…") : I18n.t("Например: хочу виджет на рабочем столе, который показывает, сколько осталось токенов в Codex.", "For example: I want a desktop widget showing how many Codex tokens I have left.")
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 3
            PxButton {
                text: page.plan ? I18n.t("Отправить уточнение", "Send clarification") : I18n.t("Обсудить идею", "Discuss idea")
                icon: "sparkle"
                accent: true
                enabled: !PluginStudio.busy && PluginStudio.hasKey && prompt.text.trim() !== ""
                onClicked: page.submit()
            }
            PxButton {
                text: I18n.t("Пример: счётчик", "Example: counter")
                visible: !page.plan && prompt.text === ""
                enabled: !PluginStudio.busy
                onClicked: PluginStudio.composer = I18n.t("Хочу виджет-счётчик на рабочем столе: кнопка увеличивает число, а в настройках можно сбросить его. Сохраняй число между перезапусками.", "I want a desktop counter widget: a button increments the number, and settings can reset it. Keep the count between restarts.")
            }
            PxButton {
                visible: page.messages.length > 0
                text: page.historyOpen ? I18n.t("Скрыть диалог", "Hide conversation") : I18n.t("История диалога", "Conversation")
                onClicked: page.historyOpen = !page.historyOpen
            }
        }
        PxText {
            visible: PluginStudio.busy && PluginStudio.action === "plan"
            text: PluginStudio.statusText
            color: Theme.accent
        }
        Column {
            width: parent.width
            visible: page.historyOpen
            spacing: Theme.u * 4
            Repeater {
                model: page.messages
                PxText {
                    required property var modelData
                    width: parent.width
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    text: modelData.role + ": " + modelData.text
                }
            }
        }
    }

    PxGroup {
        id: planGroup
        visible: !!page.plan
        title: I18n.t("Как будет работать", "How it will work")
        icon: "layers"
        width: parent.width
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            text: page.plan ? page.plan.summary : ""
        }
        Repeater {
            model: page.questions
            Column {
                id: question
                required property var modelData
                required property int index
                width: parent.width
                spacing: Theme.u * 3
                PxText {
                    width: parent.width
                    text: (question.index + 1) + ". " + question.modelData.question
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    font.bold: true
                }
                Flow {
                    width: parent.width
                    spacing: Theme.u * 3
                    Repeater {
                        model: question.modelData.options
                        PxBox {
                            id: choice
                            required property string modelData
                            width: Math.min(choiceLabel.implicitWidth + Theme.u * 12, parent.width)
                            height: choiceLabel.implicitHeight + Theme.u * 10
                            enabled: !PluginStudio.busy
                            opacity: enabled ? 1 : 0.45
                            sunken: choiceMouse.pressed
                            color: choiceMouse.containsMouse ? Theme.faceAlt : Theme.face
                            PxText {
                                id: choiceLabel
                                anchors.centerIn: parent
                                width: parent.width - Theme.u * 6
                                wrapMode: Text.Wrap
                                textFormat: Text.PlainText
                                text: choice.modelData
                            }
                            MouseArea {
                                id: choiceMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.answer(question.modelData.question, choice.modelData)
                            }
                        }
                    }
                }
            }
        }
        PxText {
            width: parent.width
            visible: !!page.spec
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            font.bold: true
            text: page.spec ? page.spec.name + " · " + page.kindLabel(page.spec.kind) + "\n" + page.spec.id : ""
        }
        PxText {
            width: parent.width
            visible: !!page.spec && ["desktop", "bar"].includes(page.spec.kind)
            wrapMode: Text.Wrap
            text: page.spec ? I18n.t("Размер содержимого: ", "Content size: ") + page.spec.widthUnits + " × " + page.spec.heightUnits + " u  ·  " + (page.spec.widthUnits * Theme.u) + " × " + (page.spec.heightUnits * Theme.u) + " px" + I18n.t(" при текущем масштабе. Цвета и шрифты — из активной темы.", " at the current scale. Colors and fonts follow the active theme.") : ""
            dim: true
        }
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            text: page.spec ? page.spec.behavior : ""
        }
        Repeater {
            model: page.spec ? [
                {title: I18n.t("Данные и доступ", "Data and access"), items: page.spec.dataSources},
                {title: I18n.t("Настройки", "Settings"), items: page.spec.settings},
                {title: I18n.t("Зависимости", "Dependencies"), items: page.spec.dependencies},
                {title: I18n.t("Ограничения", "Limitations"), items: page.spec.limitations}
            ] : []
            PxText {
                required property var modelData
                width: parent.width
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                text: modelData.title + ": " + (modelData.items.length ? modelData.items.join(" · ") : I18n.t("нет", "none"))
                dim: true
            }
        }
        PxButton {
            visible: page.questions.length > 0
            text: I18n.t("Ответить в поле запроса", "Answer in the prompt field")
            enabled: !PluginStudio.busy
            onClicked: {
                page.contentY = 0;
                prompt.input.forceActiveFocus();
            }
        }
        PxButton {
            visible: !page.draft && !page.installed
            text: I18n.t("План подходит — создать плагин", "Approve plan — generate plugin")
            icon: "sparkle"
            accent: true
            enabled: !PluginStudio.busy && PluginStudio.hasKey && page.questions.length === 0 && prompt.text.trim() === ""
            onClicked: PluginStudio.send("generate")
        }
        PxText {
            visible: PluginStudio.busy && PluginStudio.action === "generate"
            width: parent.width
            wrapMode: Text.Wrap
            text: PluginStudio.statusText
            color: Theme.accent
        }
    }

    PxGroup {
        id: resultGroup
        visible: !!page.draft
        title: I18n.t("Результат", "Result")
        icon: "package"
        width: parent.width
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            text: page.draft ? page.draft.summary : ""
        }
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            text: page.draft ? (page.draft.notes || []).join("\n") : ""
            dim: true
        }
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            color: page.draft && page.draft.errors.length ? Theme.danger : Theme.ok
            text: page.draft ? (page.draft.errors.length
                ? I18n.t("Нужно исправить:\n", "Needs fixing:\n") + page.draft.errors.join("\n")
                : I18n.t("Структура и синтаксис проверены. Проверь код и поведение после установки.", "Structure and syntax checked. Review the code and verify behavior after installation.")) : ""
        }
        PxCombo {
            width: parent.width
            model: page.files.map(f => ({label: f.path, value: f.path}))
            currentValue: page.selectedFile
            onActivated: value => page.selectedFile = value
        }
        PxTextArea {
            width: parent.width
            implicitHeight: Theme.u * 125
            readOnly: true
            monospace: true
            text: page.code
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 3
            PxButton {
                text: I18n.t("Открыть файлы", "Open files")
                icon: "folder"
                onClicked: if (page.draft)
                    Shell.openPath(page.installed ? Config.pluginsDir + "/" + PluginStudio.session.installed : page.draft.directory)
            }
            PxButton {
                visible: !page.installed
                text: I18n.t("Проверить ещё раз", "Recheck files")
                icon: "refresh"
                enabled: !PluginStudio.busy
                onClicked: PluginStudio.send("review")
            }
            PxButton {
                visible: !page.installed
                text: page.draft && page.draft.errors.length ? I18n.t("Исправить с ИИ", "Repair with AI") : I18n.t("Пересоздать с ИИ", "Regenerate with AI")
                enabled: !PluginStudio.busy && PluginStudio.hasKey && prompt.text.trim() === ""
                onClicked: PluginStudio.send("generate")
            }
        }
        PxText {
            visible: !page.installed
            width: parent.width
            wrapMode: Text.Wrap
            text: I18n.t("После установки код работает с правами твоего пользователя. До нажатия «Установить» он не запускается.", "Installed code runs with your user permissions. It does not run before you click Install.")
            dim: true
        }
        PxToggle {
            visible: !page.installed && !!page.draft && !!page.draft.manifest.desktopWidget
            text: I18n.t("Добавить виджет на текущий экран", "Add widget to the current screen")
            checked: page.addDesktop
            onToggled: value => page.addDesktop = value
        }
        PxButton {
            visible: !page.installed
            text: I18n.t("Установить", "Install")
            icon: "plus"
            accent: true
            enabled: !PluginStudio.busy && !!page.draft && page.draft.errors.length === 0 && prompt.text.trim() === ""
            onClicked: PluginStudio.install(page.addDesktop)
        }
    }

    PxGroup {
        id: installedGroup
        visible: page.installed
        title: I18n.t("Плагин установлен ♡", "Plugin installed ♡")
        icon: "heart"
        width: parent.width
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            text: I18n.t("Он доступен в Настройки → Плагины. Там его можно настроить и выключить.", "Find it in Settings → Plugins, where you can configure or disable it.")
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 3
            PxButton {
                text: I18n.t("Настроить плагин", "Configure plugin")
                icon: "gear"
                enabled: !!Plugins.byId(PluginStudio.session.installed)
                onClicked: Shell.openSettings("plugin:" + PluginStudio.session.installed)
            }
            PxButton {
                text: I18n.t("Все плагины", "All plugins")
                onClicked: Shell.openSettings("plugins")
            }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.u * 3
        PxText {
            visible: PluginStudio.busy
            width: parent.width
            wrapMode: Text.Wrap
            text: PluginStudio.statusText
            color: Theme.accent
        }
        PxText {
            visible: PluginStudio.error !== ""
            width: parent.width
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            text: PluginStudio.error
            color: Theme.danger
        }
        PxText {
            visible: !!PluginStudio.session.usage
            width: parent.width
            wrapMode: Text.Wrap
            text: I18n.t("Последний запрос: ", "Last request: ") + ((PluginStudio.session.usage || {}).input_tokens || 0) + I18n.t(" входных / ", " input / ") + ((PluginStudio.session.usage || {}).output_tokens || 0) + I18n.t(" выходных токенов.", " output tokens.")
            dim: true
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 3
            PxButton {
                visible: PluginStudio.busy && ["plan", "generate"].includes(PluginStudio.action)
                text: I18n.t("Отменить запрос", "Cancel request")
                onClicked: PluginStudio.cancel()
            }
            PxButton {
                visible: page.messages.length > 0 || page.installed
                enabled: !PluginStudio.busy
                text: page.resetConfirm ? I18n.t("Начать новый диалог?", "Start a new conversation?") : I18n.t("Новый плагин", "New plugin")
                onClicked: {
                    if (!page.resetConfirm) {
                        page.resetConfirm = true;
                        return;
                    }
                    if (PluginStudio.send("reset")) {
                        PluginStudio.composer = "";
                        page.resetConfirm = false;
                        page.selectedFile = "manifest.json";
                    }
                }
            }
        }
    }
}
