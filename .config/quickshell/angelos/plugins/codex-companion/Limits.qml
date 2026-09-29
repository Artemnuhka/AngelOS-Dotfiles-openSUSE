pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.widgets
import "."

// Remaining share of each Codex window, credits and today's tokens.
Column {
    id: root

    property bool compact: false
    spacing: Theme.u * (compact ? 2 : 4)

    readonly property var rows: [CodexState.five, CodexState.week].filter(w => !!w)

    PxText {
        visible: CodexState.status !== "ok"
        width: root.width
        wrapMode: Text.Wrap
        dim: true
        text: ({
                "idle": "…",
                "nocodex": I18n.t("Codex не найден (~/.codex). Установи codex и войди: codex login", "Codex not found (~/.codex). Install codex and run codex login"),
                "error": I18n.t("не удалось прочитать сессии Codex", "Could not read Codex sessions")
            })[CodexState.status] || ""
    }
    PxText {
        visible: CodexState.status === "ok" && !CodexState.hasLimits && !root.compact
        width: root.width
        wrapMode: Text.Wrap
        dim: true
        text: CodexState.data.auth === "apikey" ? I18n.t("Вход по API-ключу (" + (CodexState.data.provider || "openai") + "): провайдер не присылает лимиты подписки — показываю токены.", "API-key login (" + (CodexState.data.provider || "openai") + "): the provider sends no plan limits, showing tokens instead.") : I18n.t("Лимиты появятся после следующего ответа Codex.", "Limits appear after Codex's next answer.")
    }

    Repeater {
        model: CodexState.status === "ok" ? root.rows : []
        Column {
            id: r
            required property var modelData
            readonly property color c: CodexState.colorFor(modelData.left, Theme)
            width: root.width
            spacing: Theme.u
            Row {
                width: parent.width
                PxText {
                    width: parent.width / 2
                    text: CodexState.windowLabel(r.modelData.minutes)
                    dim: true
                }
                PxText {
                    width: parent.width / 2
                    horizontalAlignment: Text.AlignRight
                    text: I18n.t("осталось ", "Remaining ") + r.modelData.left + "%"
                    color: r.c
                    font.bold: true
                }
            }
            PxBox {
                width: parent.width
                height: Theme.u * (root.compact ? 6 : 8)
                sunken: true
                color: Theme.sunken
                Row {
                    anchors.fill: parent
                    spacing: Math.max(1, Theme.u / 2)
                    Repeater {
                        model: 20
                        Rectangle {
                            required property int index
                            width: root.width > 0 ? (root.width - 19 * Math.max(1, Theme.u / 2)) / 20 : 0
                            height: Theme.u * (root.compact ? 6 : 8)
                            color: index < Math.round(r.modelData.left / 5) ? r.c : "transparent"
                        }
                    }
                }
            }
            PxText {
                visible: !root.compact
                text: r.modelData.rolled ? I18n.t("окно уже сбросилось", "window has reset") : r.modelData.resetsAt ? I18n.t("сброс через ", "Resets in ") + CodexState.untilText(r.modelData.resetsAt) : ""
                kind: "tiny"
                dim: true
            }
        }
    }
    PxText {
        visible: CodexState.status === "ok" && !!CodexState.credits && CodexState.credits.has_credits
        text: CodexState.credits ? I18n.t("кредиты: ", "credits: ") + (CodexState.credits.unlimited ? "∞" : CodexState.credits.balance) : ""
        dim: true
    }
    Row {
        visible: CodexState.status === "ok"
        spacing: Theme.u * 3
        PxText {
            text: I18n.t("сегодня: ", "today: ") + CodexState.tokens(CodexState.today.total_tokens)
            font.bold: true
        }
        PxText {
            visible: !root.compact
            text: I18n.t("вх ", "in ") + CodexState.tokens(CodexState.today.input_tokens) + I18n.t(" (кэш ", " (cache ") + CodexState.tokens(CodexState.today.cached_input_tokens) + ") · " + I18n.t("вых ", "out ") + CodexState.tokens(CodexState.today.output_tokens)
            dim: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    PxText {
        visible: CodexState.status === "ok" && CodexState.hasLimits && !root.compact
        text: (CodexState.plan ? I18n.t("план: ", "plan: ") + CodexState.plan + " · " : "") + I18n.t("данные ", "data from ") + CodexState.limitsAgo
        kind: "tiny"
        dim: true
    }
}
