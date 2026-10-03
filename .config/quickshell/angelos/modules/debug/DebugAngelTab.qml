pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// The angel: how cold she is (story/game.json → angel), every line of every step
// (story/angel.json), the helper's own moves and her look.
Column {
    id: root

    spacing: Theme.u * 5
    // the steps that have their own lines, in the file's order
    readonly property var steps: Object.keys(Story.angelVoice || {}).filter(k => k !== "_comment" && k !== "draft" && typeof Story.angelVoice[k] === "object")

    PxGroup {
        width: parent.width
        title: I18n.t("Холод", "The chill")
        icon: "moon"
        DebugNum {
            label: I18n.t("Холод (броски)", "Chill (throws)")
            value: Story.chill
            to: 20
            note: Story.angelStepName + I18n.t(" · ступени ", " · steps ") + JSON.stringify(Story.chillSteps)
            onMoved: v => Story.player.chill = v
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 6
            PxToggle {
                text: I18n.t("Холодный рут", "Cold route")
                checked: !!Story.player.coldRoute
                onToggled: c => {
                    Story.player.coldRoute = c;
                    Story.player.coldSince = c ? Story.now() : 0;
                }
            }
            PxToggle {
                text: I18n.t("Сцена холода уже была", "The cold scene has played")
                checked: !!Story.player.coldSeen
                onToggled: c => Story.player.coldSeen = c
            }
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 3
            PxButton {
                icon: "sun"
                text: I18n.t("Прошли сутки без бросков", "A day without a throw")
                onClicked: GameDebug.dayPassed()
            }
            PxButton {
                icon: "chat"
                enabled: !Angel.demon
                text: I18n.t("Сцена холода", "The cold scene")
                onClicked: GameDebug.note(Novel.playScene("cold") ? "cold" : I18n.t("не играется сейчас", "won't play now"))
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Её реплики по ступеням (story/angel.json)", "Her lines by step (story/angel.json)")
        icon: "chat"
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            kind: "tiny"
            text: I18n.t("Кнопка — случайная реплика этой ступени для этого случая, в пузыре у неё в углу.", "A button: a random line of that step for that situation, in her bubble in the corner.")
        }
        Repeater {
            model: root.steps
            Flow {
                id: stepRow
                required property string modelData
                width: parent.width
                spacing: Theme.u * 2
                PxText {
                    width: Theme.u * 34
                    height: Theme.sizeBody + Theme.u * 6
                    verticalAlignment: Text.AlignVCenter
                    font.bold: Story.angelStepName === stepRow.modelData
                    text: stepRow.modelData
                }
                Repeater {
                    model: Object.keys(Story.angelVoice[stepRow.modelData] || {})
                    PxButton {
                        required property string modelData
                        compact: true
                        text: modelData
                        onClicked: GameDebug.sayFrom(Story.angelVoice[stepRow.modelData][modelData], stepRow.modelData + "/" + modelData)
                    }
                }
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Помощница в углу", "The helper in the corner")
        icon: "sparkle"
        Flow {
            width: parent.width
            spacing: Theme.u * 2
            PxButton {
                compact: true
                icon: "star"
                text: I18n.t("Совет", "Tip")
                onClicked: Angel.tip()
            }
            PxButton {
                compact: true
                icon: "sparkle"
                text: I18n.t("Шутка", "Joke")
                onClicked: Angel.joke()
            }
            PxButton {
                compact: true
                icon: "chat"
                text: I18n.t("Заговорить самой", "Chatter")
                onClicked: Angel.chatter()
            }
            PxButton {
                compact: true
                icon: "info"
                text: I18n.t("Подсказка (демоница)", "Hint (the demon)")
                enabled: Angel.demon
                onClicked: Angel.hint()
            }
            PxButton {
                compact: true
                icon: "document"
                text: I18n.t("Длинная реплика", "A long line")
                onClicked: GameDebug.sayLong()
            }
            PxButton {
                compact: true
                icon: "grid"
                text: I18n.t("Её меню", "Her menu")
                onClicked: Angel.openMenu("main")
            }
            PxButton {
                compact: true
                icon: "close"
                text: I18n.t("Замолчать", "Hush")
                onClicked: Angel.hush()
            }
            PxButton {
                compact: true
                icon: "heart"
                text: I18n.t("Позвать", "Summon")
                onClicked: GameDebug.note(Angel.summon())
            }
            PxButton {
                compact: true
                icon: "moon"
                text: I18n.t("Спрятать на минуту", "Hide for a minute")
                onClicked: Angel.hiddenUntil = Date.now() + 60000
            }
            PxButton {
                compact: true
                icon: "sun"
                text: I18n.t("Показать", "Show")
                onClicked: {
                    Angel.hiddenUntil = 0;
                    Angel.now = Date.now();
                }
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Облик", "Looks")
        icon: "palette"
        SettingRow {
            label: I18n.t("Ангел", "Angel")
            PxSegmented {
                model: ["glitch", "ophanim", "chibi", "adult", "mini"].map(v => ({
                            "label": v,
                            "value": v
                        }))
                currentValue: Config.y2k.angelLook || "glitch"
                onActivated: v => Config.y2k.angelLook = v
            }
        }
        SettingRow {
            label: I18n.t("Демоница", "Demon")
            PxSegmented {
                model: ["glitch", "chibi", "adult", "mini"].map(v => ({
                            "label": v,
                            "value": v
                        }))
                currentValue: Config.y2k.demonLook || "glitch"
                onActivated: v => Config.y2k.demonLook = v
            }
        }
        DebugNum {
            label: I18n.t("Размер, %", "Size, %")
            value: Math.round((Config.y2k.helperScale || 1) * 100)
            from: 100
            to: 115
            step: 5
            onMoved: v => Config.y2k.helperScale = v / 100
        }
    }
}
