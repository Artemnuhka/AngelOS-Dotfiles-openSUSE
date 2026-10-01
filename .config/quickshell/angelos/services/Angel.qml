pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "AngelLines.js" as Lines

// The Y2K helper in the screen corner (modules/y2k/AngelHelper): what she says
// and who she is.
//   angel   tips on a timer (Settings → Y2K), a tip the first time a settings
//           page opens, jokes, answers in the "Ask" menu (settings search).
//   demon   the user grabbed the angel and threw her down into hell: dark
//           wallpaper, cheeky jokes, a cracked screen corner, and now and then
//           a prank that flips a real setting — with "Undo" and "Where's
//           that?" buttons, so every prank shows off a feature. She leaves
//           after three lucky pleas ("Ask" → "Bring the angel back", 35 %,
//           counted once per 10 minutes) within two hours; the angel then
//           undoes the pranks and gives the wallpaper back.
// Effects: heaven() — sun rays and a choir (HeavenRays), punched() — the
// demon's broken glass (ScreenCracks), quake() — the swap shakes the screen
// (ScreenQuake). The demon arrives: shake with her 8-bit rocks, then the screen
// breaks and her cracks appear. The angel returns: the demon's glass breaks and
// falls out (shattered()), then the screen shakes — no rocks, they are hers. Nothing of it on
// streamed screens. The owner (Owner.enabled) can send the demon away at once,
// for debugging: her menu, or `angelos helper angel`.
Singleton {
    id: root

    // ---- who and where ----
    readonly property bool demon: Config.y2k.character === "demon"
    // the main screen, her own one (Y2K → Screen; unplugged → the main one), or where the focus is
    readonly property var screen: StreamMode.angelScreen(Config.y2k.helperScreen === "focus" ? Shell.focusedScreen : Shell.screenByName(Config.y2k.helperScreen) || Shell.primaryScreen)
    readonly property string screenName: screen ? screen.name : ""

    property string text: ""
    property var actions: []                 // [{label, icon, run}]: buttons in the bubble
    property bool talking: false
    property bool menuOpen: false
    property string menuMode: "main"         // main | ask
    property double hiddenUntil: 0
    property double now: Date.now()
    readonly property bool shown: Config.y2k.helper && now >= hiddenUntil && !!screen
    readonly property bool present: shown && !Shell.bootOpen && Config.ready
    property double lastReaction: 0

    // the swap animation: angel falls into hell and the demon climbs out, or back
    property string transition: ""           // "" | toHell | ascend
    property real swap: 0                    // 0..1 through it; the character flips at 0.5
    // the desktop widgets wait for the glass to break before they burn over (DesktopWidgets)
    property bool holdWidgets: false
    signal heaven(string screenName)
    signal punched(string screenName, string sound)
    signal shattered(string screenName)
    signal quake(string screenName, string kind)
    signal devDrag(real dx, real dy, int ms)   // dev: AngelHelper replays a real drag (tests)

    function tr(pair) {
        return I18n.t(pair[0], pair[1]);
    }
    // random, but not the same line twice in a row
    property var _last: ({})
    function pick(list, key) {
        if (!list || !list.length)
            return "";
        let i = Math.floor(Math.random() * list.length);
        if (list.length > 1 && i === _last[key])
            i = (i + 1) % list.length;
        _last[key] = i;
        return list[i];
    }

    function say(msg, acts, ms, silent) {
        if (!shown || !msg)
            return;
        text = msg;
        actions = !acts ? [] : Array.isArray(acts) ? acts : [acts];
        menuOpen = false;
        talking = true;
        quiet.interval = ms || Math.max(6000, msg.length * 80);
        quiet.restart();
        if (!silent)
            Sounds.play(demon ? "demon" : "angel");
    }
    // reactions to events stay rare: one per two minutes
    function react(msg, act, silent) {
        if (Date.now() - lastReaction < 120000 || talking || transition)
            return;
        lastReaction = Date.now();
        say(msg, act, 0, silent);
    }
    function hush() {
        talking = false;
        menuOpen = false;
        menuMode = "main";
    }
    function hide(minutes) {
        hush();
        hiddenUntil = Date.now() + minutes * 60000;
    }
    function openMenu(mode) {
        talking = false;
        menuMode = mode || "main";
        menuOpen = true;
        if (menuMode === "ask")
            SettingsSearch.load();
        Sounds.play(demon ? "demon" : "angel");
    }
    function showMe(page) {
        return {
            "label": I18n.t("Покажи", "Show me"),
            "icon": "heart",
            "run": () => Shell.openSettings(page)
        };
    }

    function tip() {
        const t = pick(demon ? Lines.demonTips : Lines.tips, demon ? "dtip" : "tip");
        say(I18n.t(t[0], t[1]), t[2] ? showMe(t[2]) : null);
    }
    function joke() {
        const list = demon ? (I18n.english ? Lines.demonJokesEn : Lines.demonJokesRu) : (I18n.english ? Lines.jokesEn : Lines.jokesRu);
        say(pick(list, "joke" + demon), {
            "label": I18n.t("Ещё!", "Another!"),
            "icon": "star",
            "run": () => root.joke()
        });
    }
    // the timer: a tip, or now and then a joke; the demon drops hints how to get rid of her
    function chatter() {
        if (demon && Math.random() < 0.45)
            hint();
        else if (Config.y2k.jokes && Math.random() < 0.4)
            joke();
        else
            tip();
    }
    // the demon hints how the angel comes back, with the button right there
    property double lastHint: 0
    function hint() {
        if (!demon)
            return;
        lastHint = Date.now();
        say(tr(pick(Lines.demon.hints, "hint")).replace("%1", pleasCounted).replace("%2", pleasNeeded), {
            "label": I18n.t("Верни ангела", "Bring the angel back"),
            "icon": "heart",
            "run": () => root.plea()
        });
    }

    // "Ask": a few words she understands, then the settings search
    function answer(q) {
        const s = String(q || "").trim().toLowerCase();
        if (!s)
            return;
        const L = demon ? Lines.demon : Lines.angel;
        if (/шут|анекдот|смеш|рассмеш|joke|funny|laugh/.test(s))
            return joke();
        if (/^(привет|здравств|хай|хей|ку\b|добр|hello|hi\b|hey|yo\b)/.test(s))
            return say(tr(L.hello));
        if (/как дела|как ты|как жизнь|how are you|what'?s up|sup\b/.test(s))
            return say(tr(L.how));
        if (/кто ты|ты кто|who are you|what are you/.test(s))
            return say(tr(L.who));
        if (/люблю|love you|i love/.test(s))
            return say(tr(L.love));
        if (/спасиб|благодар|thank/.test(s))
            return say(tr(L.thanks));
        if (demon && /вернись|верни|ангел|уйди|уходи|come back|angel|go away|leave/.test(s))
            return plea();
        if (!demon && /(^|\s)ад(\s|$)|демон|hell|demon/.test(s))
            return say(tr(Lines.angel.hell));
        if (/совет|подсказ|помоги|помощь|help|tip|advice/.test(s))
            return tip();
        // the questions people ask most, answered straight
        for (const it of intents)
            if (it.re.test(s))
                return say(I18n.t(it.ru, it.en), showMe(it.page));
        const r = searchLoose(q);
        if (r && r.length) {
            const best = r[0];
            return say(tr(Lines.angel.found).replace("%1", best.crumb ? best.title + " (" + best.crumb + ")" : best.title), {
                "label": I18n.t("Покажи", "Show me"),
                "icon": "heart",
                "run": () => root.showResult(best)
            });
        }
        const list = demon ? (I18n.english ? Lines.demonJokesEn : Lines.demonJokesRu) : (I18n.english ? Lines.jokesEn : Lines.jokesRu);
        say(tr(Lines.angel.notFound) + " " + pick(list, "joke" + demon));
    }
    readonly property var intents: [
        {
            "re": /крупн|больше|мельч|мелк|масштаб|bigger|larger|smaller|zoom|scale/,
            "page": "home",
            "ru": "Всё делается крупнее или мельче кнопками «Крупнее» и «Мельче» на главной настроек.",
            "en": "Make everything bigger or smaller with “Bigger” and “Smaller” on the settings home."
        },
        {
            "re": /обо(и|ев|ям)|картинк|фон |wallpaper|background/,
            "page": "wallpaper",
            "ru": "Обои — на странице «Обои»: кликни картинку, и она на столе.",
            "en": "Wallpapers are on the Wallpaper page: click a picture and it's on."
        },
        {
            "re": /звук|громк|тише|громче|микрофон|volume|sound|louder|quieter|microphone/,
            "page": "sound",
            "ru": "Громкость, колонки и микрофон — на странице «Звук».",
            "en": "Volume, speakers and the microphone are on the Sound page."
        },
        {
            "re": /тёмн|темн|светл|тема|dark|light mode|theme/,
            "page": "appearance",
            "ru": "Светлая или тёмная тема — «Внешний вид», или просто Mod+Alt+T.",
            "en": "Light or dark theme: Appearance, or just Mod+Alt+T."
        },
        {
            "re": /горяч|сочетан|клавиш|хоткей|shortcut|hotkey|keybind/,
            "page": "shortcuts",
            "ru": "Все сочетания клавиш — на странице «Горячие клавиши», любое можно поменять.",
            "en": "Every shortcut is on the Shortcuts page, and any of them can be changed."
        }
    ]
    // whole questions first, then without the filler words, then word by word
    readonly property var filler: ["как", "где", "что", "мне", "мои", "мой", "моя", "я", "можно", "сделать", "поменять", "изменить", "хочу", "чтобы", "это", "эту", "этот", "в", "на", "и", "а", "с", "по", "у", "the", "a", "an", "how", "do", "does", "i", "can", "to", "make", "change", "my", "is", "are", "where", "what", "want", "please", "set", "turn"]
    function searchLoose(q) {
        if (!SettingsSearch.loaded)
            return [];
        let r = SettingsSearch.search(q, 3);
        if (r.length)
            return r;
        const words = String(q).toLowerCase().replace(/[?!.,«»"“”]/g, " ").split(/\s+/).filter(w => w && !filler.includes(w));
        if (!words.length)
            return [];
        r = SettingsSearch.search(words.join(" "), 3);
        if (r.length)
            return r;
        for (const w of words.slice().sort((a, b) => b.length - a.length)) {
            r = SettingsSearch.search(w, 3);
            if (r.length)
                return r;
        }
        return [];
    }
    // open Settings on a search result and flash it (SettingsView.openResult)
    property var _result: null
    property int _tries: 0
    function showResult(r) {
        Shell.openSettings(r.page);
        _result = r;
        _tries = 0;
        resultTimer.restart();
    }
    Timer {
        id: resultTimer
        interval: 120
        repeat: true
        onTriggered: {
            if (Shell.settingsView) {
                Shell.settingsView.openResult(root._result);
                stop();
            } else if (++root._tries > 20)
                stop();
        }
    }

    // ---- angel → hell: no button, she is grabbed and thrown down ----
    // AngelHelper drags her sprite; dropping her deep enough (or flinging her
    // down) sends her through the floor. The demon can't be thrown anywhere.
    property bool thrown: false              // the fall starts where she was dropped
    property real throwX: 0
    property real throwY: 0
    function grabbed() {
        say(tr(pick(demon ? Lines.demon.grab : Lines.angel.grab, "grab" + demon)), null, 2600);
    }
    function released(deep, x, y) {
        if (demon) {
            say(tr(Lines.demon.drop));
            return;
        }
        if (!deep) {
            say(tr(Lines.angel.phew));
            return;
        }
        thrown = true;
        throwX = x;
        throwY = y;
        toHell();
    }
    function toHell() {
        if (demon || transition)
            return;
        hush();
        startSwap("toHell");
    }
    function becomeDemon() {
        Config.y2k.character = "demon";
        Config.y2k.demonSince = Date.now();
        Config.y2k.pleas = [];
        Config.y2k.lastPlea = 0;
        Config.y2k.pranks = [];
        Config.y2k.nextPrank = Date.now() + (6 + Math.random() * 4) * 60000;
        hellLook(true);
    }

    // ---- demon → angel: three lucky pleas in two hours ----
    readonly property int pleaCooldown: 10 * 60000
    readonly property int pleaWindow: 2 * 3600000
    readonly property real pleaChance: 0.35
    readonly property int pleasNeeded: 3
    readonly property int pleasCounted: (Config.y2k.pleas || []).filter(t => now - t < pleaWindow).length
    function plea() {
        if (!demon || transition)
            return;
        const t = Date.now();
        const since = t - (Config.y2k.lastPlea || 0);
        if (since < pleaCooldown)
            return say(tr(pick(since < 60000 ? Lines.demon.spam.slice(1) : Lines.demon.spam, "spam")).replace("%1", Math.round(since / 60000)));
        Config.y2k.lastPlea = t;
        const all = Config.y2k.pleas || [];
        const fresh = all.filter(x => t - x < pleaWindow);
        const stale = fresh.length < all.length ? tr(Lines.demon.expired) + " " : "";
        if (Math.random() >= pleaChance) {
            Config.y2k.pleas = fresh;
            return say(stale + tr(pick(Lines.demon.no, "no")));
        }
        const got = fresh.concat([t]);
        Config.y2k.pleas = got;
        if (got.length >= pleasNeeded)
            return ascend();
        say(stale + tr(got.length === 1 ? Lines.demon.yes1 : Lines.demon.yes2));
    }
    function ascend() {
        if (!demon || transition)
            return;
        say(tr(Lines.demon.leave), null, 2600);
        leave.restart();
    }
    // Settings → Y2K → "Call the angel" (and `angelos helper summon`): she comes
    // now — switched on and not hidden; if the demon rules, she leaves (a line,
    // then the same swap as the pleas). Returns what happened.
    function summon() {
        if (transition)
            return "busy";
        if (!Config.y2k.helper)
            Config.y2k.helper = true;
        hiddenUntil = 0;
        now = Date.now();
        if (!screen)
            return "hidden";               // stream mode keeps her off every screen
        if (demon) {
            say(tr(Lines.demon.summoned), null, 2600);
            leave.restart();
            return "ascend";
        }
        lastReaction = Date.now();
        say(tr(pick(Lines.angel.summoned, "summoned")));
        return "ok";
    }
    // the owner debugging: no begging, she goes right away
    function ownerAngel() {
        if (!Owner.enabled || !demon || transition)
            return false;
        hush();
        startSwap("ascend");
        return true;
    }
    Timer {
        id: leave
        interval: 2600
        onTriggered: {
            root.hush();
            root.startSwap("ascend");
        }
    }
    property int _undone: 0
    function becomeAngel() {
        _undone = undoAllPranks();
        Config.y2k.character = "angel";
        Config.y2k.pleas = [];
        Config.y2k.pranks = [];
        hellLook(false);
    }

    // ---- the swap animation, stepped like the sprite (AngelHelper draws it) ----
    function startSwap(kind) {
        holdWidgets = true;
        transition = kind;
        swap = 0;
        swapTick.restart();
    }
    Timer {
        id: swapTick
        interval: 80
        repeat: true
        onTriggered: {
            const before = root.swap;
            root.swap = Math.min(1, root.swap + interval / 1900);
            if (before < 0.5 && root.swap >= 0.5) {
                if (root.transition === "toHell")
                    root.becomeDemon();
                else
                    root.becomeAngel();       // her glass stays until the quake breaks it
            }
            if (root.swap >= 1) {
                stop();
                const kind = root.transition;
                root.transition = "";
                root.thrown = false;
                // the new one has arrived: the screen shakes, then it breaks
                if (kind === "toHell") {
                    root.shake("hell", () => {
                        root.breakScreen();
                        root.say(root.tr(Lines.demon.intro), {
                            "label": I18n.t("Как её вернуть?", "How do I get her back?"),
                            "icon": "chat",
                            "run": () => root.say(root.tr(Lines.demonTips[3]))
                        }, 16000);
                        hellNews.restart();
                    });
                } else {
                    root.breakScreen();
                    afterGlass.restart();
                }
            }
        }
    }
    // after her intro: what hell did to the right-click menu and Settings (Y2K → Angel or demon)
    Timer {
        id: hellNews
        interval: 16500
        onTriggered: {
            if (!root.demon)
                return;
            const style = DeskMenu.styleLabel(DeskMenu.style).toLowerCase();
            const parts = [];
            if (DeskMenu.hellish)
                parts.push(I18n.t("ПКМ по обоям теперь — " + style, "right-click on the wallpaper is a " + style + " now"));
            if (Config.y2k.hellSettings === "grimoire")
                parts.push(I18n.t("настройки — мой гримуар", "Settings are my grimoire"));
            const mine = [];
            if (Config.y2k.hellWidgets && DesktopWidgets.widgets.length)
                mine.push(I18n.t("виджеты", "the widgets"));
            if (Cursors.hellOn)
                mine.push(I18n.t("курсор", "the cursor"));
            if (mine.length) {
                const one = mine.length === 1 && !(Config.y2k.hellWidgets && DesktopWidgets.widgets.length);   // just the cursor
                parts.push(mine.join(I18n.t(" и ", " and ")) + (one ? I18n.t(" — тоже мой", " is mine too") : I18n.t(" — тоже мои", " are mine too")));
            }
            if (!parts.length)
                return;
            const what = parts.length > 1 ? parts.slice(0, -1).join(", ") + I18n.t(", а ", ", and ") + parts[parts.length - 1] : parts[0];
            root.say(I18n.t("И да: ", "Oh, and ") + what + I18n.t(" 😈 Вернётся ангел — вернётся и твоё.", " 😈 When the angel's back, so is yours."), {
                "label": I18n.t("Где это?", "Where is it?"),
                "icon": "gear",
                "run": () => Shell.openSettings("y2k")
            }, 12000);
        }
    }
    // sun rays for the angel, broken glass for the demon — when she shows up. `arriving`:
    // she appears with the shell (every start, login, restart): the rays and the choir
    // only the very first time (Config.y2k.raysSeen), the demon's cracks come back silently
    function effect(arriving) {
        if (!fxHere())
            return;
        if (demon) {
            if (Config.y2k.cracks !== "off")
                punched(screenName, arriving ? "" : "crack");
        } else if (Config.y2k.heavenFx && !(arriving && Config.y2k.raysSeen)) {
            if (arriving)
                Config.y2k.raysSeen = true;
            heaven(screenName);
        }
    }
    function fxHere() {
        return !!screenName && StreamMode.effectsOn(screenName) && !Shell.fullscreenOn(screenName);
    }
    // ---- the swap's end: quake, then the screen breaks ----
    property var _afterQuake: null
    function shake(kind, then) {
        if (!Config.y2k.shake || !fxHere()) {
            then();
            return;
        }
        _afterQuake = then;
        quakeGuard.restart();
        quake(screenName, kind);
    }
    // ScreenQuake is done (or could not shake at all)
    function quakeDone() {
        quakeGuard.stop();
        const then = _afterQuake;
        _afterQuake = null;
        if (then)
            then();
    }
    Timer {
        id: quakeGuard
        interval: 2500
        onTriggered: root.quakeDone()
    }
    function breakScreen() {
        holdWidgets = false;
        if (!fxHere())
            return;
        Sounds.play("shatter");
        if (!demon)
            shattered(screenName);
        else if (Config.y2k.cracks !== "off")
            punched(screenName, "");
    }
    Timer {
        id: heavenSoon
        interval: 450
        onTriggered: root.effect()
    }
    // the angel is back: her glass has fallen out (ScreenCracks, 450 ms), now the shake
    Timer {
        id: afterGlass
        interval: 480
        onTriggered: root.shake("heaven", () => {
            heavenSoon.restart();
            root.say(root.tr(root._undone ? Lines.angel.back : Lines.angel.backClean));
        })
    }
    onPresentChanged: if (present && !transition)
        appear.restart()
    // she moved (the main screen changed, a monitor came or went): her cracks come along, silently
    onScreenNameChanged: if (demon && present && !transition && screenName)
        moved.restart()
    property string _crackedOn: ""            // where her cracks were put last
    onPunched: name => _crackedOn = name
    Timer {
        id: moved
        interval: 300
        onTriggered: if (root.demon && !appear.running && root._crackedOn && root._crackedOn !== root.screenName && root.fxHere() && Config.y2k.cracks !== "off")
            root.punched(root.screenName, "")
    }
    Timer {
        id: appear
        interval: 700
        onTriggered: root.effect(true)
    }

    // ---- the demon's wallpaper: dark while she rules, yours with the angel ----
    function hellLook(on) {
        if (on) {
            if (!Config.y2k.hellWallpaper || Config.y2k.angelSaved)
                return;
            Config.y2k.angelSaved = {
                "fallback": Config.wallpaper.fallback,
                "outputs": Config.wallpaper.outputs,
                "workspaces": Config.wallpaper.workspaces,
                "mode": Config.appearance.mode
            };
            Config.appearance.mode = "dark";
            putHell();
            return;
        }
        const s = Config.y2k.angelSaved;
        if (!s)
            return;
        Sounds.quietWallpaper(4000);
        Config.wallpaper.fallback = s.fallback || "";
        Config.wallpaper.outputs = s.outputs || ({});
        Config.wallpaper.workspaces = s.workspaces || ({});
        if (s.mode)
            Config.appearance.mode = s.mode;
        Config.y2k.angelSaved = null;
    }
    // the hell picture itself: your own (Y2K → hell picture), or a painting from the
    // Hell pack / the drawn hell (scripts/hell-wallpaper.py) sized for every screen
    function putHell() {
        Sounds.quietWallpaper(4000);
        if (Config.y2k.hellPicture) {
            Wallpapers.setEverywhere(Config.y2k.hellPicture);
            return;
        }
        const sizes = [];
        for (const s of Shell.screens) {
            const k = Math.round(s.width * (s.devicePixelRatio || 1)) + "x" + Math.round(s.height * (s.devicePixelRatio || 1));
            if (!sizes.includes(k))
                sizes.push(k);
        }
        hellGen.command = ["python3", Quickshell.shellDir + "/scripts/hell-wallpaper.py", Config.home + "/.local/share/angelos/hell", "--pack", Config.home + "/Pictures/Hell", "--cache", Config.home + "/.local/share/angelos/hell-pack"].concat(Config.y2k.hellStyle === "drawn" ? ["--drawn"] : []).concat(sizes);
        hellGen.running = true;
    }
    Process {
        id: hellGen
        stdout: StdioCollector {
            onStreamFinished: {
                let files = {};
                try {
                    files = JSON.parse(text).files || {};
                } catch (e) {
                    return;
                }
                const outputs = {};
                let first = "";
                for (const s of Shell.screens) {
                    const k = Math.round(s.width * (s.devicePixelRatio || 1)) + "x" + Math.round(s.height * (s.devicePixelRatio || 1));
                    if (files[k]) {
                        outputs[s.name] = files[k];
                        first = first || files[k];
                    }
                }
                if (!first || !root.demon)
                    return;
                Sounds.quietWallpaper(4000);
                Config.wallpaper.workspaces = ({});
                Config.wallpaper.outputs = outputs;
                Config.wallpaper.fallback = first;
            }
        }
    }
    // switching the dark wallpaper off gives yours back right away
    Connections {
        target: Config.y2k
        function onHellWallpaperChanged() {
            if (root.demon && !root.transition)
                root.hellLook(Config.y2k.hellWallpaper);
        }
        // paintings ↔ drawn hell: a new picture right away
        function onHellStyleChanged() {
            root.newHell();
        }
    }
    // another hell picture now (the style changed; `angelos helper hellwall`)
    function newHell() {
        if (!demon || transition || !Config.y2k.hellWallpaper || !Config.y2k.angelSaved)
            return false;
        putHell();
        return true;
    }

    // ---- pranks: a real setting flips, the bubble says what it is ----
    function getPath(path) {
        const [a, b] = path.split(".");
        const v = Config[a][b];
        return v !== null && typeof v === "object" ? JSON.parse(JSON.stringify(v)) : v;
    }
    function setPath(path, v) {
        const [a, b] = path.split(".");
        Config[a][b] = v;
    }
    readonly property var osuPlugin: Plugins.enabledPlugins.find(p => p.id === "osu-mini") || null
    readonly property var pranks: [
        {
            "id": "switchFx",
            "run": () => {
                const old = WorkspaceAnim.current.id;
                WorkspaceAnim.pick("heart");
                return old;
            },
            "undo": old => WorkspaceAnim.pick(old || "soft"),
            "can": () => WorkspaceAnim.current.id !== "heart" && !Shell.dev,
            "page": "workspaces",
            "ru": "Переключи рабочий стол. Сюрприз: он теперь открывается сердечком, фу. Это «Анимация переключения» в «Воркспейсах».",
            "en": "Switch a workspace. Surprise: it opens through a heart now, ew. That's “Switch animation” in Workspaces."
        },
        {
            "id": "heartAnim",
            "key": "workspaces.heartAnim",
            "value": () => "drop",
            "can": () => Config.workspaces.heartAnim !== "drop",
            "page": "workspaces",
            "ru": "Сердечки на панели теперь падают, как ты в моих глазах. Анимация сердечек — в «Воркспейсах».",
            "en": "The hearts on the bar drop now, like you in my eyes. The heart animation is in Workspaces."
        },
        {
            "id": "startLabel",
            "key": "bar.startLabel",
            "value": () => "hellOS",
            "can": () => Config.bar.startLabel !== "hellOS",
            "page": "bar",
            "ru": "Посмотри на «Пуск». Теперь это hellOS. Надпись меняется в «Панели», если что.",
            "en": "Look at Start. It's hellOS now. The label is in the Bar settings, if you care."
        },
        {
            "id": "startStyle",
            "key": "bar.startStyle",
            "value": () => Config.bar.startStyle === "fullscreen" ? "win11" : "fullscreen",
            "page": "bar",
            "ru": "Открой «Пуск». Сюрприз! У него три вида, выбирается в «Панели».",
            "en": "Open Start. Surprise! It has three styles, pick one in Bar settings."
        },
        {
            "id": "barStyle",
            "key": "bar.style",
            "value": () => Config.bar.style === "island" ? "top" : "island",
            "page": "bar",
            "ru": "Я переставила тебе панель. Бывает снизу, сверху и островом — всё в «Панели».",
            "en": "I moved your bar. It can live at the bottom, on top or as an island — see Bar settings."
        },
        {
            "id": "px",
            "key": "appearance.px",
            "value": () => Math.min(4, Config.appearance.px + 1),
            "can": () => Config.appearance.px < 4,
            "page": "home",
            "ru": "Всё стало большим? Это я. Кнопки «Крупнее» и «Мельче» — на главной настроек.",
            "en": "Everything got bigger? That's me. “Bigger” and “Smaller” are on the settings home."
        },
        {
            "id": "light",
            "key": "appearance.mode",
            "value": () => "light",
            "can": () => Theme.dark,
            "page": "appearance",
            "ru": "Ослепила? Светлая тема! Обратно — Mod+Alt+T или «Внешний вид».",
            "en": "Blinded? Light theme! Back with Mod+Alt+T or in Appearance."
        },
        {
            "id": "taskLabels",
            "key": "bar.taskLabels",
            "value": () => !Config.bar.taskLabels,
            "page": "bar",
            "ru": "Кнопки окон на панели поменяла: подписи или только иконки — выбирается в «Панели».",
            "en": "I changed the window buttons: titles or icons only, it's in Bar settings."
        },
        {
            "id": "sparkles",
            "key": "y2k.sparkles",
            "value": () => true,
            "can": () => !Config.y2k.sparkles,
            "page": "y2k",
            "ru": "Поводи мышкой по рабочему столу. Блёстки — чтобы ты помнил, кто тут главная.",
            "en": "Move the mouse over the desktop. Glitter, so you remember who's in charge."
        },
        {
            "id": "wsName",
            "key": "workspaces.names",
            "value": () => {
                const ws = Niri.activeWorkspace(root.screenName);
                const m = Object.assign({}, Config.workspaces.names || {});
                if (ws)
                    m[ws.output + ":" + ws.idx] = I18n.t("прокрастинация", "procrastination");
                return m;
            },
            "can": () => !!Niri.activeWorkspace(root.screenName),
            "page": "workspaces",
            "ru": "Я подписала твой рабочий стол правдой. Имена столов меняются в «Воркспейсах».",
            "en": "I named your workspace honestly. Workspace names are in Workspaces."
        },
        {
            "id": "clock",
            "run": () => {
                DesktopWidgets.toggle("clock", root.screenName);
                return root.screenName;
            },
            "undo": name => {
                const w = DesktopWidgets.widgets.find(x => x.type === "clock" && x.screen === name);
                if (w)
                    DesktopWidgets.remove(w.uid);
            },
            "can": () => !DesktopWidgets.widgets.some(w => w.type === "clock"),
            "page": "widgets",
            "ru": "Повесила тебе часы на стол. Чтобы видел, сколько времени ты тратишь на меня. Виджеты — ПКМ по столу → Вид.",
            "en": "I hung a clock on your desktop, so you see how much time you waste on me. Widgets: right-click the desktop → View."
        },
        {
            "id": "idle",
            "run": () => Idle.start(),
            "page": "lock",
            "ru": "Заставка! Можно включать самой по времени — «Блокировка и заставка». Любая клавиша — и она уйдёт.",
            "en": "Screensaver! It can start on a timer — Lock and idle. Any key sends it away."
        },
        {
            "id": "osu",
            "run": () => Shell.gameOpen = true,
            "can": () => !!root.osuPlugin,
            "page": "plugins",
            "ru": "Сыграем в osu!? Проиграешь — останусь навсегда. Это плагин, их тут много.",
            "en": "Let's play osu!. Lose and I stay forever. It's a plugin; there are more."
        }
    ]
    function prank() {
        if (!demon || transition || !present || talking || menuOpen || Shell.locked || Idle.active || StreamMode.active || Shell.settingsOpen || Shell.fullscreenOn(screenName)) {
            Config.y2k.nextPrank = Date.now() + 5 * 60000;
            return false;
        }
        const done = (Config.y2k.pranks || []).map(p => p.id);
        const options = pranks.filter(p => !done.includes(p.id) && (!p.can || p.can()));
        Config.y2k.nextPrank = Date.now() + (25 + Math.random() * 20) * 60000;
        if (!options.length) {
            joke();
            return false;
        }
        const p = options[Math.floor(Math.random() * options.length)];
        const rec = {
            "id": p.id,
            "at": Date.now()
        };
        if (p.key) {
            rec.key = p.key;
            rec.old = getPath(p.key);
            rec.new = p.value();
            setPath(p.key, rec.new);
        } else {
            const r = p.run();
            if (p.undo)
                rec.old = r === undefined ? null : r;
        }
        Config.y2k.pranks = (Config.y2k.pranks || []).concat([rec]);
        effect();
        const acts = [];
        if (p.key || p.undo)
            acts.push({
                "label": I18n.t("Верни!", "Undo!"),
                "icon": "refresh",
                "run": () => root.undoPrank(p.id, true)
            });
        if (p.page)
            acts.push({
                "label": I18n.t("Где это?", "Where's that?"),
                "icon": "gear",
                "run": () => Shell.openSettings(p.page)
            });
        say(I18n.t(p.ru, p.en), acts, 22000);
        return true;
    }
    function undoPrank(id, speak) {
        const list = Config.y2k.pranks || [];
        const rec = list.find(r => r.id === id && !r.undone);
        if (!rec)
            return false;
        const p = pranks.find(x => x.id === id);
        // a setting the user changed again since is theirs now
        if (rec.key && JSON.stringify(getPath(rec.key)) === JSON.stringify(rec.new))
            setPath(rec.key, rec.old);
        else if (!rec.key && p && p.undo)
            p.undo(rec.old);
        Config.y2k.pranks = list.map(r => r === rec ? Object.assign({}, r, {
                "undone": true
            }) : r);
        if (speak)
            say(tr(Lines.demon.undo));
        return true;
    }
    function undoAllPranks() {
        let n = 0;
        for (const r of (Config.y2k.pranks || []).slice().reverse())
            if (!r.undone && (r.key || (pranks.find(p => p.id === r.id) || {}).undo) && undoPrank(r.id, false))
                n++;
        return n;
    }

    Timer {
        id: quiet
        onTriggered: root.talking = false
    }
    // the clock: "hide for an hour", plea counters, the demon's schedule
    Timer {
        interval: 30000
        running: Config.y2k.helper
        repeat: true
        onTriggered: {
            root.now = Date.now();
            if (root.demon && root.now > (Config.y2k.nextPrank || 0))
                root.prank();
            // and every twelve minutes or so she hints how to get the angel back
            else if (root.demon && root.present && !root.talking && !root.menuOpen && !root.transition && Config.y2k.helperTips !== "off" && !StreamMode.active && !Shell.hiddenScreen(root.screenName) && root.now - (Config.y2k.demonSince || 0) > 120000 && root.now - root.lastHint > 12 * 60000)
                root.hint();
            const h = new Date().getHours();
            if (!root.demon && h >= 1 && h < 5 && root.nightSaid !== new Date().toDateString() && !Shell.fullscreenOn(root.screenName)) {
                root.nightSaid = new Date().toDateString();
                root.react(root.tr(Lines.angel.night));
            }
        }
    }
    property string nightSaid: ""
    Timer {
        interval: Config.y2k.helperTips === "often" ? 6 * 60000 : 20 * 60000
        running: root.present && Config.y2k.helperTips !== "off"
        repeat: true
        onTriggered: if (!root.talking && !root.menuOpen && !root.transition && !Shell.hiddenScreen(root.screenName))
            root.chatter()
    }

    // ---- reactions ----
    Connections {
        target: Shell
        function onSettingsOpenChanged() {
            if (Shell.settingsOpen && Config.ready && !Config.y2k.helperGreeted) {
                Config.y2k.helperGreeted = true;
                root.say(I18n.t("Привет! Я Ангелочек ♡ Тут всё настраивается — начни с больших плиток, а сложное спрятано под «Эксперт».", "Hi! I'm Angel ♡ Everything is set up here — start with the big tiles; advanced things hide behind “Expert”."));
            } else if (Shell.settingsOpen)
                pageTip.restart();
        }
        function onSettingsPageChanged() {
            if (Shell.settingsOpen)
                pageTip.restart();
        }
    }
    // the first visit of a settings page gets its own tip — the angel's, or the demon's
    // own take on it (counted apart: "demon:<page>")
    Timer {
        id: pageTip
        interval: 1500
        onTriggered: {
            const page = Shell.settingsPage;
            const t = (root.demon ? Lines.demonPageTips : Lines.pageTips)[page];
            const key = (root.demon ? "demon:" : "") + page;
            const seen = Config.y2k.seenTips || [];
            if (!t || !Shell.settingsOpen || seen.includes(key) || root.talking || root.transition)
                return;
            Config.y2k.seenTips = seen.concat([key]);
            root.say(root.tr(t));
        }
    }
    Connections {
        target: Notifs
        function onArrived(info) {
            if (Notifs.isScreenshot(info))
                root.react(root.demon ? I18n.t("Щёлк. Компромат сохранён.", "Click. Blackmail material saved.") : I18n.t("Щёлк! Скриншот уже в буфере — вставляй куда хочешь ♡", "Click! The screenshot is on the clipboard ♡"), null, true);
            else if (info.critical)
                root.react(root.demon ? I18n.t("О, что-то горит. Люблю, когда горит.", "Oh, something's on fire. I love it when things burn.") : I18n.t("Ой… Что-то важное — посмотри уведомление!", "Oh… something important — check the notification!"));
        }
    }
    readonly property string wallpaperKey: JSON.stringify([Config.wallpaper.fallback, Config.wallpaper.outputs])
    onWallpaperKeyChanged: if (Config.ready && Date.now() - startedAt > 10000 && !transition && Date.now() > Sounds.wallpaperQuietUntil)
        react(demon ? I18n.t("Опять светленькое? Фу.", "Something bright again? Ew.") : I18n.t("Новые обои? Мне очень нравится!", "New wallpaper? I love it!"), null, true)
    readonly property double startedAt: Date.now()
}
