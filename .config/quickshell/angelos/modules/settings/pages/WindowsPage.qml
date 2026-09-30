import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

PxPage {
    id: page
    readonly property var openApps: {
        const seen = {};
        for (const w of Niri.windows)
            if (w.app_id && !seen[w.app_id])
                seen[w.app_id] = w;
        return Object.keys(seen).sort().map(k => seen[k]);
    }
    property string customPreset: ""

    heading: I18n.t("Поведение окон", "Window behavior")
    subtitle: I18n.t("niri располагает окна в прокручиваемых колонках. Изменения сохраняются с бэкапом и проверкой.", "niri arranges windows in scrolling columns. Changes are backed up and validated.")
    PxGroup {
        width: parent.width
        title: I18n.t("Закрытие окон", "Closing windows")
        icon: "close"
        SettingRow {
            id: rightRow
            preview: "TaskClose"
            label: I18n.t("ПКМ по кнопке окна на панели", "Right-click a window button")
            hint: ({
                    "menu": I18n.t("меню: во весь экран, плавающее, на другой стол или монитор, закрыть, завершить процесс", "A menu: fullscreen, floating, another desk or monitor, close, end task"),
                    "close": I18n.t("закрывает окно сразу, без вопросов", "Closes the window at once"),
                    "none": I18n.t("ничего не делает", "Does nothing")
                })[Config.bar.taskRightClick] || ""
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Меню", "Menu"),
                        "value": "menu"
                    },
                    {
                        "label": I18n.t("Закрыть", "Close"),
                        "value": "close"
                    },
                    {
                        "label": I18n.t("Ничего", "Nothing"),
                        "value": "none"
                    }
                ]
                currentValue: Config.bar.taskRightClick || "menu"
                onActivated: v => {
                    Config.bar.taskRightClick = v;
                    rightRow.show(v, ({
                            "menu": I18n.t("меню", "menu"),
                            "close": I18n.t("закрыть сразу", "close at once"),
                            "none": I18n.t("ничего", "nothing")
                        })[v]);
                }
            }
        }
        SettingRow {
            id: middleRow
            preview: "TaskClose"
            label: I18n.t("Средняя кнопка закрывает", "Middle click closes")
            hint: I18n.t("колёсиком по кнопке окна на панели, как в браузере по вкладке", "Click the wheel on a window button, like on a browser tab")
            PxToggle {
                checked: Config.bar.taskMiddleClose
                onToggled: c => {
                    Config.bar.taskMiddleClose = c;
                    middleRow.show(c ? "middle-on" : "middle-off", c ? I18n.t("закрывает", "closes") : I18n.t("не закрывает", "does not close"));
                }
            }
        }
        SettingRow {
            id: hoverRow
            preview: "TaskClose"
            label: I18n.t("Крестик при наведении", "× on hover")
            hint: I18n.t("на кнопке окна под курсором появляется крестик", "A close button appears on the hovered window button")
            PxToggle {
                checked: Config.bar.taskHoverClose
                onToggled: c => {
                    Config.bar.taskHoverClose = c;
                    hoverRow.show(c ? "hover-on" : "hover-off", c ? I18n.t("крестик есть", "with ×") : I18n.t("без крестика", "no ×"));
                }
            }
        }
        SettingRow {
            id: animRow
            preview: "CloseFx"
            label: I18n.t("Анимация закрытия", "Close animation")
            hint: {
                const s = CloseAnim.styles.find(x => x.id === CloseAnim.current);
                return s ? s.hint : CloseAnim.current === "custom" ? I18n.t("свой шейдер в cfg/animation.kdl — выбери вариант, чтобы заменить", "A hand-written shader in cfg/animation.kdl — pick one to replace it") : "";
            }
            PxCombo {
                width: parent.width
                enabled: !CloseAnim.busy
                model: CloseAnim.styles.map(s => ({
                            "label": s.label,
                            "value": s.id
                        }))
                currentValue: CloseAnim.current
                placeholder: CloseAnim.current === "custom" ? I18n.t("свой шейдер", "custom shader") : "—"
                onActivated: v => {
                    CloseAnim.pick(v);
                    const s = CloseAnim.styles.find(x => x.id === v);
                    animRow.show(v, s ? s.label : v);
                }
            }
        }
        Row {
            spacing: Theme.u * 3
            PxButton {
                compact: true
                icon: "play"
                text: I18n.t("На настоящем окне", "On a real window")
                onClicked: CloseAnim.preview()
            }
            PxText {
                anchors.verticalCenter: parent.verticalCenter
                text: CloseAnim.log
                kind: "tiny"
                dim: true
                width: Theme.u * 200
                elide: Text.ElideMiddle
            }
        }
    }
    PxGroup {
        width: parent.width
        title: I18n.t("Размещение", "Layout")
        advanced: true
        icon: "window"
        enabled: !WindowConfig.busy
        SettingRow {
            label: I18n.t("Центрировать активную колонку", "Center the focused column")
            PxCombo {
                model: [
                    {
                        label: I18n.t("Никогда", "Never"),
                        value: "never"
                    },
                    {
                        label: I18n.t("Всегда", "Always"),
                        value: "always"
                    },
                    {
                        label: I18n.t("При переполнении", "On overflow"),
                        value: "on-overflow"
                    }
                ]
                currentValue: WindowConfig.center
                onActivated: v => WindowConfig.save({
                        center: v
                    })
            }
        }
        SettingRow {
            label: I18n.t("Отступ между окнами", "Window gap")
            PxSlider {
                width: parent.width
                from: 0
                to: 64
                stepSize: 1
                value: WindowConfig.gaps
                suffix: " px"
                onReleased: v => WindowConfig.save({
                        gaps: v
                    })
            }
        }
        SettingRow {
            label: I18n.t("Фокус следует за мышью", "Focus follows the mouse")
            PxToggle {
                checked: InputConfig.focusFollowsMouse
                onToggled: c => InputConfig.save({
                        focusFollowsMouse: c
                    })
            }
        }
    }
    PxGroup {
        width: parent.width
        title: I18n.t("Ширина окон", "Window widths")
        advanced: true
        icon: "layers"
        enabled: !WindowConfig.busy

        SettingRow {
            label: I18n.t("Новые окна", "New windows")
            hint: I18n.t("ширина колонки при открытии", "column width when a window opens")
            Flow {
                width: parent.width
                spacing: Theme.u * 2
                Repeater {
                    model: WindowConfig.choices
                    PxButton {
                        required property var modelData
                        compact: true
                        text: modelData.label
                        checked: WindowConfig.defaultWidth === modelData.value
                        onClicked: WindowConfig.save({
                            "defaultWidth": modelData.value
                        })
                    }
                }
                PxField {
                    width: Theme.u * 40
                    placeholder: "px"
                    onAccepted: if (parseInt(text) > 100)
                        WindowConfig.save({
                            "defaultWidth": "fixed " + parseInt(text)
                        })
                }
            }
        }
        SettingRow {
            label: I18n.t("Пресеты Mod+R", "Mod+R presets")
            hint: I18n.t("по ним переключается ширина колонки; ✕ — убрать", "Mod+R cycles through these; ✕ removes one")
            Flow {
                width: parent.width
                spacing: Theme.u * 2
                Repeater {
                    model: WindowConfig.presets
                    PxButton {
                        required property string modelData
                        required property int index
                        compact: true
                        text: WindowConfig.label(modelData) + "  ✕"
                        enabled: WindowConfig.presets.length > 1
                        onClicked: WindowConfig.save({
                            "presets": WindowConfig.presets.filter((p, i) => i !== index)
                        })
                    }
                }
                PxCombo {
                    width: Theme.u * 60
                    placeholder: I18n.t("+ добавить", "+ add")
                    model: WindowConfig.choices.filter(c => !WindowConfig.presets.includes(c.value))
                    onActivated: v => {
                        const order = w => w.startsWith("fixed") ? 10 + parseFloat(w.split(" ")[1]) / 10000 : parseFloat(w.split(" ")[1]);
                        WindowConfig.save({
                            "presets": WindowConfig.presets.concat([v]).sort((a, b) => order(a) - order(b))
                        });
                    }
                }
            }
        }

        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            text: I18n.t("Открытые приложения — своя ширина для каждого. Применяется сразу к открытым окнам и запоминается для новых.", "Open apps — a width of their own. Applies to open windows right away and is remembered for new ones.")
            dim: true
        }
        Repeater {
            model: page.openApps
            SettingRow {
                id: appRow
                required property var modelData
                readonly property string appId: modelData.app_id
                label: DesktopEntries.heuristicLookup(appId) ? DesktopEntries.heuristicLookup(appId).name : appId
                hint: appId
                Row {
                    spacing: Theme.u * 3
                    AppIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        appId: appRow.appId
                        size: Theme.u * 10
                    }
                    PxCombo {
                        width: Theme.u * 80
                        model: [
                            {
                                "label": I18n.t("по умолчанию", "default"),
                                "value": ""
                            }
                        ].concat(WindowConfig.choices)
                        currentValue: WindowConfig.apps[appRow.appId] || ""
                        onActivated: v => WindowConfig.setAppWidth(appRow.appId, v)
                    }
                    PxField {
                        width: Theme.u * 34
                        placeholder: "px"
                        onAccepted: if (parseInt(text) > 100)
                            WindowConfig.setAppWidth(appRow.appId, "fixed " + parseInt(text))
                    }
                }
            }
        }
    }

    PxText {
        width: parent.width
        wrapMode: Text.Wrap
        text: WindowConfig.log
        dim: true
    }
}
