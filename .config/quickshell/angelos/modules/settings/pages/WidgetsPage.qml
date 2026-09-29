pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

PxPage {
    id: page

    heading: I18n.t("Виджеты", "Widgets")
    subtitle: I18n.t("Окошки на рабочем столе. Таскаются за заголовок; двойной клик по заголовку — режим правки с крестиками. Ещё их можно добавить через ПКМ → Вид.", "Little windows on the desktop. Drag them by the title; double-click the title for edit mode. You can also add them via right-click → View.")

    property string newType: DesktopWidgets.types.length ? DesktopWidgets.types[0].type : ""
    property string newScreen: Shell.focusedScreen ? Shell.focusedScreen.name : (Quickshell.screens[0] ? Quickshell.screens[0].name : "")
    readonly property var screenModel: Quickshell.screens.map(s => ({
                "label": s.name,
                "value": s.name
            }))

    PxGroup {
        title: I18n.t("Добавить", "Add")
        icon: "plus"
        width: parent.width
        Row {
            spacing: Theme.u * 3
            PxCombo {
                width: Theme.u * 100
                model: DesktopWidgets.types.map(t => ({
                            "label": t.label,
                            "value": t.type,
                            "icon": t.icon
                        }))
                currentValue: page.newType
                onActivated: v => page.newType = v
            }
            PxCombo {
                width: Theme.u * 60
                model: page.screenModel
                currentValue: page.newScreen
                onActivated: v => page.newScreen = v
            }
            PxButton {
                text: I18n.t("Добавить", "Add")
                icon: "plus"
                accent: true
                enabled: page.newType !== "" && page.newScreen !== ""
                onClicked: DesktopWidgets.add(page.newType, page.newScreen)
            }
        }
    }

    PxGroup {
        title: I18n.t("На рабочем столе", "On the desktop") + " (" + DesktopWidgets.widgets.length + ")"
        icon: "layers"
        width: parent.width

        PxText {
            visible: DesktopWidgets.widgets.length === 0
            text: I18n.t("пока пусто ♡", "nothing yet ♡")
            dim: true
        }

        Repeater {
            model: DesktopWidgets.widgets.map(w => w.uid)
            PxBox {
                id: card
                required property string modelData
                readonly property var w: DesktopWidgets.byUid(modelData)
                readonly property var info: w ? DesktopWidgets.typeInfo(w.type) : null
                readonly property var st: w && w.settings ? w.settings : ({})
                width: parent.width
                height: cardCol.implicitHeight + Theme.u * 8
                color: Theme.faceAlt

                Column {
                    id: cardCol
                    x: Theme.u * 4
                    y: Theme.u * 4
                    width: parent.width - Theme.u * 8
                    spacing: Theme.u * 3

                    Row {
                        width: parent.width
                        spacing: Theme.u * 4
                        PxIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: card.info ? card.info.icon : "heart"
                        }
                        PxText {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - Theme.u * 170
                            text: (card.info ? card.info.title : "?") + "  ·  " + (card.info ? card.info.label : "")
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        PxCombo {
                            width: Theme.u * 60
                            model: page.screenModel
                            currentValue: card.w ? card.w.screen : ""
                            onActivated: v => DesktopWidgets.setScreen(card.modelData, v)
                        }
                        PxButton {
                            compact: true
                            icon: "refresh"
                            onClicked: DesktopWidgets.resetPosition(card.modelData)
                        }
                        PxButton {
                            compact: true
                            icon: "trash"
                            danger: true
                            onClicked: DesktopWidgets.remove(card.modelData)
                        }
                    }

                    // per-type options
                    SettingRow {
                        visible: !!card.w && card.w.type === "clock"
                        label: I18n.t("Секунды", "Seconds")
                        PxToggle {
                            checked: !!card.st.seconds
                            onToggled: c => DesktopWidgets.setSetting(card.modelData, "seconds", c)
                        }
                    }
                    SettingRow {
                        visible: !!card.w && card.w.type === "cava"
                        label: I18n.t("Столбиков", "Bars")
                        PxSpin {
                            from: 8
                            to: 64
                            stepSize: 4
                            value: card.st.bars || 32
                            onMoved: v => DesktopWidgets.setSetting(card.modelData, "bars", v)
                        }
                    }
                    SettingRow {
                        visible: !!card.w && card.w.type === "cava"
                        label: I18n.t("Что слушать", "Listen to")
                        hint: I18n.t("выход, чей звук рисовать (только чтение, маршрутизация не меняется)", "which output to draw (read-only, routing is untouched)")
                        PxCombo {
                            width: parent.width
                            model: [
                                {
                                    "label": I18n.t("выход по умолчанию", "default output"),
                                    "value": ""
                                }
                            ].concat(Audio.sinks.map(n => ({
                                        "label": Audio.nodeName(n),
                                        "value": n.name
                                    })))
                            currentValue: card.st.source || ""
                            onActivated: v => DesktopWidgets.setSetting(card.modelData, "source", v)
                        }
                    }
                    PxButton {
                        visible: !!card.info && !!card.info.plugin && !!card.info.plugin.settings
                        compact: true
                        text: I18n.t("Настройки плагина", "Plugin settings")
                        icon: "gear"
                        onClicked: Shell.settingsPage = "plugin:" + card.info.plugin.id
                    }
                }
            }
        }
    }

    PxGroup {
        title: I18n.t("Поведение", "Behavior")
        icon: "gear"
        width: parent.width
        SettingRow {
            label: I18n.t("Режим правки", "Edit mode")
            hint: I18n.t("крестики на виджетах и видны скрытые", "close buttons on widgets, hidden ones shown")
            PxToggle {
                checked: DesktopWidgets.editMode
                onToggled: c => DesktopWidgets.editMode = c
            }
        }
        SettingRow {
            label: I18n.t("Прилипать к сетке", "Snap to grid")
            PxToggle {
                checked: Config.desktop.snap
                onToggled: c => Config.desktop.snap = c
            }
        }
        Row {
            spacing: Theme.u * 3
            Repeater {
                model: Quickshell.screens
                PxButton {
                    required property var modelData
                    compact: true
                    icon: "trash"
                    text: I18n.t("Убрать все с ", "Clear ") + modelData.name
                    onClicked: DesktopWidgets.removeAll(modelData.name)
                }
            }
        }
    }
}
