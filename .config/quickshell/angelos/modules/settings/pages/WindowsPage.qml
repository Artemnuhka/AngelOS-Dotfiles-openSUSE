import QtQuick
import qs.config
import qs.services
import qs.widgets

PxPage {
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
    PxText {
        width: parent.width
        wrapMode: Text.Wrap
        text: WindowConfig.log
        dim: true
    }
}
