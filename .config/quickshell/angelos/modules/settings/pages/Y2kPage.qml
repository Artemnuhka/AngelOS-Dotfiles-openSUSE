pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Y2K bits: the helper angel, glitter, the sound pack and the CD-ROM loading screen.
PxPage {
    id: page

    heading: "Y2K ✧"
    subtitle: I18n.t("Немного 2000-х: ангелочек-помощник, блёстки, звуки и загрузка как у игры с диска.", "A bit of the 2000s: a helper angel, glitter, sounds and a loading screen like a game on a disc.")

    readonly property var screenNames: Quickshell.screens.map(s => s.name)
    function toggleIn(list, name, on) {
        const l = (list || []).filter(n => n !== name);
        return on ? l.concat([name]) : l;
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Ангелочек-помощник", "Helper angel")
        icon: "heart"
        SettingRow {
            label: I18n.t("Показывать", "Show her")
            hint: I18n.t("живёт в правом нижнем углу, подсказывает и радуется вместе с тобой; клик по ней — меню", "Lives in the bottom-right corner, gives tips and cheers you on; click her for a menu")
            PxToggle {
                checked: Config.y2k.helper
                onToggled: c => Config.y2k.helper = c
            }
        }
        SettingRow {
            label: I18n.t("На каком экране", "Screen")
            PxCombo {
                width: parent.width
                model: [
                    {
                        "label": I18n.t("Где фокус", "Where the focus is"),
                        "value": ""
                    }
                ].concat(page.screenNames.map(n => ({
                            "label": n,
                            "value": n
                        })))
                currentValue: Config.y2k.helperScreen
                onActivated: v => Config.y2k.helperScreen = v
            }
        }
        SettingRow {
            label: I18n.t("Советы сами по себе", "Tips on her own")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Нет", "Off"),
                        "value": "off"
                    },
                    {
                        "label": I18n.t("Редко", "Rarely"),
                        "value": "rare"
                    },
                    {
                        "label": I18n.t("Часто", "Often"),
                        "value": "often"
                    }
                ]
                currentValue: Config.y2k.helperTips
                onActivated: v => Config.y2k.helperTips = v
            }
        }
        PxButton {
            enabled: Config.y2k.helper
            icon: "star"
            text: I18n.t("Скажи что-нибудь", "Say something")
            onClicked: {
                Angel.hiddenUntil = 0;
                Angel.tip();
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Блёстки", "Glitter")
        icon: "sparkle"
        SettingRow {
            label: I18n.t("Шлейф за курсором", "Sparkle trail")
            hint: I18n.t("видно, пока курсор над рабочим столом (над окнами он чужой — там блестит сам курсор)", "Shows while the pointer is over the desktop; over windows only the glitter cursor sparkles")
            PxToggle {
                checked: Config.y2k.sparkles
                onToggled: c => Config.y2k.sparkles = c
            }
        }
        SettingRow {
            visible: Config.y2k.sparkles && page.screenNames.length > 1
            label: I18n.t("На экранах", "On screens")
            hint: I18n.t("ничего не выбрано — на всех; например, убери стримовый", "Nothing picked means all; e.g. leave out the streaming one")
            Flow {
                width: parent.width
                spacing: Theme.u * 2
                Repeater {
                    model: page.screenNames
                    PxButton {
                        required property string modelData
                        compact: true
                        checkable: true
                        checked: (Config.y2k.sparkleScreens || []).includes(modelData)
                        text: modelData
                        onClicked: Config.y2k.sparkleScreens = page.toggleIn(Config.y2k.sparkleScreens, modelData, checked)
                    }
                }
            }
        }
        SettingRow {
            label: I18n.t("Блестящий курсор", "Glitter cursor")
            hint: Cursors.theme === "angelOS-Glitter" ? I18n.t("стоит ♡ другие курсоры — на странице «Курсор»", "In use ♡ other cursors are on the Cursor page") : I18n.t("angelOS Pixel с мерцающими искорками, везде: niri, GTK, X11, Steam", "angelOS Pixel with twinkling sparkles, everywhere: niri, GTK, X11, Steam")
            PxButton {
                enabled: !Cursors.busy && Cursors.theme !== "angelOS-Glitter"
                icon: "cursor"
                text: Cursors.busy ? I18n.t("Ставлю…", "Installing…") : I18n.t("Поставить", "Use it")
                onClicked: Cursors.install("glitter", true)
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Звуки", "Sounds")
        icon: "speaker"
        SettingRow {
            label: I18n.t("Звуки angelOS", "angelOS sounds")
            hint: I18n.t("свои, синтезированные: без чужих сэмплов", "Our own, synthesised: no borrowed samples")
            PxToggle {
                checked: Config.y2k.sounds
                onToggled: c => Config.y2k.sounds = c
            }
        }
        SettingRow {
            label: I18n.t("Громкость", "Volume")
            PxSlider {
                width: parent.width
                from: 0
                to: 100
                stepSize: 5
                suffix: " %"
                value: Math.round(Config.y2k.soundVolume * 100)
                live: false
                onReleased: v => {
                    Config.y2k.soundVolume = v / 100;
                    Sounds.preview("notify");
                }
            }
        }
        Repeater {
            model: [
                {
                    "id": "startup",
                    "label": I18n.t("Вход", "Startup"),
                    "hint": I18n.t("вместе с загрузочным экраном", "with the loading screen")
                },
                {
                    "id": "notify",
                    "label": I18n.t("Уведомление", "Notification"),
                    "hint": I18n.t("не звучит в «Не беспокоить»", "Silent in Do not disturb")
                },
                {
                    "id": "error",
                    "label": I18n.t("Важное уведомление", "Urgent notification"),
                    "hint": ""
                },
                {
                    "id": "angel",
                    "label": I18n.t("Ангелочек говорит", "The angel speaks"),
                    "hint": ""
                },
                {
                    "id": "shutdown",
                    "label": I18n.t("Выход и выключение", "Log out and power off"),
                    "hint": I18n.t("успевает доиграть перед выходом", "Plays out before the session ends")
                },
                {
                    "id": "click",
                    "label": I18n.t("Клик", "Click"),
                    "hint": I18n.t("для проверки громкости", "To check the volume")
                }
            ]
            SettingRow {
                id: soundRow
                required property var modelData
                enabled: Config.y2k.sounds
                opacity: enabled ? 1 : 0.5
                label: modelData.label
                hint: modelData.hint
                Row {
                    spacing: Theme.u * 3
                    PxToggle {
                        anchors.verticalCenter: parent.verticalCenter
                        checked: !(Config.y2k.soundOff || []).includes(soundRow.modelData.id)
                        onToggled: c => Config.y2k.soundOff = page.toggleIn(Config.y2k.soundOff, soundRow.modelData.id, !c)
                    }
                    PxButton {
                        compact: true
                        icon: "play"
                        text: I18n.t("Послушать", "Listen")
                        onClicked: Sounds.preview(soundRow.modelData.id)
                    }
                }
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Загрузочный экран", "Loading screen")
        icon: "monitor"
        SettingRow {
            label: I18n.t("При входе в систему", "On login")
            hint: I18n.t("крутится диск, «Вставьте диск 1…», полоска загрузки; один раз за вход, клик — пропустить", "A spinning disc, “insert disc 1…”, a loading bar; once per login, click to skip")
            PxToggle {
                checked: Config.y2k.boot
                onToggled: c => Config.y2k.boot = c
            }
        }
        SettingRow {
            visible: Config.y2k.boot && page.screenNames.length > 1
            label: I18n.t("На экранах", "On screens")
            hint: I18n.t("ничего не выбрано — на всех", "Nothing picked means all")
            Flow {
                width: parent.width
                spacing: Theme.u * 2
                Repeater {
                    model: page.screenNames
                    PxButton {
                        required property string modelData
                        compact: true
                        checkable: true
                        checked: (Config.y2k.bootScreens || []).includes(modelData)
                        text: modelData
                        onClicked: Config.y2k.bootScreens = page.toggleIn(Config.y2k.bootScreens, modelData, checked)
                    }
                }
            }
        }
        PxButton {
            icon: "play"
            text: I18n.t("Показать сейчас", "Show it now")
            onClicked: {
                Shell.settingsOpen = false;
                Shell.bootOpen = true;
            }
        }
    }
}
