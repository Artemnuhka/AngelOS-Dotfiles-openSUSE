pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets
import qs.modules.y2k
import "../../y2k/AngelSprite.js" as AngelArt
import "../../y2k/DemonSprite.js" as DemonArt
import "../../y2k/AngelSpriteMini.js" as AngelMini
import "../../y2k/DemonSpriteMini.js" as DemonMini

// Y2K bits: the helper angel, glitter, the sound pack and the CD-ROM loading screen.
PxPage {
    id: page

    heading: Angel.demon ? I18n.t("Демоница ⛧", "The demon ⛧") : I18n.t("Ангелочек ✧", "The angel ✧")
    // in hell the angel's own things step aside: the page is about the demon (Angel.demon)
    subtitle: Angel.demon ? I18n.t("Немного 2000-х: демоница в углу экрана, блёстки, звуки и загрузка как у игры с диска.", "A bit of the 2000s: the demon in the corner, glitter, sounds and a loading screen like a game on a disc.") : I18n.t("Немного 2000-х: ангелочек-помощник, блёстки, звуки и загрузка как у игры с диска.", "A bit of the 2000s: a helper angel, glitter, sounds and a loading screen like a game on a disc.")

    readonly property var screenNames: Quickshell.screens.map(s => s.name)
    function toggleIn(list, name, on) {
        const l = (list || []).filter(n => n !== name);
        return on ? l.concat([name]) : l;
    }

    PxGroup {
        width: parent.width
        title: Angel.demon ? I18n.t("Демоница в углу", "The demon in the corner") : I18n.t("Ангелочек-помощник", "Helper angel")
        icon: Angel.demon ? "fire" : "heart"
        SettingRow {
            label: I18n.t("Показывать", "Show her")
            hint: Angel.demon ? I18n.t("сидит в правом нижнем углу, язвит, болтает и пакостит; клик по ней — меню", "Sits in the bottom-right corner, teases, chats and plays pranks; click her for a menu") : I18n.t("живёт в правом нижнем углу, подсказывает и радуется вместе с тобой; клик по ней — меню", "Lives in the bottom-right corner, gives tips and cheers you on; click her for a menu")
            PxToggle {
                checked: Config.y2k.helper
                onToggled: c => Config.y2k.helper = c
            }
        }
        SettingRow {
            label: I18n.t("На каком экране", "Screen")
            hint: I18n.t("главный выбирается в «Мониторе»; там же — её трещины и лучи", "The main one is picked on the Monitor page; her cracks and rays go along")
            PxCombo {
                width: parent.width
                model: [
                    {
                        "label": I18n.t("Главный (", "Main (") + Shell.primaryName + ")",
                        "value": ""
                    },
                    {
                        "label": I18n.t("Где фокус", "Where the focus is"),
                        "value": "focus"
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
            label: I18n.t("Размер", "Size")
            hint: I18n.t("или Ctrl + колёсико мыши над ней — по 5 %, до +15 %", "Or Ctrl + mouse wheel over her: 5 % a notch, up to +15 %")
            PxSlider {
                width: Math.min(parent.width, Theme.u * 120)
                from: 100
                to: 115
                stepSize: 5
                value: Math.round((Config.y2k.helperScale || 1) * 100)
                suffix: "%"
                onMoved: v => Config.y2k.helperScale = Math.round(v) / 100
            }
        }
        SettingRow {
            label: Angel.demon ? I18n.t("Болтает сама", "Talks on her own") : I18n.t("Советы сами по себе", "Tips on her own")
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
                visible: !Angel.demon
                icon: "heart"
                enabled: !Angel.transition
                text: I18n.t("Позвать ангела", "Call the angel")
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

    // the helper's four versions, for each of them apart
    component LookCard: PxButton {
        id: card
        required property var modelData
        property string who: "angel"
        readonly property string current: who === "demon" ? Config.y2k.demonLook || "glitch" : Config.y2k.angelLook || "glitch"
        width: Math.max(Theme.u * 64, lookLabel.implicitWidth + Theme.u * 8)
        height: Theme.u * 78
        checked: current === modelData.value
        onClicked: {
            if (who === "demon")
                Config.y2k.demonLook = modelData.value;
            else
                Config.y2k.angelLook = modelData.value;
        }
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.u * 4
            width: parent.width - Theme.u * 6
            height: parent.height - lookLabel.height - Theme.u * 10
            SpriteRig {
                visible: card.modelData.value === "chibi" || card.modelData.value === "glitch"
                anchors.centerIn: parent
                who: card.who
                variant: card.modelData.value === "glitch" ? "glitch" : ""
                px: Math.max(0.5, Theme.u / 4)
                width: implicitWidth
                height: implicitHeight
            }
            PxIcon {
                visible: card.modelData.value !== "chibi" && card.modelData.value !== "glitch"
                anchors.centerIn: parent
                readonly property bool mini: card.modelData.value === "mini"
                bitmap: mini ? (card.who === "demon" ? DemonMini.up : AngelMini.up) : (card.who === "demon" ? DemonArt.up : AngelArt.up)
                pixel: mini ? Math.max(1, Theme.u) : Math.max(1, Math.round(Theme.u * 0.75))
                ink: card.who === "demon" ? "#1a0a14" : (Theme.dark ? Theme.text : Theme.edge)
                body: card.who === "demon" ? "#f7d9e3" : "#ffd9c7"
                fill: card.who === "demon" ? "#ff3b6b" : Theme.accent
                fill2: "#3a1a46"
                fill3: Theme.dark ? "#ffe07a" : "#f5c542"
                light: card.who === "demon" ? "#7a1e46" : "#ffffff"
                bad: "#d8203a"
                palette: mini ? ({}) : card.who === "demon" ? DemonArt.palette : Object.assign({}, AngelArt.palette, {
                    "o": Theme.hex(Theme.accent)
                })
            }
        }
        PxText {
            id: lookLabel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.u * 3
            kind: "tiny"
            font.bold: card.checked
            text: (card.checked ? "♡ " : "") + card.modelData.label
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Внешность", "Looks")
        icon: "palette"
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            text: Angel.demon ? I18n.t("Нынешняя неоновая демоница без сна, прошлая чиби, суккуб 30×40 или чертёнок 20×21.", "Today's sleepless neon demon, the earlier chibi, a 30×40 succubus or a 20×21 imp.") : Angel.hellShown ? I18n.t("Нынешние глитч-девочки (ангел с треснувшим нимбом и неоновая демоница), прошлые чиби, взрослые пиксельные 30×40 или самые первые малышки 20×21. Ангел и демоница выбираются отдельно.", "Today's glitch girls (the cracked-halo angel and the neon demon), the earlier chibi, the adult 30×40 pixel ones or the very first 20×21 minis. The angel and the demon are picked apart.") : I18n.t("Нынешняя глитч-девочка (ангел с треснувшим нимбом), прошлая чиби, взрослая пиксельная 30×40 или самая первая малышка 20×21.", "Today's glitch girl (the cracked-halo angel), the earlier chibi, the adult 30×40 pixel one or the very first 20×21 mini.")
        }
        SettingRow {
            visible: !Angel.demon
            label: I18n.t("Ангел", "Angel")
            Flow {
                width: parent.width
                spacing: Theme.u * 4
                Repeater {
                    model: [
                        {
                            "value": "glitch",
                            "label": I18n.t("Треснувший нимб (сейчас)", "Cracked halo (now)")
                        },
                        {
                            "value": "chibi",
                            "label": I18n.t("Чиби", "Chibi")
                        },
                        {
                            "value": "adult",
                            "label": I18n.t("Взрослая 30×40", "Adult 30×40")
                        },
                        {
                            "value": "mini",
                            "label": I18n.t("Малышка 20×21", "Mini 20×21")
                        }
                    ]
                    LookCard {
                        who: "angel"
                    }
                }
            }
        }
        // hell's own rows below show only while the demon rules (Angel.hellShown)
        SettingRow {
            visible: Angel.hellShown
            label: I18n.t("Демоница", "Demon")
            Flow {
                width: parent.width
                spacing: Theme.u * 4
                Repeater {
                    model: [
                        {
                            "value": "glitch",
                            "label": I18n.t("Неон без сна (сейчас)", "Sleepless neon (now)")
                        },
                        {
                            "value": "chibi",
                            "label": I18n.t("Чиби", "Chibi")
                        },
                        {
                            "value": "adult",
                            "label": I18n.t("Суккуб 30×40", "Succubus 30×40")
                        },
                        {
                            "value": "mini",
                            "label": I18n.t("Чертёнок 20×21", "Imp 20×21")
                        }
                    ]
                    LookCard {
                        who: "demon"
                    }
                }
            }
        }
    }

    PxGroup {
        width: parent.width
        title: Angel.hellShown ? I18n.t("Ангел или демон", "Angel or demon") : I18n.t("Ангел и портал", "Angel and the portal")
        icon: Angel.hellShown ? "fire" : "heart"
        SettingRow {
            label: I18n.t("Кто живёт в углу", "Who lives in the corner")
            hint: Angel.demon ? I18n.t("Демоница. Путь наверх лежит вниз, через круги: её меню → «Спросить…» → «Искать выход», не чаще раза в 10 минут. Сейчас: круг ", "The demon. The way up lies down, through the circles: her menu → “Ask…” → “Seek the way out”, once per 10 minutes at most. Now: circle ") + Theme.roman(Story.circleN(Story.circle)) + " · " + Story.circleName(Story.circle) : I18n.t("Ангелочек. Схвати её мышкой и скинь вниз — провалится в ад, и придёт демоница: тёмные обои, пошлые шутки и пакости, которые показывают фишки angelOS.", "Angel. Grab her with the mouse and throw her down: she drops into hell and the demon comes — dark wallpaper, cheeky jokes and pranks that show off angelOS features.")
            PxIcon {
                name: Angel.demon ? "fire" : "heart"
                pixel: Theme.u * 2
            }
        }
        SettingRow {
            label: I18n.t("Портал", "Portal")
            hint: Angel.portalOpen ? I18n.t("открыт: в ад и обратно — когда захочешь, без мольб и бросков (ещё — в её меню и `angelos helper portal`); адские настройки — в аду", "Open: to hell and back whenever you like, no begging and no throwing (also in her menu and `angelos helper portal`); hell's settings are in hell") : I18n.t("откроется, когда ангел трижды вернётся из ада. Возвращений: ", "Opens once the angel has come back from hell three times. Comebacks: ") + Math.min(Angel.returns, Angel.returnsNeeded) + "/" + Angel.returnsNeeded
            PxButton {
                enabled: Angel.portalOpen && !Angel.transition
                icon: Angel.portalOpen ? "sparkle" : "lock"
                accent: Angel.portalOpen
                text: !Angel.portalOpen ? I18n.t("Закрыт", "Closed") : Angel.demon ? I18n.t("В рай", "To heaven") : I18n.t("В ад", "To hell")
                onClicked: Angel.portal()
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
            label: I18n.t("Тряска экрана", "Screen shake")
            hint: Angel.hellShown ? I18n.t("когда ангел и демоница меняются, экран трясётся и бьётся стекло; с демоницей ещё сыплются 8-битные камни", "When the angel and the demon swap the screen shakes and the glass breaks; with the demon 8-bit rocks tumble down too") : I18n.t("когда ангел уходит через портал или возвращается, экран трясётся и бьётся стекло", "When the angel leaves through the portal or comes back the screen shakes and the glass breaks")
            PxToggle {
                checked: Config.y2k.shake
                onToggled: c => Config.y2k.shake = c
            }
        }
        SettingRow {
            label: I18n.t("Лучи и хор ангела", "The angel's rays and choir")
            hint: I18n.t("когда она возвращается из ада: полторы секунды солнца справа (при запуске — только самый первый раз)", "When she comes back from hell: a second and a half of sunshine on the right (at start-up only the very first time)")
            PxToggle {
                checked: Config.y2k.heavenFx
                onToggled: c => Config.y2k.heavenFx = c
            }
        }
    }

    // hell's versions of everything, a sub-page of its own (only while the demon is about)
    PxGroup {
        width: parent.width
        title: I18n.t("Ад", "Hell")
        icon: "pentagram"
        advanced: true
        shown: Angel.hellShown
        SettingRow {
            visible: Angel.hellShown
            label: I18n.t("ПКМ в аду", "Right-click menu in hell")
            hint: I18n.t("пока правит демоница; вернётся ангел — снова твоё меню", "while the demon rules; the angel brings your own menu back")
            PxCombo {
                width: Math.min(parent.width, Theme.u * 120)
                model: [
                    {
                        "label": I18n.t("Пентаграмма", "Pentagram"),
                        "value": "pentagram"
                    },
                    {
                        "label": I18n.t("Как обычно (моё меню)", "As usual (my menu)"),
                        "value": ""
                    },
                    {
                        "label": I18n.t("Кольцо", "Ring"),
                        "value": "radial"
                    },
                    {
                        "label": I18n.t("Y2K глянец", "Y2K gloss"),
                        "value": "y2k"
                    },
                    {
                        "label": I18n.t("Плитки", "Tiles"),
                        "value": "tiles"
                    }
                ]
                currentValue: Config.y2k.hellMenu || ""
                onActivated: v => Config.y2k.hellMenu = v
            }
        }
        SettingRow {
            visible: Angel.hellShown
            label: I18n.t("Настройки в аду", "Settings in hell")
            hint: I18n.t("гримуар: окно настроек становится старой книгой — оглавление слева, страницы перелистываются", "grimoire: Settings turn into an old book — contents on the left, pages that turn")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Гримуар", "Grimoire"),
                        "value": "grimoire"
                    },
                    {
                        "label": I18n.t("Как обычно", "As usual"),
                        "value": ""
                    }
                ]
                currentValue: Config.y2k.hellSettings || ""
                onActivated: v => Config.y2k.hellSettings = v
            }
        }
        SettingRow {
            visible: Angel.hellShown
            label: I18n.t("«Пуск» в аду", "Start in hell")
            hint: I18n.t("кнопка «Пуск» и меню перекрашиваются в цвета круга: тёмная основа, костяной текст, один приглушённый акцент. «Своё адское» — отдельное меню: «Призвать» программы, гримуар, мольба об ангеле, портал", "The Start button and menu take the circle's colours: a dark base, bone text, one dulled accent. “Hell's own” is a menu of its own: summon apps, the grimoire, begging for the angel, the portal")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Адская версия", "Hell version"),
                        "value": "skin"
                    },
                    {
                        "label": I18n.t("Своё адское", "Hell's own"),
                        "value": "hell"
                    },
                    {
                        "label": I18n.t("Как обычно", "As usual"),
                        "value": ""
                    }
                ]
                currentValue: Config.y2k.hellStart || ""
                onActivated: v => Config.y2k.hellStart = v
            }
        }
        SettingRow {
            visible: Angel.hellShown
            label: I18n.t("Alt+Tab в аду", "Alt+Tab in hell")
            hint: I18n.t("«Своё адское» — окно inferno.exe: выбранное окно над пентаграммой, столы — круги ада. «Адская версия» — твой стиль Alt+Tab в цветах круга", "“Hell's own” is an inferno.exe window: the pick over a pentagram, desks are hell's circles. “Hell version” is your Alt+Tab style in the circle's colours")
            Flow {
                width: parent.width
                spacing: Theme.u * 4
                PxSegmented {
                    model: [
                        {
                            "label": I18n.t("Своё адское", "Hell's own"),
                            "value": "hell"
                        },
                        {
                            "label": I18n.t("Адская версия", "Hell version"),
                            "value": "skin"
                        },
                        {
                            "label": I18n.t("Как обычно", "As usual"),
                            "value": ""
                        }
                    ]
                    currentValue: Config.y2k.hellAltTab || ""
                    onActivated: v => Config.y2k.hellAltTab = v
                }
                PxButton {
                    compact: true
                    icon: "play"
                    text: I18n.t("Попробовать", "Try it")
                    onClicked: AltTab.tryIt("")
                }
            }
        }
        SettingRow {
            visible: Angel.hellShown
            label: I18n.t("Терминал в аду", "Terminal in hell")
            hint: I18n.t("kitty, foot и Alacritty в цветах круга: почти чёрный фон, костяной текст, приглушённые цвета вывода; в kitty — выжженный фон с едва заметной пентаграммой; в fish команды подсвечиваются цветами круга, а при открытии демоница говорит пару слов", "kitty, foot and Alacritty in the circle's colours: a near-black background, bone text, dulled output colours; kitty gets a scorched background with a pentagram barely there; fish colours your commands in the circle's ink and she has a word for you in every new terminal")
            PxToggle {
                checked: Config.y2k.hellTerminal
                onToggled: c => Config.y2k.hellTerminal = c
            }
        }
        SettingRow {
            visible: Angel.hellShown
            label: I18n.t("Приложения в аду", "Apps in hell")
            hint: I18n.t("GTK-программы (Nautilus, настройки GNOME…) целиком в адских цветах, а не только заголовки; Qt — тоже, если включён стиль angelOS для Qt во «Внешнем виде»", "GTK apps (Nautilus, GNOME settings…) wholly in hell's colours, not just their title bars; Qt ones too when the angelOS Qt look is on in Appearance")
            PxToggle {
                checked: Config.y2k.hellApps
                onToggled: c => Config.y2k.hellApps = c
            }
        }
        SettingRow {
            visible: Angel.hellShown
            label: I18n.t("Панель в аду", "Bar in hell")
            hint: I18n.t("у каждого вида адская версия: камень круга по краям и в пустых местах, под значками и текстом — спокойная тёмная подложка, тонкая кромка сверху; док остаётся обычным", "Each style has a hell version: the circle's stone along the edges and in the empty spaces, a calm dark plate under icons and text, a thin rim on top; the dock stays as it is")
            PxToggle {
                checked: Config.y2k.hellBar
                onToggled: c => Config.y2k.hellBar = c
            }
        }
        SettingRow {
            visible: Angel.hellShown
            label: I18n.t("Лирика в аду", "Lyrics in hell")
            hint: I18n.t("строка на панели — адской готикой (Jacquard 12 Hell) в цвете круга, без печатной машинки и анимаций: следующая строка просто появляется", "The bar's line in hell's blackletter (Jacquard 12 Hell) in the circle's colour, no typewriter and no animation: the next line is simply there")
            Flow {
                width: parent.width
                spacing: Theme.u * 4
                PxToggle {
                    checked: Config.y2k.hellLyrics
                    onToggled: c => Config.y2k.hellLyrics = c
                }
                PxButton {
                    compact: true
                    icon: "fire"
                    text: I18n.t("Салют", "Salute")
                    onClicked: {
                        const sc = Shell.primaryScreen || Shell.screens[0];
                        if (sc)
                            HellFx.fireworks(sc.name, sc.width / 2, BarLayout.bottom ? sc.height - Theme.u * 12 : Theme.u * 12, !BarLayout.bottom);
                    }
                }
            }
        }
        SettingRow {
            visible: Angel.hellShown
            label: I18n.t("Колесо Ада", "Wheel of Hell")
            hint: I18n.t("её виджет на стол, только в аду: раз в 20 минут крутишь — две мольбы за ангела, наказание, новый ад, цербер, землетрясение, проклятый курсор на час или пустышка", "Her desktop widget, hell only: a spin every 20 minutes — two pleas for the angel, a punishment, a new hell, Cerberus, an earthquake, a cursed cursor for an hour or a dud")
            PxButton {
                compact: true
                icon: "pentagram"
                text: DesktopWidgets.widgets.some(w => w.type === "hellwheel") ? I18n.t("Уже на столе", "On the desk") : I18n.t("Поставить на стол", "Put it on the desk")
                enabled: !DesktopWidgets.widgets.some(w => w.type === "hellwheel")
                onClicked: DesktopWidgets.add("hellwheel", Shell.primaryName)
            }
        }
        SettingRow {
            visible: Angel.hellShown
            label: I18n.t("Виджеты в аду", "Widgets in hell")
            hint: I18n.t("когда бьётся стекло, виджеты сгорают и встают адскими: обсидиан, пламя, римские часы, огненные столбы; с ангелом пепел сдувает ветром. Свои плагины без адской версии перекрашиваются", "When the glass breaks the widgets burn and rise from hell: obsidian, flames, a Roman clock, columns of fire; with the angel the wind blows the ash away. Plugins without a hell look of their own are re-inked")
            PxToggle {
                checked: Config.y2k.hellWidgets
                onToggled: c => Config.y2k.hellWidgets = c
            }
        }
        SettingRow {
            visible: Angel.hellShown
            label: I18n.t("Курсор в аду", "Cursor in hell")
            hint: Config.cursor.hell ? I18n.t("пока правит демоница, курсор — ", "While the demon rules the pointer is ") + ((Cursors.entryOf(Config.cursor.hell) || {}).name || Config.cursor.hell) + I18n.t("; шесть адских тем — на странице «Курсор»", "; six hell themes are on the Cursor page") : I18n.t("демоница не трогает курсор", "The demon leaves the cursor alone")
            PxButton {
                compact: true
                icon: "cursor"
                text: I18n.t("Выбрать", "Choose")
                onClicked: Shell.settingsPage = "cursor"
            }
        }
        SettingRow {
            visible: Angel.hellShown
            label: I18n.t("Какой ад на обоях", "Which hell on the wallpaper")
            hint: I18n.t("пока правит демоница, на всех экранах всегда ад — любые другие обои она тут же снимает (они дождутся ангела). Картины — пиксельный ад из Мартина, Доре и Босха (пак Hell, скачается сам); нарисованный — пиксельная лава с луной-сердцем", "While the demon rules every screen always shows hell — any other wallpaper she takes down at once (it waits for the angel). Paintings: pixel hell from Martin, Doré and Bosch (the Hell pack, fetched if missing); drawn: pixel lava under a heart moon")
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
            visible: Angel.hellShown
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
            visible: Angel.hellShown && Config.y2k.cracks !== "off"
            label: I18n.t("Что она ломает", "What she breaks")
            hint: I18n.t("куда приходится её кулак: стекло трескается; телевизор — дыра со «снегом» и битыми полосами экрана; прожжённая дыра — внутри адский огонь; когти — четыре светящиеся раны; печать — выжженная пентаграмма. «Случайно» — каждый раз другое", "Where her fist lands: glass cracks; a TV gets a hole with snow and dead screen lines; a burnt hole has hellfire inside; claws leave four glowing gashes; a sigil is a pentagram burnt into the glass. “Random”: something else every time")
            PxCombo {
                width: Math.min(parent.width, Theme.u * 120)
                model: [
                    {
                        "label": I18n.t("Стекло", "Glass"),
                        "value": "glass"
                    },
                    {
                        "label": I18n.t("Разбитый телевизор", "Smashed TV"),
                        "value": "tv"
                    },
                    {
                        "label": I18n.t("Прожжённая дыра", "Burnt hole"),
                        "value": "burn"
                    },
                    {
                        "label": I18n.t("Следы когтей", "Claw marks"),
                        "value": "claws"
                    },
                    {
                        "label": I18n.t("Выжженная печать", "Burnt sigil"),
                        "value": "sigil"
                    },
                    {
                        "label": I18n.t("Случайно", "Random"),
                        "value": "random"
                    }
                ]
                currentValue: Config.y2k.breakage || "glass"
                onActivated: v => Config.y2k.breakage = v
            }
        }
    }

    // the novel (services/Novel): chapters written in the editor, played out on the desktop
    PxGroup {
        width: parent.width
        title: I18n.t("Новелла", "The novel")
        advanced: true
        icon: "document"
        SettingRow {
            label: I18n.t("Истории ангела", "The angel's stories")
            hint: I18n.t("главы из папки ", "Chapters from ") + Novel.dir + I18n.t(": записки на обоях после сна, вопросы с вариантами ответа («?» над ней — нажми), её записки про тебя. Пишутся в редакторе диалогов", ": notes on the wallpaper after sleep, questions with answers to pick (a “?” over her — click), her notes about you. Written in the dialogue editor")
            PxToggle {
                checked: Config.novel.enabled
                onToggled: c => Config.novel.enabled = c
            }
        }
        SettingRow {
            visible: Config.novel.enabled
            label: I18n.t("Сейчас", "Now")
            hint: {
                const s = Novel.state;
                const st = Novel.stories[s.chapter];
                if (!Object.keys(Novel.stories).length)
                    return I18n.t("глав нет — открой редактор", "No chapters yet — open the editor");
                if (!s.chapter)
                    return I18n.t("ещё не началась: первая глава ждёт выхода компьютера из сна (или «Начать сейчас»)", "Not started: the first chapter waits for the computer to wake from sleep (or “Start now”)");
                return (st ? st.title || s.chapter : s.chapter) + (s.main.node ? " · " + s.main.node + (s.main.wait ? " (" + s.main.wait.replace(/^at:\d+/, I18n.t("ждёт времени", "waits for its time")) + ")" : "") : (s.done[s.chapter] ? I18n.t(" · главная линия пройдена", " · main line done") : "")) + (s.free ? I18n.t(" · вопросы и записки приходят сами", " · questions and notes come by themselves") : "");
            }
            Flow {
                width: parent.width
                spacing: Theme.u * 2
                PxButton {
                    compact: true
                    accent: true
                    icon: "document"
                    text: I18n.t("Редактор диалогов", "Dialogue editor")
                    onClicked: Novel.edit()
                }
                PxButton {
                    compact: true
                    icon: "folder"
                    text: I18n.t("Папка", "Folder")
                    onClicked: Shell.openPath(Novel.dir)
                }
                PxButton {
                    compact: true
                    icon: "play"
                    text: I18n.t("Начать сейчас", "Start now")
                    onClicked: {
                        Novel.reload();
                        startLater.restart();
                    }
                    Timer {
                        id: startLater
                        interval: 600
                        onTriggered: Novel.startChapter(Novel.state.chapter || Object.keys(Novel.stories).sort()[0] || "")
                    }
                }
                PxButton {
                    compact: true
                    icon: "chat"
                    text: I18n.t("Вопрос сейчас", "A question now")
                    onClicked: Novel.forceQuestion()
                }
                PxButton {
                    compact: true
                    flat: true
                    icon: "refresh"
                    text: I18n.t("С самого начала", "From the very start")
                    onClicked: Novel.reset()
                }
            }
        }
        SettingRow {
            visible: Config.novel.enabled
            label: I18n.t("Кто ты", "Who you are")
            hint: I18n.t("как ангел к тебе обращается (хотел / хотела). Она всё равно однажды спросит сама", "How the angel addresses you. She still asks one day herself")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Парень", "A guy"),
                        "value": "m"
                    },
                    {
                        "label": I18n.t("Девушка", "A girl"),
                        "value": "f"
                    },
                    {
                        "label": I18n.t("Не указывать", "Rather not say"),
                        "value": ""
                    }
                ]
                currentValue: Config.novel.gender || ""
                onActivated: v => Config.novel.gender = v
            }
        }
        SettingRow {
            visible: Config.novel.enabled
            label: I18n.t("Как тебя зовут", "Your name")
            hint: I18n.t("для {name} в репликах; пусто — имя пользователя", "For {name} in her lines; empty — your login name")
            PxField {
                width: Math.min(parent.width, Theme.u * 120)
                text: Config.novel.name || ""
                placeholder: StartApps.userName
                onEdited: Config.novel.name = text.trim()
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Стрим-режим", "Stream mode")
        advanced: true
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
            hint: Angel.hellShown ? I18n.t("ни блёсток, ни загрузочного экрана, ни лучей и трещин на экранах в эфире", "No sparkles, loading screen, rays or cracks on streamed screens") : I18n.t("ни блёсток, ни загрузочного экрана, ни лучей на экранах в эфире", "No sparkles, loading screen or rays on streamed screens")
            PxToggle {
                checked: Config.stream.effects
                onToggled: c => Config.stream.effects = c
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Блёстки", "Glitter")
        advanced: true
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
        advanced: true
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
            label: Angel.hellShown ? I18n.t("Голос ангела и демоницы", "The angel's and the demon's voice") : I18n.t("Голос ангела", "The angel's voice")
            hint: Angel.hellShown ? I18n.t("её «пип» на каждую букву, «хех», хор, трещины и камни — доля от общей громкости", "Her pip on every letter, the “heh”, the choir, cracks and rocks — a share of the volume above") : I18n.t("её «пип» на каждую букву, «хех» и хор — доля от общей громкости", "Her pip on every letter, the “heh” and the choir — a share of the volume above")
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
        SettingRow {
            label: I18n.t("Каждый звук отдельно", "Every sound on its own")
            hint: I18n.t("вкл/выкл, громкость и свой звук у каждого: клики, клавиши, окна, столы, блокировка", "On/off, volume and a sound of your own for each: clicks, keys, windows, desks, the lock")
            PxButton {
                text: I18n.t("Звуки системы →", "System sounds →")
                icon: "bell"
                onClicked: Shell.settingsPage = "sfx"
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Загрузочный экран", "Loading screen")
        advanced: true
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
