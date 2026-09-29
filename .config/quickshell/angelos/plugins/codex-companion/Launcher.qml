import QtQuick
import qs.config
import qs.services
import "."

// "codex <task>" → Codex in a terminal · "codex ? question" → quick answer.
QtObject {
    id: root

    property var plugin
    property string pluginId
    readonly property string prefix: "codex"
    readonly property bool global: false
    signal changed

    function query(text, prefixed) {
        if (!prefixed)
            return [];
        if (text === "")
            return [
                {
                    "id": "resume",
                    "title": I18n.t("Продолжить последнюю сессию", "Resume last session"),
                    "subtitle": "codex resume --last",
                    "icon": "terminal"
                },
                {
                    "id": "new",
                    "title": I18n.t("Новая сессия Codex", "New Codex session"),
                    "subtitle": I18n.t("codex в терминале", "codex in a terminal"),
                    "icon": "terminal"
                }
            ];
        const m = text.match(/^\?\s*(.*)$/);
        if (m)
            return [
                {
                    "id": "ask:" + m[1],
                    "title": m[1] ? I18n.t("Спросить Codex", "Ask Codex") : I18n.t("Спросить: codex ? вопрос", "Ask: codex ? question"),
                    "subtitle": m[1] || I18n.t("без shell, ответ уведомлением", "No shell; answer as a notification"),
                    "icon": "terminal",
                    "score": 100
                }
            ];
        return [
            {
                "id": "task:" + text,
                "title": I18n.t("Запустить Codex", "Launch Codex"),
                "subtitle": text,
                "icon": "terminal",
                "score": 100
            }
        ];
    }

    function activate(id) {
        if (id === "resume")
            CodexState.launch(["resume", "--last"]);
        else if (id === "new")
            CodexState.launch([]);
        else if (id.startsWith("ask:") && id.length > 4)
            CodexState.ask(id.slice(4));
        else if (id.startsWith("task:"))
            CodexState.launch([id.slice(5)]);
    }
}
