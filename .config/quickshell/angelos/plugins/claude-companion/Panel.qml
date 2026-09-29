pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.widgets
import "."

// Tabs: last answer / sessions / ask.
Column {
    id: root

    property var plugin
    property string tab: "limits"
    spacing: Theme.u * 4

    PxSegmented {
        model: [
            {
                "label": I18n.t("Лимит", "Limits"),
                "value": "limits"
            },
            {
                "label": I18n.t("Ответ", "Answer"),
                "value": "answer"
            },
            {
                "label": I18n.t("Сессии (", "Sessions (") + Pulse.list.length + ")",
                "value": "sessions"
            },
            {
                "label": I18n.t("Спросить", "Ask"),
                "value": "ask"
            }
        ]
        currentValue: root.tab
        onActivated: v => root.tab = v
    }

    Row {
        spacing: Theme.u * 4
        Breath {
            plugin: root.plugin
            pixel: Theme.u * 2
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            PxText {
                text: "Claude " + Pulse.word
                kind: "title"
            }
            PxText {
                visible: !!Pulse.presence
                text: Pulse.presence ? "«" + Pulse.presence.message + "»" : ""
                dim: true
            }
        }
    }

    // limits
    Limits {
        visible: root.tab === "limits"
        width: parent.width
    }
    PxButton {
        visible: root.tab === "limits"
        compact: true
        text: I18n.t("Обновить", "Refresh")
        icon: "refresh"
        onClicked: Usage.refresh(true)
    }

    // answer
    PxBox {
        visible: root.tab === "answer"
        width: parent.width
        height: Theme.u * 110
        sunken: true
        color: Qt.alpha(Theme.sunken, 0.8)
        PxScroll {
            anchors.fill: parent
            anchors.margins: Theme.u * 3
            contentHeight: ans.implicitHeight
            Column {
                id: ans
                width: parent.width
                spacing: Theme.u * 3
                PxText {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: Pulse.answer ? "? " + Pulse.answer.q : I18n.t("Пока ни о чём не спрашивали. Вкладка «Спросить» или в лаунчере: claude ? вопрос", "No questions yet. Use the Ask tab or enter claude ? question in the launcher.")
                    dim: true
                }
                PxText {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: Pulse.answer ? (Pulse.answer.text || (Pulse.asking ? I18n.t("думаю…", "Thinking…") : "")) : ""
                    color: Pulse.answer && Pulse.answer.error ? Theme.danger : Theme.text
                    textFormat: Text.PlainText
                }
            }
        }
    }

    // sessions
    Column {
        visible: root.tab === "sessions"
        width: parent.width
        spacing: Theme.u * 2
        PxText {
            visible: Pulse.list.length === 0
            width: parent.width
            wrapMode: Text.Wrap
            text: I18n.t("Нет активных сессий. Запущенные claude подхватываются сами (по транскриптам), хуки в настройках дают точнее.", "No active sessions. Running Claude sessions are detected from transcripts; hooks provide more precise updates.")
            dim: true
        }
        Repeater {
            model: Pulse.list
            PxBox {
                id: card
                required property var modelData
                width: root.width
                height: Theme.u * 24
                color: Theme.faceAlt
                Row {
                    x: Theme.u * 3
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    spacing: Theme.u * 4
                    Breath {
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        state: card.modelData.state
                        plugin: root.plugin
                    }
                    Column {
                        width: root.width - Theme.u * 60
                        PxText {
                            text: (card.modelData.cwd ? card.modelData.cwd + " · " : "") + card.modelData.model + " · " + (Pulse.words[card.modelData.state] || card.modelData.state)
                            font.bold: true
                            width: parent.width
                            elide: Text.ElideRight
                        }
                        PxText {
                            text: Pulse.burn(card.modelData) || Qt.formatTime(new Date(card.modelData.at), "HH:mm:ss")
                            kind: "tiny"
                            dim: true
                        }
                    }
                    PxButton {
                        compact: true
                        icon: "trash"
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: Pulse.retire(card.modelData.id)
                    }
                }
            }
        }
    }

    // ask
    Column {
        visible: root.tab === "ask"
        width: parent.width
        spacing: Theme.u * 3
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            text: I18n.t("Быстрый вопрос без инструментов и доступа к файлам (claude -p). Ответ придёт уведомлением и появится на вкладке «Ответ».", "Ask without tools or file access (claude -p). The answer appears as a notification and on the Answer tab.")
            dim: true
        }
        PxField {
            id: q
            width: parent.width
            placeholder: I18n.t("спроси что-нибудь…", "Ask something…")
            enabled: !Pulse.asking
            onAccepted: {
                Pulse.ask(text);
                text = "";
                root.tab = "answer";
            }
        }
        Row {
            spacing: Theme.u * 3
            PxButton {
                text: Pulse.asking ? I18n.t("Думаю…", "Thinking…") : I18n.t("Спросить", "Ask")
                icon: "bot"
                accent: true
                enabled: !Pulse.asking && q.text.trim() !== ""
                onClicked: q.accepted()
            }
            PxButton {
                text: I18n.t("Терминал: продолжить", "Continue in terminal")
                icon: "terminal"
                onClicked: Pulse.launch(["--continue"], root.plugin ? root.plugin.get("mcp", true) : true)
            }
        }
    }
}
