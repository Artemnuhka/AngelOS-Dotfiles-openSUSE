pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets
import "../y2k/AngelSpriteMini.js" as AngelMini

FloatingWindow {
    id: root
    title: Shell.appTitle + " · " + I18n.t("Добро пожаловать", "Welcome")
    visible: Shell.setupOpen
    color: "transparent"
    implicitWidth: 920
    implicitHeight: 720
    minimumSize: Qt.size(720, 500)
    property int step: 0
    Connections {
        target: Shell
        function onSetupStepRequested(step) {
            root.step = Math.max(0, Math.min(root.last, step));
        }
    }
    property bool offered: false
    // only what is really needed on day one; everything else lives in Settings
    readonly property var stepList: [
        {
            "label": I18n.t("Привет", "Welcome"),
            "kind": "welcome"
        },
        // one of the player's first choices: how Settings lay out (Config.settingsUi.view)
        {
            "label": I18n.t("Настройки", "Settings"),
            "kind": "settingsLook"
        },
        {
            "label": I18n.t("Хоткеи", "Shortcuts"),
            "kind": "shortcuts"
        },
        {
            "label": I18n.t("Мониторы", "Monitors"),
            "kind": "page",
            "page": "pages/MonitorPage.qml"
        },
        {
            "label": I18n.t("Ввод", "Input"),
            "kind": "page",
            "page": "pages/KeyboardPage.qml"
        },
        {
            "label": I18n.t("Тема", "Theme"),
            "kind": "page",
            "page": "pages/AppearancePage.qml"
        },
        {
            "label": I18n.t("Движение", "Motion"),
            "kind": "motion"
        },
        {
            "label": I18n.t("Значки", "Icons"),
            "kind": "icons"
        },
        {
            "label": I18n.t("Шрифты", "Fonts"),
            "kind": "fonts"
        },
        {
            "label": I18n.t("Панель", "Bar"),
            "kind": "bar"
        },
        {
            "label": I18n.t("Окна", "Windows"),
            "kind": "page",
            "page": "pages/WindowsPage.qml"
        },
        {
            "label": I18n.t("Рабочий стол", "Desktop"),
            "kind": "desktop"
        },
        {
            "label": I18n.t("Приложения", "Apps"),
            "kind": "page",
            "page": "pages/DefaultsPage.qml"
        },
        {
            "label": I18n.t("Готово", "Finish"),
            "kind": "finish"
        }
    ]
    readonly property var steps: stepList.map(s => s.label)
    readonly property var cur: stepList[step] || stepList[0]
    readonly property int last: stepList.length - 1
    property bool tipsAfter: true
    function finishSetup() {
        Config.setup.complete = true;
        Shell.setupOpen = false;
        if (tipsAfter)
            tipsTimer.start();
    }
    Timer {
        id: tipsTimer
        interval: 700
        onTriggered: Tour.start()
    }
    onClosed: Shell.setupOpen = false
    onVisibleChanged: if (!visible)
        Shell.setupOpen = false
    Timer {
        interval: 1200
        running: Config.ready && !Config.setup.complete && !root.offered && !Shell.dev
        onTriggered: {
            root.offered = true;
            Shell.setupOpen = true;
        }
    }
    BackgroundEffect.blurRegion: Config.appearance.blur ? setupBlur : null
    Region {
        id: setupBlur
        item: setupFrame
    }
    PxWindow {
        id: setupFrame
        anchors.fill: parent
        anchors.rightMargin: Theme.u * 2
        anchors.bottomMargin: Theme.u * 2
        title: "angelOS · " + root.steps[root.step]
        icon: "heart"
        onCloseClicked: Shell.setupOpen = false
        onTitlePressed: root.startSystemMove()
        Column {
            id: header
            width: parent.width
            spacing: Theme.u * 4
            Row {
                spacing: Theme.u * 6
                Repeater {
                    model: root.steps
                    PxButton {
                        required property string modelData
                        required property int index
                        compact: true
                        text: (index + 1) + ""
                        checked: root.step === index
                        onClicked: root.step = index
                    }
                }
            }
            Rectangle {
                width: parent.width
                height: Theme.u
                color: Theme.menuBorder
            }
        }
        Loader {
            anchors.top: header.bottom
            anchors.topMargin: Theme.u * 4
            anchors.bottom: footer.top
            anchors.bottomMargin: Theme.u * 5
            anchors.left: parent.left
            anchors.right: parent.right
            sourceComponent: ({
                    "welcome": welcome,
                    "settingsLook": settingsLook,
                    "shortcuts": shortcuts,
                    "finish": finish,
                    "bar": barStep,
                    "fonts": fontsStep,
                    "motion": motionStep,
                    "icons": iconsStep,
                    "desktop": desktopStep
                })[root.cur.kind] || settingsStep
        }
        Row {
            id: footer
            anchors.bottom: parent.bottom
            spacing: Theme.u * 5
            PxButton {
                text: I18n.t("Назад", "Back")
                enabled: root.step > 0
                onClicked: root.step--
            }
            PxButton {
                text: root.step === root.last ? I18n.t("Начать работу", "Start using angelOS") : I18n.t("Далее", "Next")
                accent: true
                onClicked: {
                    if (root.step < root.last)
                        root.step++;
                    else
                        root.finishSetup();
                }
            }
            PxButton {
                text: I18n.t("Настроить позже", "Set up later")
                onClicked: {
                    Config.setup.complete = true;
                    Shell.setupOpen = false;
                }
            }
        }
    }
    // C4: how much moves — full, calm, or nothing (an optimisation mode)
    Component {
        id: motionStep
        PxPage {
            pageId: "setup"
            heading: I18n.t("Движение", "Motion")
            subtitle: I18n.t("Сколько всего движется на экране. Можно поменять в любой момент: Внешний вид → Движение или angelos motion.", "How much moves on screen. Change it any time: Appearance → Motion, or angelos motion.")
            Repeater {
                model: [
                    {
                        "value": "full",
                        "label": I18n.t("Полное", "Full"),
                        "hint": I18n.t("всё как задумано: переходы, эффекты, ад во всей красе", "Everything as designed: transitions, effects, hell in all its glory")
                    },
                    {
                        "value": "calm",
                        "label": I18n.t("Спокойное", "Calm"),
                        "hint": I18n.t("без вспышек, тряски экрана и резких звуков", "No flashes, screen shaking or sudden loud sounds")
                    },
                    {
                        "value": "off",
                        "label": I18n.t("Выключено", "Off"),
                        "hint": I18n.t("никаких анимаций — ни оболочки, ни niri, ни Ада; для слабых машин и тех, кого укачивает", "No animations at all — not the shell's, niri's or hell's; for slow machines and anyone motion makes queasy")
                    }
                ]
                SettingRow {
                    id: levelRow
                    required property var modelData
                    label: modelData.label
                    hint: modelData.hint
                    preview: "CircleFx"
                    PxButton {
                        accent: Motion.level === levelRow.modelData.value
                        icon: Motion.level === levelRow.modelData.value ? "heart" : "sparkle"
                        text: Motion.level === levelRow.modelData.value ? I18n.t("Выбрано", "Chosen") : I18n.t("Выбрать", "Choose")
                        onClicked: {
                            Motion.set(levelRow.modelData.value);
                            levelRow.show(levelRow.modelData.value, I18n.t("переход в круг", "into a circle"));
                        }
                    }
                }
            }
        }
    }
    // D3: the shell's icons in one of three pixel styles (the cards are their own preview)
    Component {
        id: iconsStep
        PxPage {
            pageId: "setup"
            heading: I18n.t("Значки", "Icons")
            subtitle: I18n.t("Каким пикселем нарисованы значки оболочки. Можно пропустить — останутся свои; поменять потом: Внешний вид → Значки.", "Which pixel draws the shell's icons. Skip it and ours stay; change it later: Appearance → Icons.")
            IconStyleCards {}
        }
    }
    Component {
        id: settingsStep
        Loader {
            source: root.cur.page || "pages/AppearancePage.qml"
        }
    }
    Component {
        id: welcome
        PxPage {
            pageId: "setup"
            heading: I18n.t("Твой angelOS", "Your angelOS")
            subtitle: I18n.t("Настрой оболочку под себя. Основная тема останется доступной, а мастер можно снова открыть в настройках внешнего вида.", "Make the shell your own. The original theme stays available, and you can reopen this wizard in Appearance settings.")
            AngelLogo {
                pixel: Theme.u * 2
                fontSize: Theme.sizeHuge
            }
            SettingRow {
                label: "Язык / Language"
                PxCombo {
                    model: [
                        {
                            label: "Русский",
                            value: "ru"
                        },
                        {
                            label: "English",
                            value: "en"
                        }
                    ]
                    currentValue: Config.appearance.language
                    onActivated: v => Config.appearance.language = v
                }
            }
            PxText {
                width: parent.width
                wrapMode: Text.Wrap
                text: I18n.t("Панель и рабочий стол запускаются на всех подключённых экранах. Параметры мониторов и ввода меняются только по твоему действию.", "The bar and desktop run on every connected display. Monitor and input settings change only when you edit them.")
            }
            // the game over the desktop, or plain dotfiles (Config.game.enabled; the
            // installer asks too: ANGELOS_GAME=0). No spoilers here: what it is, not what happens
            SettingRow {
                label: I18n.t("Как пользоваться?", "How do you want it?")
                hint: Config.game.enabled ? I18n.t("angelOS — это ещё и игра поверх рабочего стола: в углу живёт ангел, а что будет дальше, зависит от твоих выборов. Работать она не мешает. Выйти из игры можно в любой момент: angelos game off или Mod+Ctrl+Shift+Escape.", "angelOS is also a game played over your desktop: an angel lives in the corner, and what happens next depends on your choices. It never gets in the way of work. Leave the game any time: angelos game off or Mod+Ctrl+Shift+Escape.") : I18n.t("Обычные дотфайлы: панель, окна, темы и всё остальное — без ангела, демоницы, новеллы и ада. Включить игру потом: Система → Игра или angelos game on.", "Plain dotfiles: the bar, windows, themes and the rest — no angel, demon, novel or hell. Turn the game on later: System → The game, or angelos game on.")
                PxSegmented {
                    model: [
                        {
                            "label": I18n.t("С игрой", "With the game"),
                            "value": true
                        },
                        {
                            "label": I18n.t("Просто рабочий стол", "Just the desktop"),
                            "value": false
                        }
                    ]
                    currentValue: Config.game.enabled !== false
                    onActivated: v => Story.setEnabled(v)
                }
            }
            // for the angel's novel (services/Novel): how she speaks to you. Optional — she
            // asks herself one day anyway, and the story remembers what was said here
            SettingRow {
                label: I18n.t("Кто ты?", "Who are you?")
                hint: I18n.t("чтобы ангел правильно к тебе обращалась (хотел / хотела). Можно не указывать — она однажды спросит сама", "So the angel addresses you right. You can leave it — one day she asks herself")
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
                label: I18n.t("Как тебя зовут?", "Your name")
                hint: I18n.t("так ангел будет к тебе обращаться; пусто — имя пользователя", "What the angel calls you; empty — your login name")
                PxField {
                    width: Math.min(parent.width, Theme.u * 120)
                    text: Config.novel.name || ""
                    placeholder: StartApps.userName
                    onEdited: Config.novel.name = text.trim()
                }
            }
        }
    }
    // The angel asks how she should lay Settings out (DRAFT line — the story's texts are the
    // author's): the view cards with their drawings, the skin cards under them. Leaving the
    // step the first time keeps the pick as the player's first choice (settingsUi.viewPicked);
    // functionally it is the usual setting, Appearance → Settings look changes it any time.
    Component {
        id: settingsLook
        PxPage {
            pageId: "setup"
            id: lookPage
            heading: I18n.t("Как разложить настройки?", "How should Settings be laid out?")
            subtitle: I18n.t("Страницы везде одни и те же. Сменить можно когда угодно: Внешний вид → Вид настроек.", "The pages are the same in every view. Change it any time: Appearance → Settings look.")
            Component.onDestruction: if (!Config.settingsUi.viewPicked) {
                Config.settingsUi.viewPicked = Config.settingsUi.view;
                Story.record("wizard", "settingsView", Config.settingsUi.view);
            }
            // her question, in a bubble next to her (with the game on)
            Row {
                visible: Config.game.enabled
                spacing: Theme.u * 4
                PxIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    bitmap: AngelMini.up
                    pixel: Math.max(1, Theme.u * 2)
                    ink: Theme.dark ? Theme.text : Theme.edge
                    body: "#ffd9c7"
                    fill: Theme.accent
                    fill2: "#3a1a46"
                    fill3: Theme.dark ? "#ffe07a" : "#f5c542"
                    light: "#ffffff"
                    bad: "#d8203a"
                }
                PxBox {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(Theme.u * 260, lookPage.innerWidth - Theme.u * 56)
                    height: bubbleText.implicitHeight + Theme.u * 10
                    color: Theme.menuSurface
                    PxText {
                        id: bubbleText
                        x: Theme.u * 5
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - Theme.u * 10
                        wrapMode: Text.Wrap
                        // DRAFT (author's approval pending)
                        text: I18n.t("Я буду приходить сюда, когда понадобится что-то поменять. Как тебе удобнее, чтобы я раскладывала настройки?", "I'll come here whenever something needs changing. How would you like me to lay the settings out?")
                    }
                }
            }
            Flow {
                width: lookPage.innerWidth
                spacing: Theme.u * 4
                Repeater {
                    model: ["sidebar", "controlpanel", "properties", "tiles"]
                    SettingsViewCard {
                        required property string modelData
                        view: modelData
                        width: Math.min(Theme.u * 100, (lookPage.innerWidth - Theme.u * 12) / 4)
                    }
                }
            }
            PxText {
                text: I18n.t("И во что их одеть?", "And what should they wear?")
                kind: "title"
            }
            Flow {
                width: lookPage.innerWidth
                spacing: Theme.u * 4
                Repeater {
                    model: ["classic", "windose", "stream"]
                    SettingsSkinCard {
                        required property string modelData
                        skin: modelData
                        width: Math.min(Theme.u * 100, (lookPage.innerWidth - Theme.u * 12) / 3)
                    }
                }
            }
        }
    }
    Component {
        id: shortcuts
        PxPage {
            pageId: "setup"
            heading: I18n.t("Основные хоткеи", "Essential shortcuts")
            subtitle: I18n.t("Mod — клавиша Super / Windows. Полный список для текущего конфига: Mod+Shift+Escape.", "Mod is the Super / Windows key. Show your configuration's shortcut list with Mod+Shift+Escape.")
            Repeater {
                model: [["Mod+Space", I18n.t("Запуск приложений", "Launch applications")], ["Mod+S", I18n.t("Настройки", "Settings")], ["Mod+V", I18n.t("История буфера обмена", "Clipboard history")], ["Mod+Alt+L", I18n.t("Блокировка", "Lock screen")], ["Mod+Alt+Y", I18n.t("Показать или скрыть Lyrics", "Toggle lyrics")], ["Mod+Alt+T", I18n.t("Светлая / тёмная тема", "Light / dark theme")], ["Mod+Shift+Q", I18n.t("Меню питания", "Power menu")]]
                SettingRow {
                    required property var modelData
                    label: modelData[0]
                    PxText {
                        text: modelData[1]
                    }
                }
            }
        }
    }
    Component {
        id: finish
        PxPage {
            pageId: "setup"
            heading: I18n.t("Всё готово ♡", "You're ready ♡")
            PxCheck {
                text: I18n.t("Показать подсказки по интерфейсу после мастера", "Show interface tips after the wizard")
                checked: root.tipsAfter
                onToggled: c => root.tipsAfter = c
            }
            subtitle: I18n.t("Изменения уже сохранены. Настройки всегда доступны из меню angelOS или по Mod+S.", "Your changes are saved. Open Settings from the angelOS menu or press Mod+S at any time.")
            PxText {
                text: I18n.t("Тема: ", "Theme: ") + Theme.flavors[Config.appearance.flavor].name
            }
            PxText {
                text: I18n.t("Экраны: ", "Displays: ") + Shell.screens.map(s => s.name).join(", ")
            }
            PxText {
                width: parent.width
                wrapMode: Text.Wrap
                text: I18n.t("Для геометрии мониторов нажми «Сохранить в конфиг» на шаге «Мониторы», если менял её.", "If you changed monitor geometry, use Save to config on the Monitors step to keep it after login.")
            }
        }
    }

    Component {
        id: fontsStep
        PxPage {
            pageId: "setup"
            heading: I18n.t("Пиксельные шрифты", "Pixel fonts")
            subtitle: I18n.t("Выбери набор шрифтов. Недостающие скачаются с GitHub / Google Fonts (с проверкой SHA-256). Потом можно поменять в Настройки → Шрифты.", "Pick a font set. Missing fonts are downloaded from GitHub / Google Fonts and verified by SHA-256. Change it later in Settings → Fonts.")
            Component.onCompleted: Fonts.refresh()
            Repeater {
                model: Fonts.presets
                PxBox {
                    id: preset
                    required property var modelData
                    readonly property bool ready: modelData.needs.every(id => Fonts.installed(id))
                    readonly property bool current: Config.appearance.fontTitle === modelData.fonts[0] && Config.appearance.fontBody === modelData.fonts[1] && Config.appearance.fontMono === modelData.fonts[2]
                    width: parent.width
                    height: presetCol.implicitHeight + Theme.u * 10
                    color: current ? Theme.mix(Theme.face, Theme.accent, 0.18) : presetMouse.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.08) : Theme.face
                    Column {
                        id: presetCol
                        x: Theme.u * 5
                        y: Theme.u * 5
                        width: parent.width - Theme.u * 10
                        spacing: Theme.u * 2
                        Row {
                            spacing: Theme.u * 4
                            PxIcon {
                                name: preset.current ? "check" : "heart"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            PxText {
                                text: preset.modelData.label + (preset.ready ? "" : I18n.t("  · скачается при выборе", "  · downloads when picked"))
                                font.bold: true
                            }
                        }
                        Repeater {
                            model: [[0, 18, I18n.t("Заголовок ♡ angelOS", "Title ♡ angelOS")], [1, 13, I18n.t("Обычный текст: привет, мир!", "Body text: hello, world!")], [2, 13, "mono: 0123 ~/.config"]]
                            Text {
                                required property var modelData
                                readonly property string family: preset.modelData.fonts[modelData[0]] || [Theme.defaultTitleFont, Theme.defaultBodyFont, Theme.defaultMonoFont][modelData[0]]
                                visible: preset.ready
                                text: modelData[2]
                                color: Theme.text
                                font.family: family
                                font.pixelSize: Theme.fontPx(modelData[1], family)
                                renderType: Text.NativeRendering
                            }
                        }
                        PxText {
                            visible: !preset.ready
                            text: preset.modelData.fonts.filter((f, i, a) => f && a.indexOf(f) === i).join(" · ")
                            dim: true
                        }
                    }
                    MouseArea {
                        id: presetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !Fonts.busy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Fonts.applyPreset(preset.modelData)
                    }
                }
            }
            PxText {
                visible: Fonts.busy || Fonts.error !== ""
                width: parent.width
                wrapMode: Text.Wrap
                color: Fonts.error ? Theme.danger : Theme.accent
                text: Fonts.error || I18n.t("Скачиваю шрифт…", "Downloading font…")
            }
        }
    }
    Component {
        id: barStep
        PxPage {
            pageId: "setup"
            heading: I18n.t("Панель", "The bar")
            subtitle: I18n.t("Как выглядит панель. Раскладку элементов потом можно перетаскивать в Настройки → Панель.", "How the bar looks. Rearrange its items later in Settings → Bar.")
            PxGroup {
                title: I18n.t("Вид", "Look")
                icon: "window"
                width: parent.width
                SettingRow {
                    label: I18n.t("Стиль", "Style")
                    PxCombo {
                        width: Math.min(parent.width, Theme.u * 140)
                        model: [
                            {
                                "label": I18n.t("Таскбар", "Taskbar"),
                                "value": "taskbar"
                            },
                            {
                                "label": I18n.t("Полоса", "Strip"),
                                "value": "top"
                            },
                            {
                                "label": I18n.t("Остров", "Island"),
                                "value": "island"
                            },
                            {
                                "label": I18n.t("Док", "Dock"),
                                "value": "dock"
                            },
                            {
                                "label": I18n.t("Капсулы", "Capsules"),
                                "value": "capsules"
                            },
                            {
                                "label": "Windose",
                                "value": "windose"
                            }
                        ]
                        currentValue: Config.bar.style
                        onActivated: v => Config.bar.style = v
                    }
                }
                SettingRow {
                    label: I18n.t("Воркспейсы", "Workspaces")
                    PxSegmented {
                        model: [
                            {
                                "label": I18n.t("Сердечки", "Hearts"),
                                "value": "hearts",
                                "icon": "heart"
                            },
                            {
                                "label": I18n.t("Иконки", "Icons"),
                                "value": "icons",
                                "icon": "window"
                            },
                            {
                                "label": I18n.t("Оба", "Both"),
                                "value": "both"
                            }
                        ]
                        currentValue: Config.bar.workspaceStyle
                        onActivated: v => Config.bar.workspaceStyle = v
                    }
                }
                SettingRow {
                    label: I18n.t("Подписи окон", "Window titles")
                    PxToggle {
                        checked: Config.bar.taskLabels
                        onToggled: c => Config.bar.taskLabels = c
                    }
                }
                SettingRow {
                    label: I18n.t("Иконки трея под тему", "Tray icons in theme colors")
                    PxSegmented {
                        model: [
                            {
                                "label": I18n.t("Как есть", "As is"),
                                "value": "off"
                            },
                            {
                                "label": I18n.t("Моно", "Mono"),
                                "value": "mono"
                            },
                            {
                                "label": I18n.t("Акцент", "Accent"),
                                "value": "accent"
                            }
                        ]
                        currentValue: Config.bar.trayTint
                        onActivated: v => Config.bar.trayTint = v
                    }
                }
                SettingRow {
                    label: I18n.t("Лирика в центре панели", "Lyrics in the middle of the bar")
                    PxToggle {
                        checked: Config.lyrics.enabled
                        onToggled: c => Config.lyrics.enabled = c
                    }
                }
            }
            PxGroup {
                title: I18n.t("Логотип", "Logo")
                icon: "heart"
                width: parent.width
                Flow {
                    width: parent.width
                    spacing: Theme.u * 6
                    Repeater {
                        model: ["classic", "angel", "windose", "hell", "chrome"].filter(v => v !== "hell" || Angel.hellShown || (Config.bar.logoStyle === "hell" && Angel.hellAllowed))
                        PxButton {
                            required property string modelData
                            width: logoPreview.implicitWidth + Theme.u * 12
                            height: Math.max(Theme.u * 23, logoPreview.implicitHeight + Theme.u * 8)
                            checked: (Config.bar.logoStyle || "classic") === modelData
                            onClicked: Config.bar.logoStyle = modelData
                            AngelLogo {
                                id: logoPreview
                                anchors.centerIn: parent
                                variant: parent.modelData
                            }
                        }
                    }
                }
                Flow {
                    width: parent.width
                    spacing: Theme.u * 4
                    Repeater {
                        model: ["heart", "pill", "star", "cd", "kitty"]
                        PxButton {
                            required property string modelData
                            width: emblemPreview.implicitWidth + Theme.u * 10
                            height: emblemPreview.implicitHeight + Theme.u * 8
                            checked: (Config.bar.logoEmblem || "heart") === modelData
                            onClicked: Config.bar.logoEmblem = modelData
                            AngelLogo {
                                id: emblemPreview
                                anchors.centerIn: parent
                                emblemOnly: true
                                emblemName: parent.modelData
                            }
                        }
                    }
                }
                PxToggle {
                    text: I18n.t("Надпись на кнопке «Пуск» (выключи — останется только значок)", "Wordmark on the Start button (off leaves the emblem)")
                    checked: Config.bar.logoText !== false
                    onToggled: c => Config.bar.logoText = c
                }
            }
        }
    }
    Component {
        id: desktopStep
        PxPage {
            pageId: "setup"
            heading: I18n.t("Рабочий стол", "Desktop")
            subtitle: I18n.t("Виджеты на обоях — таскаются за заголовок, добавляются и убираются через ПКМ → Вид.", "Widgets on the wallpaper — drag them by the title, add or remove via right-click → View.")
            PxGroup {
                title: I18n.t("Виджеты на ", "Widgets on ") + Shell.primaryName
                icon: "layers"
                width: parent.width
                Repeater {
                    model: DesktopWidgets.types
                    PxCheck {
                        required property var modelData
                        text: modelData.label
                        checked: DesktopWidgets.has(modelData.type, Shell.primaryName)
                        onToggled: DesktopWidgets.toggle(modelData.type, Shell.primaryName)
                    }
                }
            }
            // the right-click menu on the wallpaper (Settings → Right-click menu has the rest)
            PxGroup {
                title: I18n.t("Меню по правой кнопке", "Right-click menu")
                icon: "grid"
                width: parent.width
                PxText {
                    width: parent.width
                    wrapMode: Text.Wrap
                    dim: true
                    text: I18n.t("Каким будет меню, если нажать правой кнопкой на обои. Потом его можно настроить до пункта: Настройки → ПКМ-меню.", "What a right click on the wallpaper opens. Every entry can be tuned later in Settings → Right-click menu.")
                }
                Flow {
                    width: parent.width
                    spacing: Theme.u * 4
                    Repeater {
                        model: ["list", "radial", "y2k", "tiles", "wings", "harp"]
                        PxButton {
                            id: menuCard
                            required property string modelData
                            width: menuThumb.implicitWidth + Theme.u * 8
                            height: menuThumb.implicitHeight + menuName.implicitHeight + Theme.u * 10
                            checked: DeskMenu.chosen === modelData
                            onClicked: Config.desktop.menuStyle = modelData
                            MenuStyleThumb {
                                id: menuThumb
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: Theme.u * 4
                                style: menuCard.modelData
                            }
                            PxText {
                                id: menuName
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: Theme.u * 3
                                kind: "tiny"
                                font.bold: menuCard.checked
                                text: (menuCard.checked ? "♡ " : "") + DeskMenu.styleLabel(menuCard.modelData)
                            }
                        }
                    }
                }
                PxButton {
                    compact: true
                    icon: "sparkle"
                    text: I18n.t("Попробовать", "Try it")
                    onClicked: {
                        const sc = Shell.focusedScreen;
                        const m = sc ? Shell.desktopMenus[sc.name] : null;
                        if (m)
                            Qt.callLater(() => m.openAt(Math.round(sc.width / 2), Math.round(sc.height / 2)));
                    }
                }
            }
            PxGroup {
                title: I18n.t("Голосовой ввод", "Voice typing")
                icon: "mic"
                width: parent.width
                SettingRow {
                    label: I18n.t("Индикатор VoxType", "VoxType indicator")
                    PxSegmented {
                        model: [
                            {
                                "label": "angelOS",
                                "value": "angelos"
                            },
                            {
                                "label": I18n.t("Старый", "Classic"),
                                "value": "classic"
                            },
                            {
                                "label": I18n.t("Нет", "Off"),
                                "value": "off"
                            }
                        ]
                        currentValue: Config.voxtype.indicator
                        onActivated: v => Config.voxtype.indicator = v
                    }
                }
            }
        }
    }

    RightClickGuard {}
}
