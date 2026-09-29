pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

PxPage {
    heading: I18n.t("Воркспейсы", "Workspaces")
    subtitle: I18n.t("Анимации при переключении: пиксельный переход обоев, NGO-попап и полоска сердечек.", "Workspace animations: pixel wallpaper transition, popup, and heart strip.")

    PxGroup {
        title: I18n.t("Анимация переключения", "Switch animation")
        icon: "layers"
        width: parent.width
        Component.onCompleted: WorkspaceAnim.refresh()
        Grid {
            width: parent.width
            columns: Math.max(1, Math.floor(width / (Theme.u * 120)))
            spacing: Theme.u * 3
            Repeater {
                model: WorkspaceAnim.styles
                PxBox {
                    id: styleCard
                    required property var modelData
                    readonly property bool current: WorkspaceAnim.current.id === modelData.id
                    width: (parent.width - (parent.columns - 1) * parent.spacing) / parent.columns
                    height: styleCol.implicitHeight + Theme.u * 8
                    sunken: current
                    color: current ? Theme.mix(Theme.face, Theme.accent, 0.3) : styleMouse.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.1) : Theme.face
                    Column {
                        id: styleCol
                        x: Theme.u * 4
                        y: Theme.u * 4
                        width: parent.width - Theme.u * 8
                        spacing: Theme.u
                        PxText {
                            text: (styleCard.current ? "♡ " : "") + styleCard.modelData.label
                            font.bold: true
                        }
                        PxText {
                            width: parent.width
                            text: styleCard.modelData.hint
                            kind: "tiny"
                            dim: true
                            wrapMode: Text.Wrap
                        }
                    }
                    MouseArea {
                        id: styleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !WorkspaceAnim.busy
                        onClicked: WorkspaceAnim.pick(styleCard.modelData.id)
                    }
                }
            }
        }
        Row {
            spacing: Theme.u * 4
            PxButton {
                text: I18n.t("Показать", "Try it")
                icon: "sparkle"
                onClicked: {
                    const ws = Niri.activeWorkspace(Niri.focusedOutput);
                    if (ws)
                        Niri.workspaceActivated(ws, false);
                }
            }
            PxText {
                anchors.verticalCenter: parent.verticalCenter
                text: WorkspaceAnim.log
                visible: text !== ""
                color: Theme.danger
            }
        }
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            text: I18n.t("Мягкий, слайд и подпрыг — пружина niri (cfg/animation.kdl, с бэкапом и проверкой). Остальные переключают мгновенно и прячут склейку под эффектом angelOS. В полноэкранных играх game-mode всё равно выключает анимации.", "Soft, slide and bounce are niri springs (cfg/animation.kdl, backed up and validated). The others switch instantly and hide the cut under an angelOS effect. Game mode still turns animations off for fullscreen games.")
        }
    }

    PxGroup {
        title: I18n.t("Смена воркспейса", "Workspace switching")
        icon: "sparkle"
        width: parent.width
        SettingRow {
            label: I18n.t("Показывать", "Show")
            hint: I18n.t("«в панели» — имя мигает рядом с сердечками и не закрывает окна", "In the bar: the name flashes beside the hearts without covering windows")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("В панели", "In the bar"),
                        "value": "bar"
                    },
                    {
                        "label": I18n.t("Окошком", "Popup window"),
                        "value": "window"
                    },
                    {
                        "label": I18n.t("Нет", "None"),
                        "value": "off"
                    }
                ]
                currentValue: Config.workspaces.popupMode
                onActivated: v => Config.workspaces.popupMode = v
            }
        }
        SettingRow {
            visible: Config.workspaces.popupMode === "window"
            label: I18n.t("Где окошко", "Popup position")
            PxPositionPicker {
                value: Config.workspaces.popupPosition
                onPicked: v => Config.workspaces.popupPosition = v
            }
        }
        SettingRow {
            visible: Config.workspaces.popupMode === "window"
            label: I18n.t("Милые фразы", "Cute phrases")
            PxToggle {
                checked: Config.workspaces.phrases
                onToggled: c => Config.workspaces.phrases = c
            }
        }
        SettingRow {
            label: I18n.t("Полоска сердечек справа", "Heart strip on the right")
            PxToggle {
                checked: Config.workspaces.indicator
                onToggled: c => Config.workspaces.indicator = c
            }
        }
        SettingRow {
            label: I18n.t("Сколько висит", "Display duration")
            PxSlider {
                width: parent.width
                from: 250
                to: 2000
                stepSize: 50
                value: Config.workspaces.popupMs
                suffix: I18n.t(" мс", " ms")
                onMoved: v => Config.workspaces.popupMs = v
            }
        }
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            text: I18n.t("Смена фокуса между мониторами больше ничего не показывает — только настоящее переключение воркспейса.", "Animations play when switching workspaces, not when moving focus between monitors.")
            dim: true
        }
    }

    PxGroup {
        title: I18n.t("Имена", "Names")
        icon: "heart"
        width: parent.width
        PxText {
            width: parent.width
            text: I18n.t("Имя показывается в попапе. Пусто = имя из niri или «workspace N».", "The popup shows this name. Leave empty to use the niri name or workspace number.")
            dim: true
            wrapMode: Text.Wrap
        }
        Repeater {
            model: Niri.workspaces.filter(w => w.name !== "privacy")
            SettingRow {
                id: r
                required property var modelData
                readonly property string key: modelData.output + ":" + modelData.idx
                label: modelData.output + " · #" + modelData.idx + (modelData.is_active ? "  ♡" : "")
                PxField {
                    width: Theme.u * 110
                    placeholder: r.modelData.name || ("workspace " + r.modelData.idx)
                    text: (Config.workspaces.names || {})[r.key] || ""
                    onEdited: Config.setIn(Config.workspaces, "names", r.key, text)
                }
            }
        }
    }
}
