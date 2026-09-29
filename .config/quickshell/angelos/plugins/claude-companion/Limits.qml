pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.widgets
import "."

// Pixel meters for the plan limits: how much is LEFT and when it resets.
Column {
    id: root

    property bool compact: false
    spacing: Theme.u * (compact ? 2 : 4)

    readonly property var rows: [
        {
            "label": I18n.t("5 часов", "5 hours"),
            "w": Usage.five
        },
        {
            "label": I18n.t("неделя", "week"),
            "w": Usage.week
        },
        {
            "label": I18n.t("неделя Opus", "Opus week"),
            "w": Usage.weekOpus
        },
        {
            "label": I18n.t("неделя Sonnet", "Sonnet week"),
            "w": Usage.weekSonnet
        }
    ].filter(r => !!r.w)

    PxText {
        visible: !Usage.ok
        width: root.width
        wrapMode: Text.Wrap
        dim: true
        text: ({
                "idle": "…",
                "loading": I18n.t("узнаю лимиты…", "Loading limits…"),
                "expired": I18n.t("токен Claude Code истёк — он обновится при следующем запуске claude", "Claude Code token expired. It refreshes the next time you start Claude Code."),
                "auth": I18n.t("Anthropic не пустил по токену (401) — перелогинься в claude", "Token rejected (401). Sign in to Claude Code again."),
                "offline": I18n.t("нет связи с api.anthropic.com", "Cannot reach api.anthropic.com"),
                "nologin": I18n.t("не нашёл ~/.claude/.credentials.json — войди в Claude Code", "Claude Code credentials not found. Sign in to Claude Code.")
            })[Usage.status] || Usage.status
    }

    Repeater {
        model: Usage.ok ? root.rows : []
        Column {
            id: r
            required property var modelData
            readonly property color c: Usage.colorFor(modelData.w.left, Theme)
            width: root.width
            spacing: Theme.u
            Row {
                width: parent.width
                PxText {
                    width: parent.width / 2
                    text: r.modelData.label
                    dim: true
                }
                PxText {
                    width: parent.width / 2
                    horizontalAlignment: Text.AlignRight
                    text: I18n.t("осталось ", "Remaining ") + r.modelData.w.left + "%"
                    color: r.c
                    font.bold: true
                }
            }
            // blocky meter: filled blocks = what's left
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
                            color: index < Math.round(r.modelData.w.left / 5) ? r.c : "transparent"
                        }
                    }
                }
            }
            PxText {
                visible: !root.compact && !!r.modelData.w.resetsAt
                text: r.modelData.w.resetsAt ? I18n.t("сброс через ", "Resets in ") + Usage.untilText(r.modelData.w.resetsAt) + "  (" + Qt.locale(Config.appearance.language === "en" ? "en_US" : "ru_RU").toString(r.modelData.w.resetsAt, "ddd HH:mm") + ")" : ""
                kind: "tiny"
                dim: true
            }
        }
    }
    PxText {
        visible: Usage.ok && !root.compact
        text: I18n.t("план: ", "Plan: ") + (Usage.plan || "?") + I18n.t(" · обновлено ", " · updated ") + Qt.formatTime(Usage.updated, "HH:mm")
        kind: "tiny"
        dim: true
    }
}
