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
    readonly property var currentPage: allPages.find(p => p.id === Shell.settingsPage) || allPages[0]

    // ---- search (services/SettingsSearch) ----
    property string query: ""
    property int sel: 0
    property var results: []
    onQueryChanged: {
        if (!query.trim())
            results = [];
        searchTimer.restart();
    }
    Timer {
        id: searchTimer
        interval: 60
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
        if (!it)
            return;
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

    PxWindow {
        id: frame
        anchors.fill: parent
        anchors.rightMargin: Config.appearance.shadows ? Theme.u * 2 : 0
        anchors.bottomMargin: Config.appearance.shadows ? Theme.u * 2 : 0
        title: "angelOS · " + (win.currentPage ? win.currentPage.label : I18n.t("Настройки", "Settings"))
        icon: win.currentPage ? win.currentPage.icon : "gear"
        minimizable: false
        maximizable: true
        onCloseClicked: Shell.settingsOpen = false
        onMaximizeClicked: if (win.hostWindow)
            win.hostWindow.maximized = !win.hostWindow.maximized
        onTitlePressed: if (win.hostWindow)
            win.hostWindow.startSystemMove()
        bodyPadding: Theme.u * 4

        // sidebar
        PxBox {
            id: sidebar
            width: Theme.u * 95
            height: parent.height
            sunken: true
            color: Qt.alpha(Theme.sunken, 0.55)

            PxField {
                id: search
                x: Theme.u * 2
                y: Theme.u * 2
                width: parent.width - Theme.u * 4
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

            PxScroll {
                visible: win.query.trim() === ""
                anchors.fill: parent
                anchors.margins: Theme.u * 2
                anchors.topMargin: search.height + Theme.u * 4
                contentHeight: side.implicitHeight

                Column {
                    id: side
                    width: parent.width
                    spacing: Theme.u

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
        }

        // page
        PxBox {
            id: pageBox
            anchors.left: sidebar.right
            anchors.leftMargin: Theme.u * 4
            anchors.right: parent.right
            height: parent.height
            sunken: true
            color: Qt.alpha(Theme.face, Config.appearance.blur ? 0.55 : 1)

            Loader {
                id: page
                anchors.fill: parent
                anchors.margins: Theme.u * 3
                active: win.hostWindow ? win.hostWindow.visible : true
                onLoaded: if (win.pendingTarget)
                    targetTimer.restart()
                source: {
                    const id = Shell.settingsPage;
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
