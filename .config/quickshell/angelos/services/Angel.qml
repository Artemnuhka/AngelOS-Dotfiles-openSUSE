pragma Singleton

import QtQuick
import Quickshell
import qs.config

// The Y2K helper angel (modules/y2k/AngelHelper): what she says and when.
// say() shows a bubble; tips come on a timer (Settings → Y2K → how often),
// and a few shell events get a reaction.
Singleton {
    id: root

    property string text: ""
    property var action: null                // {label, run} button in the bubble
    property bool talking: false
    property bool menuOpen: false
    property double hiddenUntil: 0
    property double now: Date.now()
    readonly property bool shown: Config.y2k.helper && now >= hiddenUntil
    property double lastReaction: 0

    function say(msg, act, ms) {
        if (!shown)
            return;
        text = msg;
        action = act || null;
        menuOpen = false;
        talking = true;
        quiet.interval = ms || Math.max(5000, msg.length * 75);
        quiet.restart();
        Sounds.play("angel");
    }
    // reactions to events stay rare: one per two minutes
    function react(msg, act) {
        if (Date.now() - lastReaction < 120000 || talking)
            return;
        lastReaction = Date.now();
        say(msg, act);
    }
    function hush() {
        talking = false;
        menuOpen = false;
    }
    function hide(minutes) {
        hush();
        hiddenUntil = Date.now() + minutes * 60000;
    }
    function tip() {
        const t = tips[Math.floor(Math.random() * tips.length)];
        say(t.text, t.page ? {
            "label": I18n.t("Покажи", "Show me"),
            "run": () => Shell.openSettings(t.page)
        } : null);
    }

    readonly property var tips: [
        {
            "text": I18n.t("В настройках можно искать своими словами: «сделать крупнее», «звук потише»… Попробуй!", "You can search settings in your own words: “bigger”, “quieter”… Try it!"),
            "page": "home"
        },
        {
            "text": I18n.t("ПКМ по рабочему столу → Вид — там живут виджеты: часы, музыка, cava ♡", "Right-click the desktop → View: that's where widgets live ♡"),
            "page": "widgets"
        },
        {
            "text": I18n.t("Виджеты можно увеличить: зажми Ctrl и покрути колёсико над ними.", "Widgets grow: hold Ctrl and scroll over one."),
            "page": "widgets"
        },
        {
            "text": I18n.t("Хочешь, чтобы обои менялись красиво? Там есть сердечко, телевизор и даже плавление, как в DOOM!", "Want a fancy wallpaper change? There's a heart, an old TV and even a DOOM melt!"),
            "page": "wallpaper"
        },
        {
            "text": I18n.t("Win+Shift+S — скриншот области, он сразу окажется в буфере.", "Win+Shift+S takes a region screenshot straight to the clipboard."),
            "page": "capture"
        },
        {
            "text": I18n.t("Любое сочетание клавиш можно поменять — даже для своих программ.", "Any shortcut can be changed, even for your own apps."),
            "page": "shortcuts"
        },
        {
            "text": I18n.t("Средняя кнопка мыши по окну на панели закрывает его, как вкладку в браузере.", "Middle-click a window on the taskbar to close it, like a browser tab."),
            "page": "windows"
        },
        {
            "text": I18n.t("Не забывай пить водичку и моргать ♡", "Remember to drink water and blink ♡"),
            "page": ""
        },
        {
            "text": I18n.t("Если что-то сломалось — в «Эксперт» есть всё-всё. Но я верю, что всё хорошо!", "If something breaks, Expert mode has everything. But I believe it's all fine!"),
            "page": ""
        }
    ]

    Timer {
        id: quiet
        onTriggered: root.talking = false
    }
    // the clock for "hide for an hour"
    Timer {
        interval: 30000
        running: root.hiddenUntil > root.now
        repeat: true
        onTriggered: root.now = Date.now()
    }
    Timer {
        interval: Config.y2k.helperTips === "often" ? 8 * 60000 : 30 * 60000
        running: root.shown && Config.y2k.helperTips !== "off"
        repeat: true
        onTriggered: if (!root.talking && !root.menuOpen)
            root.tip()
    }

    // ---- reactions ----
    Connections {
        target: Shell
        function onSettingsOpenChanged() {
            if (Shell.settingsOpen && Config.ready && !Config.y2k.helperGreeted) {
                Config.y2k.helperGreeted = true;
                root.say(I18n.t("Привет! Я Ангелочек ♡ Тут всё настраивается — начни с больших плиток, а сложное спрятано под «Эксперт».", "Hi! I'm Angel ♡ Everything is set up here — start with the big tiles; advanced things hide behind “Expert”."));
            }
        }
    }
    Connections {
        target: Notifs
        function onArrived(info) {
            if (info.appName === "Screenshot" && /сохран|saved/i.test(info.summary))
                root.react(I18n.t("Щёлк! Скриншот уже в буфере — вставляй куда хочешь ♡", "Click! The screenshot is on the clipboard ♡"));
            else if (info.critical)
                root.react(I18n.t("Ой… Что-то важное — посмотри уведомление!", "Oh… something important — check the notification!"));
        }
    }
    readonly property string wallpaperKey: JSON.stringify([Config.wallpaper.fallback, Config.wallpaper.outputs])
    onWallpaperKeyChanged: if (Config.ready && Date.now() - startedAt > 10000)
        react(I18n.t("Новые обои? Мне очень нравится!", "New wallpaper? I love it!"))
    readonly property double startedAt: Date.now()
}
