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
    }
    PxGroup {
        width: parent.width
        title: "Alt+Tab"
        icon: "layers"
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            text: I18n.t("Держи Alt и жми Tab — окна по порядку недавнего использования; отпусти Alt, чтобы переключиться. Shift+Tab и стрелки — назад, Esc — отмена, Delete — закрыть окно. Быстрое Alt+Tab просто прыгает на прошлое окно.", "Hold Alt and press Tab: windows in most-recently-used order; let go of Alt to switch. Shift+Tab and the arrows go back, Esc cancels, Delete closes a window. A quick Alt+Tab just jumps to the previous window.")
        }
        Grid {
            width: parent.width
            columns: Math.max(1, Math.floor(width / (Theme.u * 110)))
            spacing: Theme.u * 3
            Repeater {
                model: AltTab.styles
                PxBox {
                    id: atCard
                    required property var modelData
                    readonly property bool current: AltTab.style === modelData.id
                    width: (parent.width - (parent.columns - 1) * parent.spacing) / parent.columns
                    height: atCol.implicitHeight + Theme.u * 8
                    sunken: current
                    color: current ? Theme.mix(Theme.face, Theme.accent, 0.3) : atMouse.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.1) : Theme.face
                    Column {
                        id: atCol
                        x: Theme.u * 4
                        y: Theme.u * 4
                        width: parent.width - Theme.u * 8
                        spacing: Theme.u
                        PxText {
                            text: (atCard.current ? "♡ " : "") + atCard.modelData.label
                            font.bold: true
                        }
                        PxText {
                            width: parent.width
                            text: atCard.modelData.hint
                            kind: "tiny"
                            dim: true
                            wrapMode: Text.Wrap
                        }
                    }
                    MouseArea {
                        id: atMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Config.alttab.style = atCard.modelData.id;
                            if (atCard.modelData.id !== "niri")
                                AltTab.tryIt();
                        }
                    }
                }
            }
        }
        SettingRow {
            visible: AltTab.ours
            label: I18n.t("Какие окна", "Which windows")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Все", "All"),
                        "value": "all"
                    },
                    {
                        "label": I18n.t("Этот монитор", "This monitor"),
                        "value": "output"
                    },
                    {
                        "label": I18n.t("Этот стол", "This desk"),
                        "value": "workspace"
                    }
                ]
                currentValue: Config.alttab.scope
                onActivated: v => Config.alttab.scope = v
            }
        }
        SettingRow {
            visible: AltTab.ours
            label: I18n.t("Подписи", "Titles")
            PxToggle {
                checked: Config.alttab.titles
                onToggled: c => Config.alttab.titles = c
            }
        }
        SettingRow {
            visible: AltTab.ours
            label: I18n.t("Показывать через", "Show after")
            hint: I18n.t("пока Alt держится дольше — иначе просто переключает, без окошка", "only while Alt is held longer, otherwise it just switches")
            PxSlider {
                width: parent.width
                from: 0
                to: 500
                stepSize: 10
                suffix: I18n.t(" мс", " ms")
                value: Config.alttab.delayMs
                onReleased: v => Config.alttab.delayMs = v
            }
        }
        Row {
            spacing: Theme.u * 3
            visible: AltTab.ours
            PxButton {
                compact: true
                icon: "play"
                text: I18n.t("Показать", "Try it")
                onClicked: AltTab.tryIt()
            }
            PxText {
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.u * 200
                wrapMode: Text.Wrap
                kind: "tiny"
                color: AltTab.watcherStatus === "noperm" ? Theme.danger : Theme.textDim
                text: AltTab.watcherStatus === "noperm" ? I18n.t("нет доступа к клавиатуре (группа input): отпускание Alt ловится только самим окошком — если оно не успело открыться, выбери окно Enter или кликом", "No keyboard access (the input group): only the switcher itself sees Alt being let go — if it was not open yet, pick with Enter or a click") : AltTab.log
            }
        }
    }
    PxGroup {
        width: parent.width
        title: I18n.t("Анимации окон", "Window animations")
        icon: "sparkle"
        Component.onCompleted: WindowAnim.refresh()
        Repeater {
            model: [
                {
                    "kind": "open",
                    "label": I18n.t("Анимация открытия", "Open animation"),
                    "speed": I18n.t("Скорость открытия", "Open speed"),
                    "preview": "OpenFx"
                },
                {
                    "kind": "close",
                    "label": I18n.t("Анимация закрытия", "Close animation"),
                    "speed": I18n.t("Скорость закрытия", "Close speed"),
                    "preview": "CloseFx"
                }
            ]
            Column {
                id: animBlock
                required property var modelData
                readonly property string kind: modelData.kind
                readonly property string currentId: animBlock.kind === "open" ? WindowAnim.open : WindowAnim.close
                width: parent.width
                spacing: Theme.u * 2
                SettingRow {
                    id: animRow
                    preview: animBlock.modelData.preview
                    label: animBlock.modelData.label
                    hint: {
                        const s = WindowAnim.styleOf(animBlock.kind, animBlock.currentId);
                        return s ? s.hint : animBlock.currentId === "custom" ? I18n.t("свой шейдер в cfg/animation.kdl — выбери вариант, чтобы заменить", "A hand-written shader in cfg/animation.kdl — pick one to replace it") : "";
                    }
                    PxCombo {
                        width: parent.width
                        enabled: !WindowAnim.busy
                        model: WindowAnim.styles(animBlock.kind).map(s => ({
                                    "label": s.label,
                                    "value": s.id
                                }))
                        currentValue: animBlock.currentId
                        placeholder: animBlock.currentId === "custom" ? I18n.t("свой шейдер", "custom shader") : "—"
                        onActivated: v => {
                            WindowAnim.pick(animBlock.kind, v);
                            const s = WindowAnim.styleOf(animBlock.kind, v);
                            animRow.show(v, s ? s.label : v);
                        }
                    }
                }
                SettingRow {
                    label: animBlock.modelData.speed
                    hint: I18n.t("×2 — вдвое быстрее, ×0.5 — вдвое медленнее; niri ещё умножает всё на свой slowdown", "×2 is twice as fast, ×0.5 half as fast; niri also stretches everything by its slowdown")
                    enabled: !WindowAnim.busy && animBlock.currentId !== "off" && animBlock.currentId !== "custom" && animBlock.currentId !== ""
                    opacity: enabled ? 1 : 0.5
                    PxSlider {
                        width: parent.width
                        from: 25
                        to: 300
                        stepSize: 5
                        valueScale: 0.01
                        decimals: 2
                        suffix: "×"
                        value: Math.round((animBlock.kind === "open" ? WindowAnim.openSpeed : WindowAnim.closeSpeed) * 100)
                        onReleased: v => WindowAnim.setSpeed(animBlock.kind, v / 100)
                    }
                }
            }
        }
        Row {
            spacing: Theme.u * 3
            PxButton {
                compact: true
                icon: "play"
                text: I18n.t("На настоящем окне", "On a real window")
                onClicked: WindowAnim.preview()
            }
            PxText {
                anchors.verticalCenter: parent.verticalCenter
                text: WindowAnim.log
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
