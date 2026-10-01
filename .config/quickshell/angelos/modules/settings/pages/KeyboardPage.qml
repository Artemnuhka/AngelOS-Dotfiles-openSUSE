pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

PxPage {
    id: page

    heading: I18n.t("Клавиатура и мышь", "Keyboard and mouse")
    subtitle: I18n.t("Пишется в ~/.config/niri/cfg/input.kdl точечно (комментарии остаются), с бэкапом и проверкой.", "Updates input.kdl, preserving comments, with a backup and validation.")

    readonly property var layoutList: InputConfig.layouts.split(",").filter(l => l)
    readonly property var optionList: InputConfig.options.split(",").filter(o => o)
    readonly property string switchOption: optionList.find(o => o.startsWith("grp:")) || ""

    function setOptions(list) {
        InputConfig.save({
            "options": list.filter(o => o).join(",")
        });
    }

    PxGroup {
        title: I18n.t("Раскладки", "Keyboard layouts")
        icon: "keyboard"
        width: parent.width

        SettingRow {
            label: I18n.t("Сейчас", "Current")
            PxText {
                text: Niri.layoutName + "  (" + Niri.layoutShort + ")"
                kind: "title"
            }
        }
        SettingRow {
            label: I18n.t("Раскладки", "Keyboard layouts")
            hint: I18n.t("порядок = порядок переключения", "Order determines the switching sequence")
            Flow {
                width: parent.width
                spacing: Theme.u * 3
                Repeater {
                    model: page.layoutList
                    PxButton {
                        required property string modelData
                        required property int index
                        compact: true
                        text: modelData + "  ✕"
                        enabled: page.layoutList.length > 1
                        onClicked: InputConfig.save({
                            "layouts": page.layoutList.filter((l, i) => i !== index).join(",")
                        })
                    }
                }
                PxCombo {
                    width: Theme.u * 60
                    placeholder: I18n.t("+ добавить", "+ add")
                    model: InputConfig.knownLayouts.filter(l => !page.layoutList.includes(l))
                    onActivated: v => InputConfig.save({
                            "layouts": page.layoutList.concat([v]).join(",")
                        })
                }
            }
        }
        SettingRow {
            label: I18n.t("Переключать", "Switch with")
            PxCombo {
                width: Theme.u * 100
                model: InputConfig.switchOptions
                currentValue: page.switchOption
                onActivated: v => page.setOptions(page.optionList.filter(o => !o.startsWith("grp:")).concat([v]))
            }
        }
        Repeater {
            model: InputConfig.extraOptions
            PxCheck {
                required property var modelData
                text: modelData.label
                checked: page.optionList.includes(modelData.value)
                onToggled: c => page.setOptions(page.optionList.filter(o => o !== modelData.value).concat(c ? [modelData.value] : []))
            }
        }
    }

    PxGroup {
        title: I18n.t("Повтор клавиш", "Key repeat")

        advanced: true
        icon: "refresh"
        width: parent.width
        SettingRow {
            label: I18n.t("Задержка", "Delay")
            PxSlider {
                width: parent.width
                from: 150
                to: 800
                stepSize: 10
                value: InputConfig.repeatDelay
                suffix: I18n.t(" мс", " ms")
                onReleased: v => InputConfig.save({
                        "repeatDelay": v
                    })
            }
        }
        SettingRow {
            label: I18n.t("Скорость", "Rate")
            PxSlider {
                width: parent.width
                from: 10
                to: 80
                stepSize: 1
                value: InputConfig.repeatRate
                suffix: I18n.t("/с", "/s")
                onReleased: v => InputConfig.save({
                        "repeatRate": v
                    })
            }
        }
        SettingRow {
            label: I18n.t("NumLock при входе", "NumLock on login")
            hint: InputConfig.numlockState === "noperm" ? I18n.t("niri включает его при своём запуске; включить сразу не вышло — нет доступа к /dev/uinput", "niri turns it on when it starts; turning it on right away failed: no access to /dev/uinput") : I18n.t("niri включает его при запуске, angelOS проверяет лампочку после входа и дожимает", "niri turns it on when it starts; angelOS checks the LED after login and makes sure")
            PxToggle {
                checked: InputConfig.numlock
                onToggled: c => InputConfig.save({
                        "numlock": c
                    })
            }
        }
        PxField {
            width: parent.width
            placeholder: I18n.t("поле для проверки — печатай тут ♡", "Type here to test ♡")
        }
    }

    PxGroup {
        title: I18n.t("Мышь", "Mouse")
        icon: "mouse"
        width: parent.width
        SettingRow {
            label: I18n.t("Ускорение", "Acceleration")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Плоское", "Flat"),
                        "value": "flat"
                    },
                    {
                        "label": I18n.t("Адаптивное", "Adaptive"),
                        "value": "adaptive"
                    }
                ]
                currentValue: InputConfig.accelProfile
                onActivated: v => InputConfig.save({
                        "accelProfile": v
                    })
            }
        }
        SettingRow {
            label: I18n.t("Чувствительность", "Sensitivity")
            PxSlider {
                width: parent.width
                from: -1
                to: 1
                stepSize: 0.05
                decimals: 2
                value: InputConfig.accelSpeed
                onReleased: v => InputConfig.save({
                        "accelSpeed": v
                    })
            }
        }
        SettingRow {
            label: I18n.t("Фокус следует за мышью", "Focus follows mouse")
            PxToggle {
                checked: InputConfig.focusFollowsMouse
                onToggled: c => InputConfig.save({
                        "focusFollowsMouse": c
                    })
            }
        }
    }

    // the lens at the pointer (services/Lens)
    PxGroup {
        width: parent.width
        title: I18n.t("Лупа у курсора", "Lens at the pointer")
        icon: "search"
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            text: I18n.t("Круглая лупа едет за мышкой и увеличивает то, что под ней (как «Лупа» в KDE). niri не умеет зумить сам, поэтому лупа увеличивает снимок экрана: клик или R — новый снимок, остальной экран живой. Внутри: колесо — ближе/дальше, Shift+колесо — размер, ПКМ или Esc — убрать.", "A round lens follows the mouse and magnifies what is under it (like KDE's Magnifier). niri cannot zoom by itself, so the lens magnifies a picture of the screen: a click or R takes a new one, the rest of the screen stays live. Inside: wheel — closer/farther, Shift+wheel — size, right click or Esc — away.")
        }
        SettingRow {
            label: I18n.t("Клавиши", "Keys")
            hint: Lens.log !== "" ? Lens.log : I18n.t("Meta+Alt+= ближе (и открыть), Meta+Alt+- дальше, Meta+Alt+0 убрать; Meta+= и Meta+- у niri заняты шириной колонки", "Meta+Alt+= closer (and open), Meta+Alt+- farther, Meta+Alt+0 away; niri uses Meta+= and Meta+- for the column width")
            Row {
                spacing: Theme.u * 3
                PxToggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: Config.lens.keys
                    onToggled: c => Config.lens.keys = c
                }
                PxButton {
                    anchors.verticalCenter: parent.verticalCenter
                    compact: true
                    icon: "search"
                    text: I18n.t("Попробовать", "Try it")
                    onClicked: Lens.cmd("toggle", "")
                }
            }
        }
        SettingRow {
            label: I18n.t("Увеличение", "Magnification")
            hint: I18n.t("с каким открывается; дальше — клавишами и колесом", "What it opens with; the keys and the wheel change it")
            PxSegmented {
                model: [1.5, 2, 3, 4, 6].map(z => ({
                            "label": "×" + z,
                            "value": z
                        }))
                currentValue: Config.lens.zoom
                onActivated: v => Config.lens.zoom = v
            }
        }
        SettingRow {
            label: I18n.t("Размер", "Size")
            PxSlider {
                width: parent.width
                from: 160
                to: 700
                stepSize: 20
                suffix: " px"
                value: Config.lens.size
                live: false
                onReleased: v => Config.lens.size = v
            }
        }
        SettingRow {
            label: I18n.t("Форма", "Shape")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Круг", "Circle"),
                        "value": "circle"
                    },
                    {
                        "label": I18n.t("Квадрат", "Square"),
                        "value": "square"
                    }
                ]
                currentValue: Config.lens.shape
                onActivated: v => Config.lens.shape = v
            }
        }
        SettingRow {
            label: I18n.t("Чёткие пиксели", "Sharp pixels")
            hint: I18n.t("выключи — будет сглаживание, как в KDE", "Off: smoothed, like KDE")
            PxToggle {
                checked: Config.lens.crisp
                onToggled: c => Config.lens.crisp = c
            }
        }
        SettingRow {
            label: I18n.t("Обновлять снимок", "Retake the picture")
            hint: I18n.t("лупа на миг прячется и снимает экран заново", "The lens hides for a moment and takes the screen again")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("по клику", "on a click"),
                        "value": 0
                    },
                    {
                        "label": I18n.t("раз в 1 с", "every 1 s"),
                        "value": 1
                    },
                    {
                        "label": I18n.t("раз в 3 с", "every 3 s"),
                        "value": 3
                    }
                ]
                currentValue: Config.lens.refresh
                onActivated: v => Config.lens.refresh = v
            }
        }
    }

    PxText {
        width: parent.width
        wrapMode: Text.Wrap
        text: InputConfig.log
        dim: true
    }
}
