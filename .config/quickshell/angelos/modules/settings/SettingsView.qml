pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Settings content (frame, sidebar, pages). Hosted by SettingsWindow.
// Laid out like macOS's System Settings: the sidebar always there — search on top, your
// account card, then the sections in runs a line apart, each with its coloured tile; the
// page on the right under a toolbar with ◀ ▶ (history) and where you are (Sound › System
// sounds › Clicks). A section opens its first page; its other pages and the advanced
// groups of a page are its sub-pages, listed as "Title ›" links at the page's top (PxPage)
// — Shell.settingsSub is the advanced group open on its own. Windose and Stream are the
// same sections in their own clothes; while the demon rules it is her grimoire.
Item {
    id: win

    Component.onCompleted: {
        lastLoc = loc;
        Shell.settingsView = win;
        Theme.scriptWindow = scriptHost;
        if (typeof SettingsSearch.reload === "function")
            SettingsSearch.reload();
        else
            SettingsSearch.load();
        SettingsKeys.load();
    }
    Component.onDestruction: {
        if (Shell.settingsView === win)
            Shell.settingsView = null;
        if (Theme.scriptWindow === win.Window.window)
            Theme.scriptWindow = null;
    }
    function diagnostics() {
        return {
            page: Shell.settingsPage,
            sub: Shell.settingsSub,
            section: sectionOf(Shell.settingsPage),
            source: String(page.source),
            status: page.status,
            sidebarVisible: sidebar.visible,
            settingsSkin: page.item && page.item.settingsSkin !== undefined ? page.item.settingsSkin : "",
            plugin: page.item && page.item.loadedPlugin !== undefined ? page.item.loadedPlugin : ""
        };
    }
    property var hostWindow: null
    readonly property alias frame: frame
    readonly property var pageItem: page.item
    // while the demon rules (Y2K → Angel or demon → Settings in hell): a grimoire (GrimoireBook)
    readonly property bool grimoire: Angel.demon && Config.y2k.hellSettings === "grimoire"
    // …written by hand: every PxText in this window takes the grimoire's script (Theme.fontScript)
    readonly property var scriptHost: grimoire ? win.Window.window : null
    onScriptHostChanged: Theme.scriptWindow = scriptHost
    // Classic stays the default; Windose and Stream are optional settings layouts.
    readonly property string skin: ["classic", "windose", "stream"].includes(Config.settingsUi.skin) ? Config.settingsUi.skin : "classic"
    readonly property string settingsSkin: grimoire ? "classic" : skin
    // (there is no simple view or Expert any more: every page is a click away in the sidebar)
    readonly property bool expert: true

    // ---- every page, by id: titles, the page loader, the search's crumbs ----
    readonly property var pageList: [
        {
            "id": "account",
            "label": I18n.t("Аккаунт", "Account"),
            "icon": "heart"
        },
        {
            "id": "network",
            "label": I18n.t("Wi-Fi и сеть", "Wi-Fi and network"),
            "icon": "wifi"
        },
        {
            "id": "bluetooth",
            "label": "Bluetooth",
            "icon": "bluetooth"
        },
        {
            "id": "notifications",
            "label": I18n.t("Уведомления", "Notifications"),
            "icon": "bell"
        },
        {
            "id": "sound",
            "label": I18n.t("Звук", "Sound"),
            "icon": "speaker"
        },
        {
            "id": "sfx",
            "label": I18n.t("Звуки системы", "System sounds"),
            "icon": "bell"
        },
        {
            "id": "appearance",
            "label": I18n.t("Внешний вид", "Appearance"),
            "icon": "palette"
        },
        {
            "id": "fonts",
            "label": I18n.t("Шрифты", "Fonts"),
            "icon": "document"
        },
        {
            "id": "cursor",
            "label": I18n.t("Курсор", "Cursor"),
            "icon": "cursor"
        },
        {
            "id": "wallpaper",
            "label": I18n.t("Обои", "Wallpaper"),
            "icon": "image"
        },
        {
            "id": "widgets",
            "label": I18n.t("Виджеты", "Widgets"),
            "icon": "layers"
        },
        {
            "id": "deskmenu",
            "label": I18n.t("ПКМ-меню", "Right-click menu"),
            "icon": "grid"
        },
        {
            "id": "bar",
            "label": I18n.t("Панель и «Пуск»", "Bar and Start"),
            "icon": "window"
        },
        {
            "id": "lyrics",
            "label": I18n.t("Лирика", "Lyrics"),
            "icon": "mic"
        },
        {
            "id": "y2k",
            "label": Angel.demon ? I18n.t("Демоница ⛧", "The demon ⛧") : I18n.t("Ангелочек ✧", "The angel ✧"),
            "icon": Angel.demon ? "pentagram" : "sparkle"
        },
        {
            "id": "monitor",
            "label": I18n.t("Экран", "Display"),
            "icon": "monitor"
        },
        {
            "id": "windows",
            "label": I18n.t("Окна", "Windows"),
            "icon": "window"
        },
        {
            "id": "workspaces",
            "label": I18n.t("Воркспейсы", "Workspaces"),
            "icon": "layers"
        },
        {
            "id": "keyboard",
            "label": I18n.t("Клавиатура", "Keyboard"),
            "icon": "keyboard"
        },
        {
            "id": "shortcuts",
            "label": I18n.t("Горячие клавиши", "Shortcuts"),
            "icon": "keyboard"
        },
        {
            "id": "mouse",
            "label": I18n.t("Мышь и лупа", "Mouse and lens"),
            "icon": "mouse"
        },
        {
            "id": "gamepad",
            "label": I18n.t("Геймпад", "Gamepad"),
            "icon": "gamepad"
        },
        {
            "id": "lock",
            "label": I18n.t("Блокировка и заставка", "Lock and idle"),
            "icon": "lock"
        },
        {
            "id": "capture",
            "label": I18n.t("Скриншоты и запись", "Screenshots and recording"),
            "icon": "camera"
        },
        {
            "id": "defaults",
            "label": I18n.t("Приложения по умолчанию", "Default apps"),
            "icon": "star"
        },
        {
            "id": "plugins",
            "label": I18n.t("Плагины", "Plugins"),
            "icon": "plug"
        },
        {
            "id": "studio",
            "label": I18n.t("Мастер плагинов", "Plugin Studio"),
            "icon": "sparkle",
            "developer": true
        },
        {
            "id": "updates",
            "label": I18n.t("Обновления", "Updates"),
            "icon": "download"
        },
        {
            "id": "dotfiles",
            "label": "Dotfiles",
            "icon": "package",
            "owner": true
        },
        {
            "id": "system",
            "label": I18n.t("Система", "System"),
            "icon": "chip"
        }
    ].concat(Plugins.settingsPages.map(p => ({
                "id": "plugin:" + p.id,
                "label": I18n.label(p.name),
                "icon": p.icon || "plug"
            })))
    function pageEntry(id) {
        return pageList.find(p => p.id === id) || null;
    }
    function labelOf(id) {
        const p = pageEntry(id);
        return p ? p.label : id;
    }
    // owner-only pages vanish in the public version, Plugin Studio is for developers
    function pageShown(id) {
        const p = pageEntry(id);
        return !!p && (!p.owner || Owner.enabled) && (!p.developer || Config.developer.enabled);
    }

    // ---- the sidebar: the account card, then the sections in runs ----
    readonly property string nightPage: Plugins.settingsPages.some(p => p.id === "nightlight") ? "plugin:nightlight" : ""
    readonly property var runs: [
        {
            "title": I18n.t("Связь", "Connections"),
            "sections": [
                {
                    "id": "network",
                    "label": I18n.t("Wi-Fi и сеть", "Wi-Fi and network"),
                    "icon": "wifi",
                    "tint": "#3a86ff",
                    "pages": ["network"]
                },
                {
                    "id": "bluetooth",
                    "label": "Bluetooth",
                    "icon": "bluetooth",
                    "tint": "#2f62d6",
                    "pages": ["bluetooth"]
                }
            ]
        },
        {
            "title": I18n.t("Уведомления и звук", "Notifications and sound"),
            "sections": [
                {
                    "id": "notifications",
                    "label": I18n.t("Уведомления", "Notifications"),
                    "icon": "bell",
                    "tint": "#e8404f",
                    "pages": ["notifications"]
                },
                {
                    "id": "sound",
                    "label": I18n.t("Звук", "Sound"),
                    "icon": "speaker",
                    "tint": "#e94f96",
                    "pages": ["sound", "sfx"]
                }
            ]
        },
        {
            "title": I18n.t("Вид", "Look"),
            "sections": [
                {
                    "id": "appearance",
                    "label": I18n.t("Внешний вид", "Appearance"),
                    "icon": "palette",
                    "tint": "#6b5bd6",
                    "pages": ["appearance", "fonts", "cursor"]
                },
                {
                    "id": "wallpaper",
                    "label": I18n.t("Обои и стол", "Wallpaper and desktop"),
                    "icon": "image",
                    "tint": "#1fa7bd",
                    "pages": ["wallpaper", "widgets", "deskmenu"]
                },
                {
                    "id": "bar",
                    "label": I18n.t("Панель и «Пуск»", "Bar and Start"),
                    "icon": "window",
                    "tint": "#565e6b",
                    "pages": ["bar"]
                },
                {
                    "id": "lyrics",
                    "label": I18n.t("Лирика", "Lyrics"),
                    "icon": "mic",
                    "tint": "#b04cc8",
                    "pages": ["lyrics"]
                },
                {
                    "id": "y2k",
                    "label": Angel.demon ? I18n.t("Демоница ⛧", "The demon ⛧") : I18n.t("Ангелочек ✧", "The angel ✧"),
                    "icon": Angel.demon ? "pentagram" : "sparkle",
                    "tint": Angel.demon ? "#b3142b" : "#f06aa8",
                    "pages": ["y2k"]
                }
            ]
        },
        {
            "title": I18n.t("Устройства", "Devices"),
            "sections": [
                {
                    "id": "monitor",
                    "label": I18n.t("Экран", "Display"),
                    "icon": "monitor",
                    "tint": "#2f7de8",
                    "pages": ["monitor"].concat(win.nightPage ? [win.nightPage] : [])
                },
                {
                    "id": "windows",
                    "label": I18n.t("Окна и столы", "Windows and desks"),
                    "icon": "layers",
                    "tint": "#13a596",
                    "pages": ["windows", "workspaces"]
                },
                {
                    "id": "keyboard",
                    "label": I18n.t("Клавиатура", "Keyboard"),
                    "icon": "keyboard",
                    "tint": "#7b818c",
                    "pages": ["keyboard", "shortcuts"]
                },
                {
                    "id": "mouse",
                    "label": I18n.t("Мышь и геймпад", "Mouse and gamepad"),
                    "icon": "mouse",
                    "tint": "#6a717c",
                    "pages": ["mouse", "gamepad"]
                },
                {
                    "id": "lock",
                    "label": I18n.t("Блокировка и заставка", "Lock and idle"),
                    "icon": "lock",
                    "tint": "#e8930b",
                    "pages": ["lock"]
                },
                {
                    "id": "capture",
                    "label": I18n.t("Скриншоты и запись", "Screenshots and recording"),
                    "icon": "camera",
                    "tint": "#ef6c1a",
                    "pages": ["capture"]
                }
            ]
        },
        {
            "title": I18n.t("Система", "System"),
            "sections": [
                {
                    "id": "defaults",
                    "label": I18n.t("Приложения", "Apps"),
                    "icon": "star",
                    "tint": "#5b6b80",
                    "pages": ["defaults"]
                },
                {
                    "id": "plugins",
                    "label": I18n.t("Плагины", "Plugins"),
                    "icon": "plug",
                    "tint": "#1fae55",
                    "pages": ["plugins", "studio"].concat(Plugins.settingsPages.map(p => "plugin:" + p.id).filter(id => id !== win.nightPage))
                },
                {
                    "id": "updates",
                    "label": I18n.t("Обновления", "Updates"),
                    "icon": "download",
                    "tint": "#0e95d6",
                    "pages": ["updates", "dotfiles"]
                },
                {
                    "id": "system",
                    "label": I18n.t("Система", "System"),
                    "icon": "chip",
                    "tint": "#5f6672",
                    "pages": ["system"]
                }
            ]
        }
    ]
    // what the sidebar shows: pages the user may see, sections with something left
    readonly property var visibleRuns: runs.map(r => ({
                "title": r.title,
                "sections": r.sections.map(s => Object.assign({}, s, {
                        "pages": s.pages.filter(id => win.pageShown(id))
                    })).filter(s => s.pages.length > 0)
            })).filter(r => r.sections.length > 0)
    readonly property var visibleSections: visibleRuns.reduce((a, r) => a.concat(r.sections), [])
    // the same as groups of sections (the grimoire's contents, Windose and Stream's home)
    readonly property var visibleGroups: visibleRuns.map(r => ({
                "title": r.title,
                "pages": r.sections.map(s => ({
                        "id": s.pages[0],
                        "label": s.label,
                        "icon": s.icon
                    }))
            }))
    readonly property var allPages: [pageEntry("account")].concat(visibleSections.reduce((a, s) => a.concat(s.pages.map(id => win.pageEntry(id))), [])).filter(p => !!p)
    readonly property string currentId: Shell.settingsPage === "home" || Shell.settingsPage === "more" ? "account" : Shell.settingsPage
    readonly property var currentPage: allPages.find(p => p.id === currentId) || null
    function sectionFor(id) {
        return visibleSections.find(s => s.pages.includes(id)) || null;
    }
    function sectionOf(id) {
        if (id === "home" || id === "more" || id === "account")
            return "account";
        const s = sectionFor(id);
        return s ? s.id : "";
    }
    function tintOf(id) {
        const s = sectionFor(id);
        return s ? s.tint : Theme.accent;
    }
    // the section's first page for its other pages ("‹ Sound" on System sounds)
    function parentOf(id) {
        const s = sectionFor(id);
        return s && s.pages[0] !== id ? s.pages[0] : "";
    }
    // a section's first page lists the others as links
    function subpagesOf(id) {
        const s = sectionFor(id);
        return s && s.pages[0] === id ? s.pages.slice(1).map(p => win.pageEntry(p)).filter(p => !!p) : [];
    }
    function openSection(s) {
        Shell.settingsPage = s.pages[0];
        Shell.settingsSub = "";
    }

    // ---- history: ◀ ▶ like a browser (a page and its sub-page) ----
    property var backStack: []
    property var forwardStack: []
    property string lastLoc: ""             // set once at start, then by recordLoc (no binding)
    property bool travelling: false
    readonly property string loc: Shell.settingsPage + "|" + Shell.settingsSub
    onLocChanged: Qt.callLater(recordLoc)
    function recordLoc() {
        if (loc === lastLoc)
            return;
        if (!travelling) {
            backStack = backStack.filter(l => l !== loc).concat([lastLoc]).slice(-30);
            forwardStack = [];
            // how often each page is opened: the account page's "Everyday" follows it
            if (Config.ready && Shell.settingsOpen && Shell.settingsSub === "" && Shell.settingsPage !== "home" && Shell.settingsPage !== "more") {
                const u = Object.assign({}, Config.settingsUi.usage || {});
                u[Shell.settingsPage] = (u[Shell.settingsPage] || 0) + 1;
                Config.settingsUi.usage = u;
            }
        }
        travelling = false;
        lastLoc = loc;
    }
    Connections {
        target: Shell
        function onSettingsOpenChanged() {
            if (!Shell.settingsOpen) {
                win.backStack = [];
                win.forwardStack = [];
            }
        }
    }
    function goLoc(l) {
        const [p, sub] = l.split("|");
        travelling = true;
        Shell.settingsPage = p;
        Shell.settingsSub = sub || "";
        Qt.callLater(recordLoc);
    }
    readonly property bool canBack: backStack.length > 0
    readonly property bool canForward: forwardStack.length > 0
    readonly property string backTarget: canBack ? backStack[backStack.length - 1].split("|")[0] : "account"
    readonly property string backLabel: labelOf(backTarget)
    function back() {
        recordLoc();
        if (!canBack)
            return;
        const b = backStack.slice();
        const target = b.pop();
        backStack = b;
        forwardStack = forwardStack.concat([loc]);
        goLoc(target);
    }
    function forward() {
        recordLoc();
        if (!canForward)
            return;
        const f = forwardStack.slice();
        const target = f.pop();
        forwardStack = f;
        backStack = backStack.concat([loc]);
        goLoc(target);
    }
    // where you are, for the toolbar: Section › Page › Sub-page
    readonly property var crumbs: {
        const out = [];
        const s = sectionFor(currentId);
        if (currentId === "account")
            out.push(labelOf("account"));
        else if (s) {
            out.push(s.label);
            if (s.pages[0] !== currentId)
                out.push(labelOf(currentId));
        } else
            out.push(labelOf(currentId));
        if (Shell.settingsSub)
            out.push(Shell.settingsSub);
        return out;
    }

    // ---- search (services/SettingsSearch) ----
    property string query: ""
    property int sel: 0
    property var results: []
    onQueryChanged: {
        if (!query.trim())
            results = [];
        searchTimer.restart();
    }
    // one frame: keys typed together are searched once (a search takes ~1 ms)
    Timer {
        id: searchTimer
        interval: 16
        onTriggered: win.results = win.query.trim() ? SettingsSearch.search(win.query, 14) : []
    }
    Connections {
        target: SettingsSearch
        function onDocsChanged() {
            if (win.query.trim())
                searchTimer.restart();
        }
    }
    readonly property string ghost: query ? SettingsSearch.complete(query) : ""
    property var pendingTarget: null
    Binding {
        target: SettingsSearch
        property: "pageInfo"
        value: {
            const m = {};
            for (const p of win.allPages) {
                const s = win.sectionFor(p.id);
                m[p.id] = {
                    "label": s && s.pages[0] !== p.id ? s.label + " › " + p.label : p.label,
                    "icon": p.icon
                };
            }
            return m;
        }
    }
    // `angelos settingsQuery "…"`: type into the search box (scripts, previews)
    function setQuery(t) {
        search.text = t;
        query = t;
        sel = 0;
        search.focusField();
    }
    function acceptGhost() {
        if (!ghost)
            return false;
        search.text = query + ghost;
        query = search.text;
        sel = 0;
        return true;
    }
    function openResult(r) {
        if (!r)
            return;
        pendingTarget = r.kind === "page" ? null : r;
        query = "";
        search.text = "";
        if (Shell.settingsPage === r.page)
            targetTimer.restart();
        else
            Shell.settingsPage = r.page;
        if (r.kind === "page")
            Shell.settingsSub = "";
    }
    // the found setting: on the page (a visible one) or anywhere in it (`any`)
    function findItem(item, r, any) {
        if (!item || (!any && !item.visible))
            return null;
        if (r.kind === "row" && item.label === r.target && item.hint !== undefined)
            return item;
        if (r.kind === "group" && item.title === r.target && item.spacing !== undefined)
            return item;
        for (const c of item.children) {
            const f = findItem(c, r, any);
            if (f)
                return f;
        }
        return null;
    }
    function groupOf(item) {
        for (let p = item; p; p = p.parent)
            if (p.advanced !== undefined && p.title !== undefined)
                return p;
        return null;
    }
    // scroll the page to the found setting and flash it; one in a sub-page opens it first
    function showTarget() {
        const r = pendingTarget;
        pendingTarget = null;
        const pg = page.item;
        if (!r || !pg || !pg.flick)
            return;
        const groupHint = {
            "kind": "group",
            "target": String(r.crumb).split(" › ").slice(-1)[0] || ""
        };
        let it = findItem(pg.flick.contentItem, r, false) || (r.kind === "row" ? findItem(pg.flick.contentItem, groupHint, false) : null);
        if (!it) {
            const hidden = findItem(pg.flick.contentItem, r, true) || (r.kind === "row" ? findItem(pg.flick.contentItem, groupHint, true) : null);
            const g = hidden ? groupOf(hidden) : null;
            if (g && g.advanced && !r.opened && Shell.settingsSub !== g.title) {
                Shell.settingsSub = g.title;
                pendingTarget = Object.assign({}, r, {
                    "opened": true
                });
                targetTimer.restart();
            }
            return;
        }
        const y = it.mapToItem(pg.flick.contentItem, 0, 0).y;
        pg.scrollBy(Math.max(0, y - Theme.u * 8) - pg.flick.contentY);
        flashComp.createObject(it);
    }
    Timer {
        id: targetTimer
        interval: 80
        onTriggered: win.showTarget()
    }
    Component {
        id: flashComp
        Rectangle {
            id: flash
            anchors.fill: parent
            anchors.margins: -Theme.u * 2
            z: 100
            color: Qt.alpha(Theme.accent, 0.12)
            border.width: Math.max(2, Theme.u)
            border.color: Theme.accent
            SequentialAnimation on opacity {
                running: true
                PauseAnimation {
                    duration: 900
                }
                NumberAnimation {
                    to: 0
                    duration: 900
                }
                ScriptAction {
                    script: flash.destroy()
                }
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+F"
        onActivated: search.focusField()
    }
    // Ctrl+Z: the last change of a setting goes back (Config.undo)
    Shortcut {
        sequence: "Ctrl+Z"
        enabled: Config.canUndo
        onActivated: Config.undo()
    }
    // ◀ ▶ from the keyboard too, like Finder (Ctrl+[ / Ctrl+], Alt+← / Alt+→)
    Shortcut {
        sequences: ["Ctrl+[", "Alt+Left"]
        onActivated: win.back()
    }
    Shortcut {
        sequences: ["Ctrl+]", "Alt+Right"]
        onActivated: win.forward()
    }

    // the grimoire: its pages take the search box and the settings page (parent: below)
    GrimoireBook {
        id: book
        anchors.fill: parent
        view: win
        visible: win.grimoire
    }
    // the grimoire re-inks what it shows on parchment
    Component {
        id: inkFx
        ShaderEffect {
            fragmentShader: Qt.resolvedUrl("../../shaders/grimoire.frag.qsb")
            property color paper: book.paper
            property color ink: book.ink
            property color redInk: book.redInk
            property real invert: Theme.dark ? 1 : 0
        }
    }

    PxWindow {
        id: frame
        visible: !win.grimoire
        anchors.fill: parent
        anchors.rightMargin: Config.appearance.shadows ? Theme.u * 2 : 0
        anchors.bottomMargin: Config.appearance.shadows ? Theme.u * 2 : 0
        skin: win.skin
        title: (win.skin === "windose" ? "settings.exe ♡ " : "angelOS · ") + (win.currentPage ? win.currentPage.label : I18n.t("Настройки", "Settings"))
        icon: win.currentPage ? win.currentPage.icon : "gear"
        minimizable: false
        maximizable: true
        onCloseClicked: Shell.settingsOpen = false
        onMaximizeClicked: if (win.hostWindow)
            win.hostWindow.maximized = !win.hostWindow.maximized
        onTitlePressed: if (win.hostWindow)
            win.hostWindow.startSystemMove()
        bodyPadding: Theme.u * 4

        // the sidebar: on the left (Stream: its channel rail on the right)
        PxBox {
            id: sidebar
            x: win.skin === "stream" ? parent.width - width : 0
            width: Theme.u * (win.skin === "stream" ? 100 : 108)
            height: parent.height
            sunken: true
            color: win.skin === "classic" ? Qt.alpha(Theme.sunken, 0.55) : win.skin === "stream" ? Theme.streamPanel : Theme.mix(Theme.windosePaper, Theme.windoseLavender, 0.1)
        }

        // search box and results: at the top of the sidebar (the grimoire: on its page)
        Item {
            id: searchArea
            parent: win.grimoire ? book.searchSlot : sidebar
            anchors.fill: parent
            z: 5
            layer.enabled: win.grimoire
            layer.effect: inkFx

            PxField {
                id: search
                keepFocus: true
                x: Theme.u * 2
                y: Theme.u * 2
                width: parent.width - Theme.u * 4
                icon: "search"
                placeholder: I18n.t("Поиск", "Search")
                onEdited: {
                    win.query = text;
                    win.sel = 0;
                }
                onAccepted: win.openResult(win.results[Math.min(win.sel, win.results.length - 1)])
                onKeyPressed: e => {
                    if (e.key === Qt.Key_Tab || (e.key === Qt.Key_Right && search.input.cursorPosition === search.text.length)) {
                        if (win.acceptGhost())
                            e.accepted = true;
                    } else if (e.key === Qt.Key_Down) {
                        win.sel = Math.min(win.results.length - 1, win.sel + 1);
                        e.accepted = true;
                    } else if (e.key === Qt.Key_Up) {
                        win.sel = Math.max(0, win.sel - 1);
                        e.accepted = true;
                    } else if (e.key === Qt.Key_Escape && search.text !== "") {
                        search.text = "";
                        win.query = "";
                        e.accepted = true;
                    }
                }
                // the rest of the suggested word, dimmed after the caret: "Bl" → "ur"
                PxText {
                    visible: win.ghost !== "" && search.input.activeFocus && search.input.contentWidth + implicitWidth < search.input.width
                    x: search.input.x + search.input.contentWidth
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.ghost
                    font: search.input.font
                    color: Theme.textDim
                    opacity: 0.8
                }
            }
            PxText {
                visible: win.ghost !== "" && search.input.activeFocus
                anchors.top: search.bottom
                anchors.right: search.right
                anchors.topMargin: Theme.u
                text: "Tab ↹ " + search.text + win.ghost
                kind: "tiny"
                dim: true
                width: search.width
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideLeft
            }

            // results: in place of the sections while there is a query
            Rectangle {
                visible: win.grimoire && resultsBox.visible
                anchors.fill: parent
                anchors.topMargin: search.height + Theme.u * 6
                color: Theme.face
            }
            PxScroll {
                id: resultsBox
                visible: win.query.trim() !== ""
                anchors.fill: parent
                anchors.margins: Theme.u * 2
                anchors.topMargin: search.height + Theme.u * 10
                contentHeight: resultCol.implicitHeight
                Column {
                    id: resultCol
                    width: parent.width
                    spacing: Theme.u
                    PxText {
                        visible: win.results.length === 0
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: SettingsSearch.loaded ? I18n.t("Ничего не нашлось. Попробуй другое слово — «экран», «прозрачность», «хоткеи»…", "Nothing found. Try another word — “display”, “transparency”, “hotkeys”…") : "…"
                        dim: true
                        leftPadding: Theme.u * 3
                    }
                    Repeater {
                        model: win.results
                        Rectangle {
                            id: res
                            required property var modelData
                            required property int index
                            readonly property bool picked: win.sel === index
                            width: resultCol.width
                            height: resRow.implicitHeight + Theme.u * 4
                            color: picked ? Theme.select : rm.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.15) : "transparent"
                            Row {
                                id: resRow
                                x: Theme.u * 3
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.u * 3
                                PxIcon {
                                    name: res.modelData.icon || "gear"
                                    anchors.verticalCenter: parent.verticalCenter
                                    ink: res.picked ? Theme.selectText : (Theme.dark ? Theme.text : Theme.edge)
                                }
                                Column {
                                    width: res.width - Theme.u * 20
                                    PxText {
                                        width: parent.width
                                        text: res.modelData.title
                                        elide: Text.ElideRight
                                        font.bold: res.modelData.kind === "page"
                                        color: res.picked ? Theme.selectText : Theme.text
                                    }
                                    PxText {
                                        visible: text !== ""
                                        width: parent.width
                                        text: res.modelData.crumb || res.modelData.hint
                                        kind: "tiny"
                                        elide: Text.ElideRight
                                        color: res.picked ? Theme.selectText : Theme.textDim
                                    }
                                }
                            }
                            MouseArea {
                                id: rm
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: win.sel = res.index
                                onClicked: win.openResult(res.modelData)
                            }
                        }
                    }
                }
            }
        }

        // the account card and the sections
        PxScroll {
            parent: sidebar
            visible: win.query.trim() === ""
            anchors.fill: parent
            anchors.margins: Theme.u * 2
            anchors.topMargin: search.height + Theme.u * 4
            contentHeight: side.implicitHeight

            Column {
                id: side
                width: parent.width
                spacing: Theme.u

                // you: the avatar, the name; your account, language, the wizard
                Rectangle {
                    id: account
                    readonly property bool sel: win.sectionOf(Shell.settingsPage) === "account"
                    width: side.width
                    height: Theme.u * 24
                    color: sel ? Theme.select : am.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.15) : "transparent"
                    // the avatar from Bar → Start (StartPrefs), else a heart, in a pixel frame
                    PxBox {
                        id: face
                        x: Theme.u * 3
                        anchors.verticalCenter: parent.verticalCenter
                        width: Theme.u * 18
                        height: width
                        color: Theme.accent
                        Image {
                            id: avatarPic
                            anchors.fill: parent
                            anchors.margins: face.inset
                            source: StartPrefs.avatarUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize: Config.bar.avatarPixel ? Qt.size(20, 20) : Qt.size(width * 2, height * 2)
                            smooth: !Config.bar.avatarPixel
                            visible: status === Image.Ready
                        }
                        PxIcon {
                            visible: avatarPic.status !== Image.Ready
                            anchors.centerIn: parent
                            name: "heart"
                            fill: "#ffffff"
                        }
                    }
                    Column {
                        x: Theme.u * 25
                        width: parent.width - x - Theme.u * 2
                        anchors.verticalCenter: parent.verticalCenter
                        PxText {
                            width: parent.width
                            text: StartPrefs.userName
                            font.bold: true
                            elide: Text.ElideRight
                            color: account.sel ? Theme.selectText : Theme.text
                        }
                        PxText {
                            width: parent.width
                            text: I18n.t("Аккаунт, язык, мастер", "Account, language, wizard")
                            kind: "tiny"
                            elide: Text.ElideRight
                            color: account.sel ? Theme.selectText : Theme.textDim
                        }
                    }
                    MouseArea {
                        id: am
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Shell.settingsPage = "account";
                            Shell.settingsSub = "";
                        }
                    }
                }

                Repeater {
                    model: win.visibleRuns
                    Column {
                        id: run
                        required property var modelData
                        required property int index
                        width: side.width
                        spacing: Theme.u
                        // a line between the runs (Windose and Stream: their titles)
                        Item {
                            width: run.width
                            height: win.skin === "classic" ? Theme.u * 5 : runTitle.implicitHeight + Theme.u * 3
                            Rectangle {
                                visible: win.skin === "classic"
                                x: Theme.u * 3
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - Theme.u * 6
                                height: Math.max(1, Theme.u / 2)
                                color: Qt.alpha(Theme.lo, Theme.dark ? 0.9 : 0.6)
                            }
                            PxText {
                                id: runTitle
                                visible: win.skin !== "classic"
                                anchors.bottom: parent.bottom
                                text: (win.skin === "windose" ? "▸ " : "# ") + run.modelData.title
                                kind: "tiny"
                                dim: true
                                leftPadding: Theme.u * 3
                            }
                        }
                        Repeater {
                            model: run.modelData.sections
                            Rectangle {
                                id: entry
                                required property var modelData
                                readonly property bool sel: win.sectionOf(Shell.settingsPage) === modelData.id
                                width: run.width
                                height: Theme.u * (win.skin === "stream" ? 18 : 16)
                                radius: win.skin === "stream" ? Theme.u * 2 : 0
                                color: win.skin === "classic" ? sel ? Theme.select : em.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.15) : "transparent" : sel ? Theme.mix(Theme.face, Theme.accent, win.skin === "stream" ? 0.26 : 0.18) : em.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.12) : "transparent"
                                border.width: win.skin !== "classic" && sel ? Math.max(1, Theme.u / 2) : 0
                                border.color: Theme.accent
                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.u * 3
                                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                    spacing: Theme.u * 4
                                    SettingsTile {
                                        anchors.verticalCenter: parent.verticalCenter
                                        icon: entry.modelData.icon
                                        tint: entry.modelData.tint
                                    }
                                    PxText {
                                        width: entry.width - Theme.u * 22
                                        elide: Text.ElideRight
                                        text: entry.modelData.label
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: win.skin === "classic" && entry.sel ? Theme.selectText : Theme.text
                                        font.bold: entry.sel
                                    }
                                }
                                MouseArea {
                                    id: em
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: win.openSection(entry.modelData)
                                }
                            }
                        }
                    }
                }
            }
        }

        // page
        PxBox {
            id: pageBox
            anchors.left: win.skin === "stream" ? parent.left : sidebar.right
            anchors.leftMargin: win.skin === "stream" ? 0 : Theme.u * (win.skin === "classic" ? 4 : 3)
            anchors.right: win.skin === "stream" ? sidebar.left : parent.right
            anchors.rightMargin: win.skin === "stream" ? Theme.u * 3 : 0
            height: parent.height
            sunken: true
            color: win.skin === "windose" ? Theme.windosePaper : win.skin === "stream" ? Theme.streamBg : Qt.alpha(Theme.face, Config.appearance.blur ? 0.55 : 1)
            edgeColor: win.skin === "windose" ? Theme.windoseLine : Theme.edge

            // Windose: the home lies on lilac checks, like Ame's desktop
            Image {
                visible: win.skin === "windose" && (Shell.settingsPage === "home" || Shell.settingsPage === "more")
                anchors.fill: parent
                fillMode: Image.Tile
                smooth: false
                sourceSize: Qt.size(Theme.u * 16, Theme.u * 16)
                source: "data:image/svg+xml;utf8," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" shape-rendering="crispEdges"><rect width="16" height="16" fill="' + Theme.hex(Theme.mix(Theme.windosePaper, Theme.windoseLavender, 0.045)) + '"/><rect width="8" height="8" fill="' + Theme.hex(Theme.mix(Theme.windosePaper, Theme.windoseLavender, 0.018)) + '"/><rect x="8" y="8" width="8" height="8" fill="' + Theme.hex(Theme.mix(Theme.windosePaper, Theme.windoseLavender, 0.018)) + '"/></svg>')
            }

            // the toolbar: ◀ ▶, where you are, "Undo"
            Item {
                id: toolbar
                x: Theme.u * 2
                y: Theme.u * 2
                width: parent.width - Theme.u * 4
                height: Theme.u * 15
                Row {
                    id: arrows
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.u
                    PxButton {
                        compact: true
                        flat: true
                        icon: "arrowLeft"
                        enabled: win.canBack
                        opacity: enabled ? 1 : 0.35
                        onClicked: win.back()
                    }
                    PxButton {
                        compact: true
                        flat: true
                        icon: "arrowRight"
                        enabled: win.canForward
                        opacity: enabled ? 1 : 0.35
                        onClicked: win.forward()
                    }
                }
                Row {
                    anchors.left: arrows.right
                    anchors.leftMargin: Theme.u * 4
                    anchors.right: undoBtn.visible ? undoBtn.left : parent.right
                    anchors.rightMargin: Theme.u * 3
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.u * 2
                    clip: true
                    Repeater {
                        model: win.crumbs
                        Row {
                            id: crumb
                            required property var modelData
                            required property int index
                            readonly property bool last: index === win.crumbs.length - 1
                            spacing: Theme.u * 2
                            PxText {
                                visible: crumb.index > 0
                                text: "›"
                                dim: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            PxText {
                                text: crumb.modelData
                                kind: "title"
                                font.bold: crumb.last
                                color: crumb.last ? Theme.text : cm.containsMouse ? Theme.accent : Theme.textDim
                                anchors.verticalCenter: parent.verticalCenter
                                MouseArea {
                                    id: cm
                                    anchors.fill: parent
                                    enabled: !crumb.last
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    // up to that level: the section's first page, or the page itself
                                    onClicked: {
                                        const s = win.sectionFor(win.currentId);
                                        if (crumb.index === 0 && s)
                                            win.openSection(s);
                                        else
                                            Shell.settingsSub = "";
                                    }
                                }
                            }
                        }
                    }
                }
                // "Undo": the last change of a setting (Config.undo)
                PxButton {
                    id: undoBtn
                    visible: Config.canUndo
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    compact: true
                    icon: "refresh"
                    text: I18n.t("Отменить", "Undo") + (win.width > Theme.u * 420 && SettingsKeys.loaded ? " " + SettingsKeys.stepLabel(Config.lastStep) : "")
                    onClicked: Config.undo()
                }
                Rectangle {
                    anchors.top: parent.bottom
                    anchors.topMargin: Theme.u
                    width: parent.width
                    height: Math.max(1, Theme.u / 2)
                    color: Qt.alpha(Theme.lo, 0.6)
                }
            }

            Loader {
                id: page
                parent: win.grimoire ? book.pageSlot : pageBox
                anchors.fill: parent
                anchors.margins: win.grimoire ? 0 : Theme.u * 3
                anchors.topMargin: win.grimoire ? 0 : toolbar.y + toolbar.height + Theme.u * 4
                layer.enabled: win.grimoire
                layer.effect: inkFx
                active: win.hostWindow ? win.hostWindow.visible : true
                onLoaded: if (win.pendingTarget)
                    targetTimer.restart()
                source: {
                    const id = Shell.settingsPage;
                    // the old home: your account in Classic, Windose and Stream keep their own
                    if (id === "home" || id === "more")
                        return win.skin === "classic" || win.grimoire ? "pages/AccountPage.qml" : id === "home" ? "pages/HomePage.qml" : "pages/MorePage.qml";
                    if (id.startsWith("plugin:"))
                        return "pages/PluginSettingsPage.qml";
                    if (id === "dotfiles")
                        return Owner.enabled ? "file://" + Owner.dir + "/DotfilesPage.qml" : "pages/AccountPage.qml";
                    const name = id.charAt(0).toUpperCase() + id.slice(1);
                    return "pages/" + (win.allPages.find(p => p.id === id) ? name : "Account") + "Page.qml";
                }
            }
        }

        // resize grip
        PxIcon {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: -Theme.u * 3
            name: "sparkle"
            fill: Theme.textDim
            MouseArea {
                anchors.fill: parent
                anchors.margins: -Theme.u * 3
                cursorShape: Qt.SizeFDiagCursor
                onPressed: if (win.hostWindow)
                    win.hostWindow.startSystemResize(Edges.Bottom | Edges.Right)
            }
        }
    }
}
