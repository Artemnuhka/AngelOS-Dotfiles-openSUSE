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
        SettingRow {
            label: I18n.t("Шутит", "Jokes")
            hint: I18n.t("иногда вместо совета — шутка (на языке интерфейса)", "Now and then a joke instead of a tip (in the interface language)")
            PxToggle {
                checked: Config.y2k.jokes
                onToggled: c => Config.y2k.jokes = c
            }
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 3
            // she comes by herself too; this calls her now (and sends the demon off)
            PxButton {
                icon: "heart"
                enabled: !Angel.transition
                text: Angel.demon ? I18n.t("Призвать ангела (прогнать демоницу)", "Call the angel (send the demon off)") : I18n.t("Позвать ангела", "Call the angel")
                onClicked: {
                    const r = Angel.summon();
                    summonNote.text = r === "hidden" ? I18n.t("стрим-режим прячет её с экранов в эфире — выбери экран не в эфире или выключи «Ангелочек уходит с экрана»", "Stream mode keeps her off the streamed screens: pick another screen or switch off “The angel leaves the screen”") : "";
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
            PxButton {
                enabled: Config.y2k.helper
                icon: "sparkle"
                text: I18n.t("Пошути", "Tell a joke")
                onClicked: {
                    Angel.hiddenUntil = 0;
                    Angel.joke();
                }
            }
        }
        PxText {
            id: summonNote
            width: parent.width
            visible: text !== ""
            wrapMode: Text.Wrap
            kind: "tiny"
            color: Theme.danger
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Ангел или демон", "Angel or demon")
        icon: "fire"
        SettingRow {
            label: I18n.t("Кто живёт в углу", "Who lives in the corner")
            hint: Angel.demon ? I18n.t("Демоница. Вернуть ангела можно только уговорами: её меню → «Спросить…» → «Верни ангела». Нужно 3 удачные просьбы за 2 часа, считается одна в 10 минут. Сейчас: ", "The demon. Only begging brings the angel back: her menu → “Ask…” → “Bring the angel back”. Three lucky pleas within 2 hours, one counts every 10 minutes. Now: ") + Angel.pleasCounted + "/" + Angel.pleasNeeded : I18n.t("Ангелочек. Схвати её мышкой и скинь вниз — провалится в ад, и придёт демоница: тёмные обои, пошлые шутки и пакости, которые показывают фишки angelOS.", "Angel. Grab her with the mouse and throw her down: she drops into hell and the demon comes — dark wallpaper, cheeky jokes and pranks that show off angelOS features.")
            PxIcon {
                name: Angel.demon ? "fire" : "heart"
                pixel: Theme.u * 2
            }
        }
        SettingRow {
            label: I18n.t("Дрожание текста", "Text tremble")
            hint: I18n.t("буквы в её репликах иногда подёргиваются на пиксель, как в Undertale", "Now and then a letter in her lines twitches by a pixel, like in Undertale")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Нет", "Off"),
                        "value": "off"
                    },
                    {
                        "label": I18n.t("Слегка", "Light"),
                        "value": "light"
                    },
                    {
                        "label": I18n.t("Сильно", "Strong"),
                        "value": "strong"
                    }
                ]
                currentValue: Config.y2k.textShake
                onActivated: v => Config.y2k.textShake = v
            }
        }
        SettingRow {
            label: I18n.t("Тёмные обои демоницы", "The demon's dark wallpaper")
            hint: I18n.t("пиксельный ад на всех экранах, пока она тут; ангел вернёт твои обои. Выключишь — твои обои вернутся сразу", "Pixel hell on every screen while she's here; the angel gives yours back. Switching it off brings yours back at once")
            PxToggle {
                checked: Config.y2k.hellWallpaper
                onToggled: c => Config.y2k.hellWallpaper = c
            }
        }
        SettingRow {
            label: I18n.t("Какой ад на обоях", "Which hell on the wallpaper")
            hint: I18n.t("картины — пиксельный ад из Мартина, Доре и Босха (пак Hell, скачается сам, если его нет); нарисованный — пиксельная лава с луной-сердцем", "Paintings: pixel hell from Martin, Doré and Bosch (the Hell pack, fetched if it's missing); drawn: pixel lava under a heart moon")
            enabled: Config.y2k.hellWallpaper
            opacity: enabled ? 1 : 0.5
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Картины", "Paintings"),
                        "value": "pack"
                    },
                    {
                        "label": I18n.t("Нарисованный", "Drawn"),
                        "value": "drawn"
                    }
                ]
                currentValue: Config.y2k.hellStyle
                onActivated: v => Config.y2k.hellStyle = v
            }
        }
        SettingRow {
            label: I18n.t("Трещины на экране", "Screen cracks")
            hint: I18n.t("она бьёт по стеклу слева снизу; чем ближе курсор, тем прозрачнее стекло, клики проходят насквозь. Вернётся ангел — осколки осыплются", "She punches the glass bottom left; the nearer the pointer, the clearer the glass, and clicks go through. When the angel is back the shards fall out")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Сильно", "Full"),
                        "value": "full"
                    },
                    {
                        "label": I18n.t("Слабо", "Weak"),
                        "value": "weak"
                    },
                    {
                        "label": I18n.t("Нет", "Off"),
                        "value": "off"
                    }
                ]
                currentValue: Config.y2k.cracks
                onActivated: v => Config.y2k.cracks = v
            }
        }
        SettingRow {
            label: I18n.t("Тряска экрана", "Screen shake")
            hint: I18n.t("когда ангел и демоница меняются, экран трясётся и бьётся стекло; с демоницей ещё сыплются 8-битные камни", "When the angel and the demon swap the screen shakes and the glass breaks; with the demon 8-bit rocks tumble down too")
            PxToggle {
                checked: Config.y2k.shake
                onToggled: c => Config.y2k.shake = c
            }
        }
        SettingRow {
            label: I18n.t("Лучи и хор ангела", "The angel's rays and choir")
            hint: I18n.t("когда она появляется: полторы секунды солнца справа", "When she appears: a second and a half of sunshine on the right")
            PxToggle {
                checked: Config.y2k.heavenFx
                onToggled: c => Config.y2k.heavenFx = c
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Стрим-режим", "Stream mode")
        icon: "monitor"
        SettingRow {
            label: I18n.t("Сейчас", "Now")
            hint: StreamMode.active ? I18n.t("эфир: angelOS не лезет в кадр", "Live: angelOS stays out of the picture") : Config.stream.auto ? (StreamMode.obsUp ? I18n.t("OBS на связи, эфира нет", "OBS connected, not streaming") : StreamMode.obsAuth ? I18n.t("OBS просит пароль WebSocket — включи вход без пароля или сохрани пароль в OBS", "OBS wants a WebSocket password") : I18n.t("OBS не запущен или WebSocket-сервер выключен (Инструменты → Настройки WebSocket)", "OBS isn't running or its WebSocket server is off (Tools → WebSocket Server Settings)")) : I18n.t("выключен", "Off")
            PxButton {
                icon: StreamMode.active ? "close" : "play"
                accent: !StreamMode.active
                text: StreamMode.active ? I18n.t("Выключить", "Switch off") : I18n.t("Включить вручную", "Switch on by hand")
                onClicked: StreamMode.set("toggle")
            }
        }
        SettingRow {
            label: I18n.t("Сам по OBS", "Follow OBS")
            hint: I18n.t("включается, пока OBS ведёт трансляцию (obs-websocket, порт ", "On while OBS is streaming (obs-websocket, port ") + Config.stream.port + ")"
            PxToggle {
                checked: Config.stream.auto
                onToggled: c => Config.stream.auto = c
            }
        }
        SettingRow {
            visible: page.screenNames.length > 1
            label: I18n.t("Экраны в эфире", "Streamed screens")
            hint: I18n.t("ничего не выбрано — все; остальные экраны живут как обычно", "Nothing picked means all; the others carry on as usual")
            Flow {
                width: parent.width
                spacing: Theme.u * 2
                Repeater {
                    model: page.screenNames
                    PxButton {
                        required property string modelData
                        compact: true
                        checkable: true
                        checked: (Config.stream.screens || []).includes(modelData)
                        text: modelData
                        onClicked: Config.stream.screens = page.toggleIn(Config.stream.screens, modelData, checked)
                    }
                }
            }
        }
        SettingRow {
            label: I18n.t("Ангелочек уходит с экрана", "The angel leaves the screen")
            hint: I18n.t("на другой экран, а если его нет — прячется", "To another screen, or hides if there is none")
            PxToggle {
                checked: Config.stream.hideAngel
                onToggled: c => Config.stream.hideAngel = c
            }
        }
        SettingRow {
            label: I18n.t("Тишина", "Quiet")
            hint: I18n.t("звуки angelOS не попадут в эфир", "angelOS sounds stay off the stream")
            PxToggle {
                checked: Config.stream.mute
                onToggled: c => Config.stream.mute = c
            }
        }
        SettingRow {
            label: I18n.t("«Не беспокоить»", "Do not disturb")
            hint: I18n.t("уведомления копятся в истории; после эфира всё как было", "Notifications wait in the history; back to normal after the stream")
            PxToggle {
                checked: Config.stream.dnd
                onToggled: c => Config.stream.dnd = c
            }
        }
        SettingRow {
            label: I18n.t("Без эффектов", "No effects")
            hint: I18n.t("ни блёсток, ни загрузочного экрана, ни лучей и трещин на экранах в эфире", "No sparkles, loading screen, rays or cracks on streamed screens")
            PxToggle {
                checked: Config.stream.effects
                onToggled: c => Config.stream.effects = c
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
            hint: I18n.t("молчат в стрим-режиме", "Quiet in stream mode")
            PxToggle {
                checked: Config.y2k.sounds
                onToggled: c => Config.y2k.sounds = c
            }
        }
        SettingRow {
            label: I18n.t("Набор", "Sound pack")
            hint: Config.y2k.soundPack === "overdose" ? (Sounds.downloading ? I18n.t("скачиваю с GitHub (Plasma-Overdose)…", "Downloading from GitHub (Plasma-Overdose)…") : Sounds.overdoseError ? Sounds.overdoseError : I18n.t("звуки Windose из NEEDY GIRL OVERDOSE; скачиваются один раз из Plasma-Overdose, принадлежат авторам игры", "Windose sounds from NEEDY GIRL OVERDOSE, fetched once from Plasma-Overdose; they belong to the game's authors")) : I18n.t("свои, синтезированные: без чужих сэмплов", "Our own, synthesised: no borrowed samples")
            PxSegmented {
                model: [
                    {
                        "label": "Y2K",
                        "value": "y2k"
                    },
                    {
                        "label": "Overdose ♡",
                        "value": "overdose"
                    }
                ]
                currentValue: Config.y2k.soundPack
                onActivated: v => {
                    Config.y2k.soundPack = v;
                    Sounds.preview("notify");
                }
            }
        }
        SettingRow {
            label: I18n.t("Милые мелочи", "Cute little sounds")
            hint: I18n.t("«Пуск», переключатели, скриншоты, громкость, закрытие окон", "Start, switches, screenshots, volume, closing windows")
            PxToggle {
                checked: Config.y2k.cuteSounds
                onToggled: c => Config.y2k.cuteSounds = c
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
        SettingRow {
            label: I18n.t("Голос ангела и демоницы", "The angel's and the demon's voice")
            hint: I18n.t("её «пип» на каждую букву, «хех», хор, трещины и камни — доля от общей громкости", "Her pip on every letter, the “heh”, the choir, cracks and rocks — a share of the volume above")
            PxSlider {
                width: parent.width
                from: 0
                to: 100
                stepSize: 5
                suffix: " %"
                value: Math.round(Config.y2k.helperVolume * 100)
                live: false
                onReleased: v => {
                    Config.y2k.helperVolume = v / 100;
                    Sounds.preview("voice");
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
                    "id": "demon",
                    "label": I18n.t("Демоница говорит", "The demon speaks"),
                    "hint": ""
                },
                {
                    "id": "wallpaper",
                    "label": I18n.t("Смена обоев", "Wallpaper change"),
                    "hint": I18n.t("каждый раз", "Every time")
                },
                {
                    "id": "open",
                    "label": I18n.t("Окна angelOS", "angelOS windows"),
                    "hint": I18n.t("милая мелочь", "A cute one")
                },
                {
                    "id": "toggle",
                    "label": I18n.t("Переключатель", "Switch"),
                    "hint": I18n.t("милая мелочь", "A cute one")
                },
                {
                    "id": "screenshot",
                    "label": I18n.t("Скриншот", "Screenshot"),
                    "hint": I18n.t("вместо обычного уведомления", "Instead of the usual notification")
                },
                {
                    "id": "volume",
                    "label": I18n.t("Громкость", "Volume"),
                    "hint": I18n.t("милая мелочь", "A cute one")
                },
                {
                    "id": "windowClose",
                    "label": I18n.t("Окно закрылось", "A window closed"),
                    "hint": I18n.t("милая мелочь", "A cute one")
                },
                {
                    "id": "choir",
                    "label": I18n.t("Хор ангела", "The angel's choir"),
                    "hint": ""
                },
                {
                    "id": "crack",
                    "label": I18n.t("Удар по стеклу", "The glass punch"),
                    "hint": ""
                },
                {
                    "id": "voice",
                    "label": I18n.t("Голоса (пип-пип)", "Voices (pip-pip)"),
                    "hint": I18n.t("как в Undertale: писк на каждую букву, у ангела и демоницы свой", "Like Undertale: a pip for every letter, the angel's and the demon's own")
                },
                {
                    "id": "rocks",
                    "label": I18n.t("Тряска и камни", "Quake and rocks"),
                    "hint": I18n.t("8-битный грохот камней, когда приходит демоница", "8-bit rumble of rocks when the demon arrives")
                },
                {
                    "id": "shatter",
                    "label": I18n.t("Экран ломается", "The screen breaks"),
                    "hint": I18n.t("8-битный звон стекла, когда ангел и демоница меняются", "8-bit glass crash when the angel and the demon swap")
                },
                {
                    "id": "shutdown",
                    "label": I18n.t("Выход и выключение", "Log out and power off"),
                    "hint": I18n.t("успевает доиграть перед выходом", "Plays out before the session ends")
                },
                {
                    "id": "click",
                    "label": I18n.t("Клик", "Click"),
                    "hint": Sounds.clickStatus === "noperm" ? I18n.t("нет доступа к мыши (группа input) — клики не слышно", "No access to the mouse (the input group): clicks stay silent") : I18n.t("щелчок на каждый клик ЛКМ и ПКМ, во всех окнах", "A tick on every left and right click, in every window")
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
