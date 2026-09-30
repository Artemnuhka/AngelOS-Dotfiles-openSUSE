pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets
import qs.modules.workspace

PxPage {
    heading: I18n.t("Воркспейсы", "Workspaces")
    subtitle: I18n.t("Анимации при переключении: сердечки на панели, переход между столами, NGO-попап и полоска сердечек.", "Switching animations: the hearts on the bar, the transition between desks, the popup and the heart strip.")

    PxGroup {
        id: heartsGroup
        title: I18n.t("Анимация сердечек", "Heart animation")
        icon: "heart"
        width: parent.width
        readonly property var heartStyles: [
            {
                "id": "smart",
                "label": I18n.t("Умная", "Smart"),
                "hint": I18n.t("соседний — столкновение, далеко — телепорт эндермена", "next door: collide, far away: enderman teleport")
            },
            {
                "id": "collide",
                "label": I18n.t("Столкновение", "Collide"),
                "hint": I18n.t("медленно, рывок — и стычок с соседним", "slow, a rush, and a knock into the next one")
            },
            {
                "id": "ender",
                "label": I18n.t("Эндермен", "Enderman"),
                "hint": I18n.t("фиолетовые частицы, телепорт", "purple particles, teleport")
            },
            {
                "id": "hop",
                "label": I18n.t("Прыжок", "Hop"),
                "hint": I18n.t("перепрыгивает дугой", "jumps over in an arc")
            },
            {
                "id": "worm",
                "label": I18n.t("Червячок", "Worm"),
                "hint": I18n.t("тянется следом", "stretches along")
            },
            {
                "id": "pixel",
                "label": I18n.t("Пиксели", "Pixels"),
                "hint": I18n.t("рассыпается и собирается", "falls apart and rebuilds")
            },
            {
                "id": "beat",
                "label": I18n.t("Сердцебиение", "Heartbeat"),
                "hint": I18n.t("тук-тук и волна", "lub-dub and a ripple")
            },
            {
                "id": "sparkle",
                "label": I18n.t("Звёздочки", "Sparkles"),
                "hint": I18n.t("комета и звёздный взрыв", "a comet and a starburst")
            },
            {
                "id": "drop",
                "label": I18n.t("Падение", "Drop"),
                "hint": I18n.t("падает сверху и пружинит", "falls from above and bounces")
            },
            {
                "id": "glitch",
                "label": I18n.t("Глитч", "Glitch"),
                "hint": I18n.t("RGB-помехи", "RGB interference")
            },
            {
                "id": "slide",
                "label": I18n.t("Скольжение", "Slide"),
                "hint": I18n.t("просто и аккуратно", "simple and tidy")
            },
            {
                "id": "off",
                "label": I18n.t("Без анимации", "Off"),
                "hint": I18n.t("сразу", "instant")
            }
        ]

        // live preview: six hearts on a strip
        PxBox {
            width: parent.width
            height: Theme.u * 30
            sunken: true
            color: Theme.sunken
            Row {
                id: previewRow
                anchors.centerIn: parent
                spacing: Theme.u * 2
                property int active: 0
                Repeater {
                    id: previewCells
                    model: 6
                    Item {
                        id: pc
                        required property int index
                        readonly property bool lit: previewRow.active === index && previewAnim.hiddenIndex !== index
                        width: Theme.u * 13
                        height: Theme.u * 13
                        PxIcon {
                            anchors.centerIn: parent
                            name: "heart"
                            hollow: !pc.lit && pc.index > 3
                            fill: pc.lit ? Theme.accent : Theme.accent4
                            scale: pc.lit ? 1 : 0.8
                        }
                    }
                }
            }
            Connections {
                target: Shell
                function onHeartDemo(from, to) {
                    if (from < 0 || to < 0 || from > 5 || to > 5)
                        return;
                    previewRow.active = to;
                    previewAnim.play(from, to);
                }
            }
            WsAnimator {
                id: previewAnim
                x: previewRow.x
                y: previewRow.y
                width: previewRow.width
                height: previewRow.height
                style: Config.workspaces.heartAnim
                cellRect: i => {
                    const c = previewCells.itemAt(i);
                    return c ? c.mapToItem(previewAnim, 0, 0, c.width, c.height) : Qt.rect(0, 0, 0, 0);
                }
            }
        }
        Row {
            spacing: Theme.u * 3
            PxButton {
                icon: "arrowRight"
                text: I18n.t("На соседний", "Next door")
                onClicked: {
                    const from = previewRow.active, to = (from + 1) % 6;
                    previewRow.active = to;
                    previewAnim.play(from, to);
                }
            }
            PxButton {
                icon: "sparkle"
                text: I18n.t("С первого на последний", "First to last")
                onClicked: {
                    const from = previewRow.active === 5 ? 5 : 0, to = from === 5 ? 0 : 5;
                    previewRow.active = to;
                    previewAnim.play(from, to);
                }
            }
        }
        Grid {
            width: parent.width
            columns: Math.max(1, Math.floor(width / (Theme.u * 100)))
            spacing: Theme.u * 3
            Repeater {
                model: heartsGroup.heartStyles
                PxBox {
                    id: hsCard
                    required property var modelData
                    readonly property bool current: (Config.workspaces.heartAnim || "smart") === modelData.id
                    width: (parent.width - (parent.columns - 1) * parent.spacing) / parent.columns
                    height: hsCol.implicitHeight + Theme.u * 8
                    sunken: current
                    color: current ? Theme.mix(Theme.face, Theme.accent, 0.3) : hsMouse.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.1) : Theme.face
                    Column {
                        id: hsCol
                        x: Theme.u * 4
                        y: Theme.u * 4
                        width: parent.width - Theme.u * 8
                        spacing: Theme.u
                        PxText {
                            text: (hsCard.current ? "♡ " : "") + hsCard.modelData.label
                            font.bold: true
                        }
                        PxText {
                            width: parent.width
                            text: hsCard.modelData.hint
                            kind: "tiny"
                            dim: true
                            wrapMode: Text.Wrap
                        }
                    }
                    MouseArea {
                        id: hsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Config.workspaces.heartAnim = hsCard.modelData.id;
                            // show it right away
                            const from = previewRow.active, to = hsCard.modelData.id === "ender" ? (from === 5 ? 0 : 5) : (from + 1) % 6;
                            previewRow.active = to;
                            Qt.callLater(() => previewAnim.play(from, to));
                        }
                    }
                }
            }
        }
    }

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
                enabled: WorkspaceAnim.captured
                // the effect over the current screen, without switching
                onClicked: WorkspaceAnim.preview(Niri.focusedOutput)
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
            text: I18n.t("«Мягкий» и «Рывок» — анимация самого niri по кривой Безье (cfg/animation.kdl, с бэкапом и проверкой), попробуй Mod+1…9. «Пиксели», «Сердечко» и «Телепорт» — angelOS снимает экран, niri переключает мгновенно, а старый стол уходит эффектом: для них клавиши Mod+1…9, Mod+колесо и Mod+O идут через angelOS (если оболочка не запущена — напрямую в niri). Переключения мышью в обзоре остаются мгновенными. В полноэкранных играх game-mode всё равно выключает анимации.", "Soft and Dash are niri's own animation on a bezier curve (cfg/animation.kdl, backed up and validated) — try Mod+1…9. Pixels, Heart and Teleport: angelOS grabs the screen, niri switches instantly and the old desk leaves with an effect; for them Mod+1…9, Mod+wheel and Mod+O go through angelOS (straight to niri if the shell is not running). Switching with the mouse in the overview stays instant. Game mode still turns animations off for fullscreen games.")
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
