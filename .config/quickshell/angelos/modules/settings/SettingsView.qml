pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Settings content (frame, sidebar, pages). Hosted by SettingsWindow.
Item {
    id: win

    Component.onCompleted: {
        Shell.settingsView = win;
        SettingsSearch.load();
        SettingsKeys.load();
    }
    Component.onDestruction: if (Shell.settingsView === win)
        Shell.settingsView = null
    function diagnostics() {
        return {
            page: Shell.settingsPage,
            source: String(page.source),
            status: page.status,
            plugin: page.item && page.item.loadedPlugin !== undefined ? page.item.loadedPlugin : ""
        };
    }
    property var hostWindow: null
    readonly property alias frame: frame
    readonly property var groups: [
        {
            "title": I18n.t("Вид", "Appearance"),
            "pages": [
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
                    "id": "wallpaper",
                    "label": I18n.t("Обои", "Wallpaper"),
                    "icon": "image"
                },
                {
                    "id": "capture",
                    "label": I18n.t("Скриншоты", "Screenshots"),
                    "icon": "image"
                },
                {
                    "id": "cursor",
                    "label": I18n.t("Курсор", "Cursor"),
                    "icon": "cursor"
                },
                {
                    "id": "widgets",
                    "label": I18n.t("Виджеты", "Widgets"),
                    "icon": "layers"
                },
                {
                    "id": "bar",
                    "label": I18n.t("Панель", "Bar"),
                    "icon": "window"
                },
                {
                    "id": "workspaces",
                    "label": I18n.t("Воркспейсы", "Workspaces"),
                    "icon": "layers"
                },
                {
                    "id": "lyrics",
                    "label": I18n.t("Лирика", "Lyrics"),
                    "icon": "mic"
                },
                {
                    "id": "y2k",
                    "label": "Y2K ✧",
                    "icon": "sparkle"
                }
            ]
        },
        {
            "title": I18n.t("Устройства", "Devices"),
            "pages": [
                {
                    "id": "monitor",
                    "label": I18n.t("Монитор", "Monitor"),
                    "icon": "monitor"
                },
                {
                    "id": "keyboard",
                    "label": I18n.t("Клавиатура и мышь", "Keyboard and mouse"),
                    "icon": "keyboard"
                },
                {
                    "id": "shortcuts",
                    "label": I18n.t("Горячие клавиши", "Shortcuts"),
                    "icon": "keyboard"
                },
                {
                    "id": "windows",
                    "label": I18n.t("Поведение окон", "Window behavior"),
                    "icon": "window"
                },
                {
                    "id": "sound",
                    "label": I18n.t("Звук", "Sound"),
                    "icon": "speaker"
                },
                {
                    "id": "network",
                    "label": I18n.t("Сеть и Wi-Fi", "Network and Wi-Fi"),
                    "icon": "wifi"
                },
                {
                    "id": "bluetooth",
                    "label": "Bluetooth",
                    "icon": "bluetooth"
                },
                {
                    "id": "gamepad",
                    "label": I18n.t("Геймпад", "Gamepad"),
                    "icon": "gamepad"
                }
            ]
        },
        {
            "title": "System",
            "pages": [
                {
                    "id": "defaults",
                    "label": I18n.t("По умолчанию", "Default apps"),
                    "icon": "star"
                },
                {
                    "id": "notifications",
                    "label": I18n.t("Уведомления", "Notifications"),
                    "icon": "bell"
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
                    "id": "dotfiles",
                    "label": "Dotfiles",
                    "icon": "package",
                    "owner": true
                },
                {
                    "id": "lock",
                    "label": I18n.t("Блокировка и заставка", "Lock and idle"),
                    "icon": "lock"
                },
                {
                    "id": "updates",
                    "label": I18n.t("Обновления", "Updates"),
                    "icon": "download"
                },
                {
                    "id": "system",
                    "label": "System",
                    "icon": "chip"
                }
            ]
        },
        {
            "title": I18n.t("Плагины", "Plugins"),
            "pages": Plugins.settingsPages.map(p => ({
                        "id": "plugin:" + p.id,
                        "label": I18n.label(p.name),
                        "icon": p.icon || "plug"
                    }))
        }
    ]
    // owner-only pages vanish in the public version
    readonly property var visibleGroups: groups.map(g => ({
                "title": g.title,
                "pages": g.pages.filter(p => (!p.owner || Owner.enabled) && (!p.developer || Config.developer.enabled))
            })).filter(g => g.pages.length > 0)
    readonly property var allPages: visibleGroups.reduce((a, g) => a.concat(g.pages), [])
    readonly property var currentPage: allPages.find(p => p.id === Shell.settingsPage) || null
    // simple view: home tiles + main settings (advanced groups folded); expert: every page in the sidebar
    readonly property bool expert: Config.settingsUi.expert
    readonly property bool atHome: !expert && (Shell.settingsPage === "home" || Shell.settingsPage === "more")
    function setExpert(on) {
        Config.settingsUi.expert = on;
        if (on && (Shell.settingsPage === "home" || Shell.settingsPage === "more"))
            Shell.settingsPage = "appearance";
        else if (!on)
            Shell.settingsPage = "home";
        history = [];
    }

    // "Back" in the simple view goes where the page was opened from — the home
    // tiles, "All sections", a page a search result led away from — not
    // always to the home screen
    property var history: []
    property string lastPage: Shell.settingsPage
    property bool goingBack: false
    Connections {
        target: Shell
        function onSettingsPageChanged() {
            if (!win.goingBack && win.lastPage && win.lastPage !== Shell.settingsPage)
                win.history = win.history.filter(p => p !== Shell.settingsPage).concat([win.lastPage]).slice(-20);
            win.goingBack = false;
            win.lastPage = Shell.settingsPage;
            // how often each page is opened: "Everyday" on the home page follows it
            if (Config.ready && Shell.settingsOpen && Shell.settingsPage !== "home" && Shell.settingsPage !== "more") {
                const u = Object.assign({}, Config.settingsUi.usage || {});
                u[Shell.settingsPage] = (u[Shell.settingsPage] || 0) + 1;
                Config.settingsUi.usage = u;
            }
        }
        function onSettingsOpenChanged() {
            if (!Shell.settingsOpen)
                win.history = [];
        }
    }
    readonly property string backTarget: history.length ? history[history.length - 1] : "home"
    readonly property string backLabel: backTarget === "home" ? I18n.t("Главная", "Home") : backTarget === "more" ? I18n.t("Все разделы", "All sections") : ((allPages.find(p => p.id === backTarget) || {}).label || I18n.t("Назад", "Back"))
    function back() {
        const h = history.slice();
        const target = h.length ? h.pop() : "home";
        history = h;
        goingBack = true;
        Shell.settingsPage = target;
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
            for (const p of win.allPages)
                m[p.id] = {
                    "label": p.label,
                    "icon": p.icon
                };
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
    }
    // scroll the page to the found setting and flash it
    function findItem(item, r) {
        if (!item || !item.visible)
            return null;
        if (r.kind === "row" && item.label === r.target && item.hint !== undefined)
            return item;
        if (r.kind === "group" && item.title === r.target && item.spacing !== undefined)
            return item;
        for (const c of item.children) {
            const f = findItem(c, r);
            if (f)
                return f;
        }
        return null;
    }
    function unfoldAll(item) {
        let any = false;
        if (item.folded === true && item.advanced !== undefined) {
            item.open = true;
            any = true;
        }
        for (const c of item.children)
            any = unfoldAll(c) || any;
        return any;
    }
    function showTarget() {
        const r = pendingTarget;
        pendingTarget = null;
        const pg = page.item;
        if (!r || !pg || !pg.flick)
            return;
        const it = findItem(pg.flick.contentItem, r) || (r.kind === "row" ? findItem(pg.flick.contentItem, {
                "kind": "group",
                "target": String(r.crumb).split(" › ")[1] || ""
            }) : null);
        if (!it) {
            // the setting may sit in a folded "Advanced" group of the simple view
            if (!r.unfolded && unfoldAll(pg.flick.contentItem)) {
                pendingTarget = Object.assign({}, r, {
                    "unfolded": true
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
        interval: 60
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

    PxWindow {
        id: frame
        anchors.fill: parent
        anchors.rightMargin: Config.appearance.shadows ? Theme.u * 2 : 0
        anchors.bottomMargin: Config.appearance.shadows ? Theme.u * 2 : 0
        title: "angelOS · " + (win.currentPage ? win.currentPage.label : Shell.settingsPage === "more" ? I18n.t("Все разделы", "All sections") : I18n.t("Настройки", "Settings"))
        icon: win.currentPage ? win.currentPage.icon : "gear"
        minimizable: false
        maximizable: true
        onCloseClicked: Shell.settingsOpen = false
        onMaximizeClicked: if (win.hostWindow)
            win.hostWindow.maximized = !win.hostWindow.maximized
        onTitlePressed: if (win.hostWindow)
            win.hostWindow.startSystemMove()
        bodyPadding: Theme.u * 4

        // sidebar (expert view)
        PxBox {
            id: sidebar
            visible: win.expert
            width: Theme.u * 95
            height: parent.height
            sunken: true
            color: Qt.alpha(Theme.sunken, 0.55)
        }

        // search box and results: in the sidebar (expert) or above the page (simple)
        Item {
            id: searchArea
            parent: win.expert ? sidebar : pageBox
            anchors.fill: parent
            z: 5

            PxField {
                id: search
                x: win.expert ? Theme.u * 2 : homeBtn.x + (homeBtn.visible ? homeBtn.width + Theme.u * 3 : 0)
                y: Theme.u * 2
                width: win.expert ? parent.width - Theme.u * 4 : (undoBtn.visible ? undoBtn.x : expertBtn.x) - x - Theme.u * 3
                icon: "search"
                placeholder: I18n.t("Поиск настроек…", "Search settings…")
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

            // results
            Rectangle {
                visible: !win.expert && resultsBox.visible
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

        // expert sidebar: every page
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

                // back to the simple view
                Rectangle {
                    width: side.width
                    height: Theme.u * 15
                    color: sm.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.15) : "transparent"
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.u * 4
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.u * 4
                        PxIcon {
                            name: "grid"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        PxText {
                            text: I18n.t("Простой вид", "Simple view")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    MouseArea {
                        id: sm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.setExpert(false)
                    }
                }

                Repeater {
                    model: win.visibleGroups
                    Column {
                        id: grp
                        required property var modelData
                        width: side.width
                        spacing: Theme.u
                        PxText {
                            text: "✧ " + grp.modelData.title
                            kind: "tiny"
                            dim: true
                            topPadding: Theme.u * 4
                            leftPadding: Theme.u * 3
                            bottomPadding: Theme.u
                        }
                        Repeater {
                            model: grp.modelData.pages
                            Rectangle {
                                id: entry
                                required property var modelData
                                readonly property bool sel: Shell.settingsPage === modelData.id
                                width: grp.width
                                height: Theme.u * 15
                                color: sel ? Theme.select : em.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.15) : "transparent"
                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.u * 4
                                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                    spacing: Theme.u * 4
                                    PxIcon {
                                        name: entry.modelData.icon
                                        anchors.verticalCenter: parent.verticalCenter
                                        ink: entry.sel ? Theme.selectText : (Theme.dark ? Theme.text : Theme.edge)
                                    }
                                    PxText {
                                        width: entry.width - Theme.u * 24
                                        elide: Text.ElideRight
                                        text: entry.modelData.label
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: entry.sel ? Theme.selectText : Theme.text
                                        font.bold: entry.sel
                                    }
                                }
                                MouseArea {
                                    id: em
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Shell.settingsPage = entry.modelData.id
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
            anchors.left: win.expert ? sidebar.right : parent.left
            anchors.leftMargin: win.expert ? Theme.u * 4 : 0
            anchors.right: parent.right
            height: parent.height
            sunken: true
            color: Qt.alpha(Theme.face, Config.appearance.blur ? 0.55 : 1)

            // simple view header: home, (search), expert
            PxButton {
                id: homeBtn
                visible: !win.expert && Shell.settingsPage !== "home"
                x: Theme.u * 2
                y: Theme.u * 2
                height: search.height
                compact: true
                icon: "arrowLeft"
                text: win.backLabel
                onClicked: win.back()
            }
            // "Undo": the last change of a setting (Config.undo); in Expert it sits
            // in the page's top-right corner
            PxButton {
                id: undoBtn
                visible: Config.canUndo
                z: 6
                x: win.expert ? parent.width - width - Theme.u * 3 : expertBtn.x - width - Theme.u * 3
                y: Theme.u * 2
                height: search.height
                compact: true
                icon: "refresh"
                text: I18n.t("Отменить", "Undo") + (win.width > Theme.u * 420 && SettingsKeys.loaded ? " " + SettingsKeys.stepLabel(Config.lastStep) : "")
                onClicked: Config.undo()
            }
            PxButton {
                id: expertBtn
                visible: !win.expert
                x: parent.width - width - Theme.u * 2
                y: Theme.u * 2
                height: search.height
                compact: true
                icon: "gear"
                text: I18n.t("Эксперт", "Expert")
                onClicked: win.setExpert(true)
            }

            Loader {
                id: page
                anchors.fill: parent
                anchors.margins: Theme.u * 3
                anchors.topMargin: win.expert ? Theme.u * 3 : search.height + Theme.u * 6
                active: win.hostWindow ? win.hostWindow.visible : true
                onLoaded: if (win.pendingTarget)
                    targetTimer.restart()
                source: {
                    const id = Shell.settingsPage;
                    if (id === "home" || id === "more")
                        return win.expert ? "pages/AppearancePage.qml" : id === "home" ? "pages/HomePage.qml" : "pages/MorePage.qml";
                    if (id.startsWith("plugin:"))
                        return "pages/PluginSettingsPage.qml";
                    if (id === "dotfiles")
                        return Owner.enabled ? "file://" + Owner.dir + "/DotfilesPage.qml" : "pages/AppearancePage.qml";
                    const name = id.charAt(0).toUpperCase() + id.slice(1);
                    return "pages/" + (win.allPages.find(p => p.id === id) ? name : "Appearance") + "Page.qml";
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
