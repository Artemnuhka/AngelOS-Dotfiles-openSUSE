pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// The save as it stands, and every number of it changeable: where the player is, the
// circle, the sins, the tries, the way out. Writes go straight into the save (Story).
Column {
    id: root

    spacing: Theme.u * 5
    property string circle: Story.circle || Story.order[0]

    PxGroup {
        width: parent.width
        title: I18n.t("Рай и ад", "Heaven and hell")
        icon: "fire"
        Flow {
            width: parent.width
            spacing: Theme.u * 3
            PxButton {
                icon: "fire"
                enabled: !Angel.demon && !Angel.transition
                text: I18n.t("В ад сразу", "To hell at once")
                onClicked: GameDebug.toHellNow(root.circle)
            }
            PxButton {
                icon: "sparkle"
                enabled: Angel.demon && !Angel.transition
                text: I18n.t("В рай сразу", "To heaven at once")
                onClicked: GameDebug.toHeavenNow()
            }
            PxButton {
                icon: "arrowDown"
                enabled: !Angel.demon && !Angel.transition
                text: I18n.t("Сбросить ангела (как в игре)", "Throw her down (as in the game)")
                onClicked: {
                    Story._jumpTo = root.circle;
                    Angel.released(true, 0, 0, true);
                    GameDebug.note(I18n.t("бросок: throw.fling", "a throw: throw.fling"));
                }
            }
            PxButton {
                icon: "star"
                enabled: Angel.demon && !Angel.transition
                text: I18n.t("К звёздам (как в игре)", "To the stars (as in the game)")
                onClicked: Story.outcome("stars")
            }
        }
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            kind: "tiny"
            text: I18n.t("«Сразу» — без падения, заставки, тряски и звука; возвращение считается, как в игре. «Как в игре» — с действием из game.json (холод, грехи) и всем показом.", "“At once”: no fall, splash, quake or sound; the comeback counts as in the game. “As in the game”: the action from game.json (chill, sins) and the whole show.")
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Круг", "Circle")
        icon: "pentagram"
        Flow {
            width: parent.width
            spacing: Theme.u * 3
            PxCombo {
                width: Theme.u * 90
                model: Story.order.map(id => ({
                            "label": Theme.roman(Story.circleN(id)) + " · " + Story.circleName(id),
                            "value": id
                        }))
                currentValue: root.circle
                onActivated: v => root.circle = v
            }
            PxButton {
                icon: "play"
                text: I18n.t("Войти (с переходом)", "Enter (with the show)")
                onClicked: GameDebug.note(Story.jump(root.circle))
            }
            PxButton {
                icon: "next"
                text: I18n.t("Сразу", "At once")
                onClicked: GameDebug.circleNow(root.circle)
            }
            PxButton {
                icon: "arrowDown"
                enabled: Story.inHell
                text: I18n.t("Глубже", "Deeper")
                onClicked: Story.deeper()
            }
        }
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            kind: "tiny"
            dim: true
            text: I18n.t("путь: ", "path: ") + JSON.stringify(Story.hell.path || []) + "   " + I18n.t("начинали в: ", "falls began in: ") + JSON.stringify(Story.hell.fallCircles || []) + "   " + I18n.t("следующее падение: ", "next fall: ") + Story.circleForFall()
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Грехи", "Sins")
        icon: "skull"
        Grid {
            width: parent.width
            columns: width > Theme.u * 300 ? 2 : 1
            columnSpacing: Theme.u * 10
            rowSpacing: Theme.u * 2
            Repeater {
                model: Story.order
                DebugNum {
                    required property string modelData
                    label: Theme.roman(Story.circleN(modelData)) + " " + Story.circleName(modelData)
                    value: Number(Story.vars[modelData]) || 0
                    onMoved: v => GameDebug.setSin(modelData, v)
                }
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Попытки и путь наружу", "Tries and the way out")
        icon: "heart"
        Grid {
            width: parent.width
            columns: width > Theme.u * 300 ? 2 : 1
            columnSpacing: Theme.u * 10
            rowSpacing: Theme.u * 2
            DebugNum {
                label: I18n.t("Попытки в круге", "Tries in the circle")
                value: Story.hell.attempts || 0
                note: I18n.t("договор с ", "the pact from ") + Story.pactAfter
                onMoved: v => Story.hell.attempts = v
            }
            DebugNum {
                label: I18n.t("Молчания", "Silences")
                value: Story.hell.silences || 0
                note: I18n.t("лимб с ", "limbo from ") + Story.limboAfter
                onMoved: v => Story.hell.silences = v
            }
            DebugNum {
                label: I18n.t("Падения", "Falls")
                value: Story.hell.falls || 0
                onMoved: v => Story.hell.falls = v
            }
            DebugNum {
                label: I18n.t("Возвращения", "Returns")
                value: Story.player.returns || 0
                note: Angel.portalOpen ? I18n.t("портал открыт", "portal open") : ""
                onMoved: v => Story.player.returns = v
            }
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 3
            PxButton {
                icon: "refresh"
                text: I18n.t("Попытка — сейчас", "A try now")
                onClicked: {
                    Story.player.lastPlea = 0;
                    GameDebug.note(I18n.t("следующая попытка — сейчас", "the next try: now"));
                }
            }
            PxButton {
                icon: "play"
                enabled: Story.inHell
                text: I18n.t("Попытка выхода", "Try to get out")
                onClicked: GameDebug.note(Story.attempt(true))
            }
            PxButton {
                icon: "document"
                text: I18n.t("Договор на бумаге", "The pact on paper")
                onClicked: Angel.showContract()
            }
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 6
            PxToggle {
                text: I18n.t("Договор подписан", "Pact signed")
                checked: !!Story.hell.pact
                onToggled: c => Story.hell.pact = c
            }
            PxToggle {
                text: I18n.t("Лимб", "Limbo")
                checked: !!Story.hell.limbo
                onToggled: c => {
                    Story.hell.limbo = c;
                    Story.hell.limboSince = c ? Story.now() : 0;
                }
            }
            PxToggle {
                text: I18n.t("Амнистия при запуске", "Amnesty at start")
                checked: !!Story.hell.amnesty
                onToggled: c => Story.hell.amnesty = c
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Действия игры (game.json → actions)", "The game's actions (game.json → actions)")
        icon: "grid"
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            kind: "tiny"
            text: I18n.t("Как если бы игрок это сделал: грехи, холод, близость — по правилам (ограничения «every» и «realm» в силе).", "As if the player did it: the sins, the chill, the closeness by the rules (“every” and “realm” still apply).")
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 2
            Repeater {
                model: Object.keys(Story.rules.actions || {})
                PxButton {
                    required property string modelData
                    compact: true
                    text: modelData
                    onClicked: {
                        // the demon's own three go through her menu (closeness, her line, the step's scene)
                        if (modelData.startsWith("demon.")) {
                            Angel.demonDo(modelData.slice(6));
                            GameDebug.note(modelData);
                        } else {
                            GameDebug.note(modelData + ": " + (Story.act(modelData) ? "ok" : I18n.t("не сейчас", "not now")));
                        }
                    }
                }
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Сохранение целиком", "The whole save")
        icon: "document"
        PxText {
            id: whole
            width: parent.width
            kind: "tiny"
            dim: true
            wrapMode: Text.WrapAnywhere
            text: Story.status()
            Timer {
                interval: 1000
                repeat: true
                running: whole.visible
                onTriggered: whole.text = Story.status()
            }
        }
    }
}
