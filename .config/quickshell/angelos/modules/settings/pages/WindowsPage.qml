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
        title: I18n.t("Размещение", "Layout")
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
