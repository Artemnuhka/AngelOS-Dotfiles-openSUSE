pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// The circles' demons: each one's closeness with the player (story/game.json → closeness),
// her step's scene, her lines (story/voices.json → demons), the circle's voice, and which
// demon's pictures stand in the corner (sprites/demon-<circle>/, any circle, unsaved).
Column {
    id: root

    spacing: Theme.u * 5
    readonly property var stepNames: [I18n.t("чужая", "a stranger"), I18n.t("знакомая", "acquainted"), I18n.t("близкая", "close"), I18n.t("своя", "your own")]

    PxGroup {
        width: parent.width
        title: I18n.t("Кто стоит в углу", "Who stands in the corner")
        icon: "heartHorns"
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            kind: "tiny"
            text: I18n.t("Скин демоницы любого круга, где бы ни был игрок (не сохраняется). Нарезанные: ", "Any circle's demon skin wherever the player is (not saved). Cut so far: ") + (GameDebug.skins.length ? GameDebug.skins.join(", ") : "—")
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 2
            PxButton {
                compact: true
                checked: GameDebug.skin === ""
                text: I18n.t("Как круг", "The circle's")
                onClicked: GameDebug.skin = ""
            }
            PxButton {
                compact: true
                checked: GameDebug.skin === "-"
                text: I18n.t("Без скина", "No skin")
                onClicked: GameDebug.skin = "-"
            }
            Repeater {
                model: GameDebug.skins
                PxButton {
                    required property string modelData
                    compact: true
                    checked: GameDebug.skin === modelData
                    text: Theme.roman(Story.circleN(modelData)) + " " + Story.circleName(modelData)
                    onClicked: GameDebug.skin = modelData
                }
            }
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 2
            PxButton {
                compact: true
                icon: "document"
                text: I18n.t("Длинная реплика", "A long line")
                onClicked: GameDebug.sayLong()
            }
            PxButton {
                compact: true
                icon: "chat"
                text: I18n.t("Заговорить самой", "Chatter")
                onClicked: Angel.chatter()
            }
            PxButton {
                compact: true
                icon: "refresh"
                text: I18n.t("Пересканировать", "Rescan")
                onClicked: GameDebug.rescan()
            }
        }
    }

    PxGroup {
        width: parent.width
        visible: Story.inHell
        title: I18n.t("Голос круга (story/voices.json → ", "The circle's voice (story/voices.json → ") + HellLook.voice + ")"
        icon: "chat"
        Flow {
            width: parent.width
            spacing: Theme.u * 2
            Repeater {
                model: Object.keys(Story.voices[HellLook.voice] || {})
                PxButton {
                    required property string modelData
                    compact: true
                    text: modelData
                    onClicked: GameDebug.sayFrom(Story.voices[HellLook.voice][modelData], HellLook.voice + "/" + modelData)
                }
            }
        }
    }

    Repeater {
        model: Story.order
        PxGroup {
            id: card
            required property string modelData
            readonly property int points: Story.closePoints(modelData)
            readonly property int step: Story.closeStepOf(points)
            readonly property var lines: (Story.voices.demons || {})[modelData] || {}
            width: root.width
            title: Theme.roman(Story.circleN(modelData)) + " · " + Story.circleName(modelData) + (Story.circle === modelData ? I18n.t("  ← здесь", "  ← here") : "")
            icon: "heartHorns"
            DebugNum {
                label: I18n.t("Близость", "Closeness")
                value: card.points
                to: 40
                note: root.stepNames[card.step] + " · " + JSON.stringify(Story.closeSteps)
                onMoved: v => GameDebug.setClose(card.modelData, v)
            }
            Flow {
                width: parent.width
                spacing: Theme.u * 2
                Repeater {
                    model: [1, 2, 3].filter(n => !!Novel.scenes["close-" + card.modelData + "-" + n])
                    PxButton {
                        required property int modelData
                        compact: true
                        icon: "play"
                        text: I18n.t("Сцена ступени ", "Step scene ") + modelData
                        onClicked: GameDebug.note(Novel.startScene("close-" + card.modelData + "-" + modelData) ? "close-" + card.modelData + "-" + modelData : I18n.t("не играется", "won't play"))
                    }
                }
                PxButton {
                    compact: true
                    icon: "refresh"
                    text: I18n.t("Поговорить/подарок/остаться — снова можно", "Talk/gift/stay ready again")
                    onClicked: {
                        GameDebug.closeReady(card.modelData);
                        GameDebug.note(card.modelData + ": ready");
                    }
                }
            }
            Flow {
                width: parent.width
                spacing: Theme.u * 2
                visible: Object.keys(card.lines).length > 0
                Repeater {
                    model: Object.keys(card.lines).filter(k => k !== "draft")
                    PxButton {
                        required property string modelData
                        readonly property var raw: card.lines[modelData]
                        // per step ([[…], …] for each step) or one list for all
                        readonly property var list: Array.isArray(raw) && Array.isArray(raw[0]) && Array.isArray(raw[0][0]) ? (raw[Math.min(card.step, raw.length - 1)] || []) : raw
                        compact: true
                        icon: "chat"
                        text: modelData
                        onClicked: GameDebug.sayFrom(list, card.modelData + "/" + modelData)
                    }
                }
            }
        }
    }
}
