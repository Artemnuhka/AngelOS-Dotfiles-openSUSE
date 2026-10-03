pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// The game's debug panel (services/GameDebug): a window of its own, so it stays open over
// heaven and hell while the corner, the desktop and Settings change behind it. It keeps the
// plain look in every circle — it is a tool, not part of the story. Opened from Settings →
// System (developer mode) or `angelos debug`.
FloatingWindow {
    id: root

    title: Shell.appTitle + " · " + I18n.t("Отладка игры", "Game debug")
    visible: GameDebug.shown
    color: "transparent"
    implicitWidth: 1000
    implicitHeight: 760
    minimumSize: Qt.size(760, 520)
    onClosed: GameDebug.open = false
    onVisibleChanged: if (!visible)
        GameDebug.open = false

    readonly property var tabs: [
        {
            "id": "state",
            "label": I18n.t("Состояние", "State"),
            "icon": "info",
            "page": "DebugStateTab.qml"
        },
        {
            "id": "angel",
            "label": I18n.t("Ангел", "The angel"),
            "icon": "heart",
            "page": "DebugAngelTab.qml"
        },
        {
            "id": "demons",
            "label": I18n.t("Демоницы", "The demons"),
            "icon": "heartHorns",
            "page": "DebugDemonsTab.qml"
        },
        {
            "id": "scenes",
            "label": I18n.t("Сцены", "Scenes"),
            "icon": "chat",
            "page": "DebugScenesTab.qml"
        },
        {
            "id": "fx",
            "label": I18n.t("Эффекты", "Effects"),
            "icon": "fire",
            "page": "DebugFxTab.qml"
        },
        {
            "id": "looks",
            "label": I18n.t("Облик", "Looks"),
            "icon": "palette",
            "page": "DebugLooksTab.qml"
        },
        {
            "id": "sounds",
            "label": I18n.t("Звуки", "Sounds"),
            "icon": "speaker",
            "page": "DebugSoundsTab.qml"
        },
        {
            "id": "system",
            "label": I18n.t("Система", "System"),
            "icon": "chip",
            "page": "DebugSystemTab.qml"
        }
    ]
    readonly property var current: tabs.find(t => t.id === GameDebug.tab) || tabs[0]

    PxWindow {
        id: frame
        anchors.fill: parent
        anchors.rightMargin: Theme.u * 2
        anchors.bottomMargin: Theme.u * 2
        skin: ""
        // a tool to read at a glance: no desktop showing through
        translucent: false
        title: "angelOS · " + I18n.t("Отладка игры", "Game debug")
        icon: "chip"
        onCloseClicked: GameDebug.open = false
        onTitlePressed: root.startSystemMove()

        // the panel's own look: classic in every settings skin and every circle
        Item {
            id: body
            readonly property string settingsSkin: "classic"
            width: parent.width
            height: parent.height

            // ---- what is going on, always in sight ----
            PxBox {
                id: head
                width: parent.width
                height: headRow.implicitHeight + Theme.u * 6
                sunken: true
                color: Theme.sunken
                Flow {
                    id: headRow
                    x: Theme.u * 4
                    y: Theme.u * 3
                    width: parent.width - Theme.u * 8
                    spacing: Theme.u * 4
                    PxText {
                        font.bold: true
                        text: (Story.enabled ? "" : I18n.t("ИГРА ВЫКЛЮЧЕНА · ", "GAME OFF · ")) + (Story.inHell ? I18n.t("ад", "hell") + " · " + (Story.circle ? Theme.roman(Story.circleN(Story.circle)) + " " + Story.circleName(Story.circle) : "—") : I18n.t("рай", "heaven")) + (Angel.transition ? " → " + Angel.transition : "") + " · " + I18n.t("ангел: ", "angel: ") + Story.angelStepName + " (" + Story.chill + ")" + " · " + I18n.t("падений ", "falls ") + (Story.hell.falls || 0) + " · " + I18n.t("возвращений ", "returns ") + (Story.player.returns || 0) + (GameDebug.lookOverridden ? " · " + I18n.t("облик: ", "look: ") + HellLook.circle : "") + (GameDebug.skin ? " · " + I18n.t("скин: ", "skin: ") + GameDebug.skin : "")
                    }
                    PxText {
                        visible: Novel.sceneBusy
                        color: Theme.accent
                        text: I18n.t("сцена: ", "scene: ") + Novel.sceneStatus()
                    }
                }
            }

            // ---- the tabs ----
            Column {
                id: side
                anchors.top: head.bottom
                anchors.topMargin: Theme.u * 4
                width: Theme.u * 62
                spacing: Theme.u * 2
                Repeater {
                    model: root.tabs
                    PxButton {
                        required property var modelData
                        width: side.width
                        icon: modelData.icon
                        text: modelData.label
                        checked: root.current.id === modelData.id
                        onClicked: GameDebug.tab = modelData.id
                    }
                }
                Item {
                    width: 1
                    height: Theme.u * 4
                }
                PxButton {
                    width: side.width
                    icon: "camera"
                    text: GameDebug.snapBusy === "take" ? I18n.t("Снимаю…", "Taking…") : I18n.t("Снимок", "Snapshot")
                    onClicked: GameDebug.snapshot()
                }
                PxButton {
                    width: side.width
                    icon: "arrowLeft"
                    enabled: !!GameDebug.snapInfo && !GameDebug.snapBusy
                    text: I18n.t("Вернуть снимок", "Restore it")
                    onClicked: GameDebug.restore()
                }
                PxButton {
                    width: side.width
                    icon: "power"
                    text: I18n.t("Перезапуск", "Restart")
                    onClicked: GameDebug.restart()
                }
            }

            PxScroll {
                id: scroll
                anchors.top: head.bottom
                anchors.topMargin: Theme.u * 4
                anchors.left: side.right
                anchors.leftMargin: Theme.u * 5
                anchors.right: parent.right
                anchors.bottom: status.top
                anchors.bottomMargin: Theme.u * 3
                contentHeight: page.item ? page.item.implicitHeight + Theme.u * 4 : 0
                Loader {
                    id: page
                    width: scroll.width - Theme.u * 8
                    source: root.current.page
                    onSourceChanged: scroll.contentY = 0
                }
            }

            // the last thing done
            PxText {
                id: status
                anchors.bottom: parent.bottom
                width: parent.width
                kind: "tiny"
                dim: true
                elide: Text.ElideRight
                text: GameDebug.log || I18n.t("Всё здесь меняет настоящее сохранение. Сначала «Снимок» — потом «Вернуть снимок».", "Everything here changes the real save. “Snapshot” first — then “Restore it”.")
            }
        }
    }

    RightClickGuard {}
}
