pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// Every scene of story/scenes, grouped by what starts it (its event's trigger), played at
// once whatever its condition says; the outcomes; the scene that is running.
Column {
    id: root

    spacing: Theme.u * 5
    // {trigger: [{id, title, cond}]} from the scenes' event nodes
    readonly property var byTrigger: {
        const out = {};
        for (const id of Object.keys(Novel.scenes).sort()) {
            const sc = Novel.scenes[id] || {};
            const ev = (sc.nodes || {})[sc.start] || {};
            const t = ev.type === "event" && ev.trigger ? ev.trigger : "—";
            (out[t] = out[t] || []).push({
                "id": id,
                "title": sc.title ? I18n.label(sc.title) : id,
                "cond": ev.cond || ""
            });
        }
        return out;
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Идёт сейчас", "Running now")
        icon: "play"
        PxText {
            width: parent.width
            kind: "tiny"
            wrapMode: Text.WrapAnywhere
            text: Novel.sceneBusy ? Novel.sceneStatus() : I18n.t("ничего", "nothing")
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 2
            PxButton {
                compact: true
                icon: "close"
                enabled: Novel.sceneBusy
                text: I18n.t("Остановить", "Stop")
                onClicked: Novel.stopScene()
            }
            PxButton {
                compact: true
                icon: "refresh"
                enabled: Novel.sceneBusy
                text: I18n.t("Показать снова", "Show again")
                onClicked: Novel.resumeScene()
            }
            PxButton {
                compact: true
                icon: "refresh"
                text: I18n.t("Перечитать сцены", "Reload scenes")
                onClicked: Novel.reload()
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Исходы", "Outcomes")
        icon: "star"
        Flow {
            width: parent.width
            spacing: Theme.u * 2
            Repeater {
                model: ["stars", "pact", "limbo", "amnesty"]
                PxButton {
                    required property string modelData
                    compact: true
                    enabled: Story.inHell && !Angel.transition
                    text: modelData
                    onClicked: GameDebug.note(modelData + ": " + Story.outcome(modelData))
                }
            }
        }
    }

    Repeater {
        model: Object.keys(root.byTrigger).sort()
        PxGroup {
            id: group
            required property string modelData
            width: root.width
            title: I18n.t("Событие: ", "Event: ") + modelData + "  (" + root.byTrigger[modelData].length + ")"
            icon: "chat"
            Repeater {
                model: root.byTrigger[group.modelData]
                Row {
                    id: sceneRow
                    required property var modelData
                    width: group.width - Theme.pad * 2
                    spacing: Theme.u * 3
                    PxButton {
                        id: playBtn
                        compact: true
                        icon: "play"
                        text: sceneRow.modelData.id
                        onClicked: GameDebug.note(Novel.startScene(sceneRow.modelData.id) ? sceneRow.modelData.id : I18n.t("не играется сейчас: ", "won't play now: ") + sceneRow.modelData.id)
                    }
                    PxText {
                        width: sceneRow.width - playBtn.width - Theme.u * 3
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        dim: true
                        text: sceneRow.modelData.title + (sceneRow.modelData.cond ? "  ·  " + sceneRow.modelData.cond : "")
                    }
                }
            }
        }
    }
}
