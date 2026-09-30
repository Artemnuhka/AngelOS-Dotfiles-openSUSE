pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Windows 11-like Start: search on top, pinned apps grid, "All apps" list,
// recommended row, user + power at the bottom. Right-click pins/unpins.
PxBox {
    id: root

    signal closeRequested
    property int current: -1
    property bool showAll: false
    property string query: ""
    // Settings → Bar → Start: width in % of the default and rows of pinned apps
    readonly property real sizeFactor: Math.max(0.7, Math.min(1.8, (Config.bar.startWidth || 100) / 100))
    readonly property int columns: Math.max(4, Math.min(10, Math.round(6 * sizeFactor)))
    readonly property int rows: Math.max(2, Math.min(6, Config.bar.startRows || 3))
    readonly property var shown: query.trim() !== "" ? StartApps.search(query).slice(0, columns * Math.max(4, rows)) : showAll ? StartApps.apps : StartApps.pinned.slice(0, columns * rows)
    readonly property var recommended: [
        {
            "text": I18n.t("Настройки", "Settings"),
            "hint": I18n.t("тема, обои, панель", "theme, wallpaper, bar"),
            "icon": "gear",
            "act": () => Shell.openSettings()
        },
        {
            "text": I18n.t("Обои", "Wallpaper"),
            "hint": I18n.t("выбрать картинку", "pick a picture"),
            "icon": "image",
            "act": () => Shell.openSettings("wallpaper")
        },
        {
            "text": I18n.t("Файлы", "Files"),
            "hint": I18n.t("домашняя папка", "home folder"),
            "icon": "folder",
            "act": () => Shell.exec([Config.system.fileManager || "xdg-open", Config.home])
        },
        {
            "text": I18n.t("Терминал", "Terminal"),
            "hint": Config.system.terminal || "kitty",
            "icon": "terminal",
            "act": () => Shell.terminal()
        }
    ]

    function reset() {
        current = -1;
        showAll = false;
        query = "";
        field.text = "";
        Qt.callLater(() => field.focusField());
    }
    function run(app) {
        closeRequested();
        Qt.callLater(() => StartApps.launch(app));
    }
    function act(fn) {
        closeRequested();
        Qt.callLater(fn);
    }
    function move(dx, dy) {
        const n = shown.length;
        if (!n)
            return;
        if (current < 0) {
            current = 0;
            return;
        }
        const step = showAll && !query ? dy : dy * columns + dx;
        current = Math.max(0, Math.min(n - 1, current + (showAll && !query ? dy + dx : step)));
        if (showAll && !query)
            allList.positionViewAtIndex(current, ListView.Contain);
    }
    // the overlay forwards the first key here; the search field takes the rest
    function key(e) {
        if (nav(e))
            return;
        if (e.text && e.text.trim() !== "" && !(e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            field.text += e.text;
            query = field.text;
            field.focusField();
            e.accepted = true;
        }
    }
    function nav(e) {
        if (e.key === Qt.Key_Escape || e.key === Qt.Key_Super_L || e.key === Qt.Key_Super_R)
            closeRequested();
        else if (e.key === Qt.Key_Down)
            move(0, 1);
        else if (e.key === Qt.Key_Up)
            move(0, -1);
        else if (e.key === Qt.Key_Right && (current >= 0 || query === ""))
            move(1, 0);
        else if (e.key === Qt.Key_Left && (current >= 0 || query === ""))
            move(-1, 0);
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
            run(shown[Math.max(0, current)]);
        else
            return false;
        e.accepted = true;
        return true;
    }

    width: Math.round(Theme.u * 250 * sizeFactor)
    height: col.implicitHeight + footer.height + Theme.u * 10
    color: Qt.alpha(Theme.menuSurface, Theme.panelAlpha)
    edgeColor: Theme.menuBorder
    flat: true
    shadow: Config.appearance.shadows

    component Tile: Item {
        id: tile
        required property var modelData
        required property int index
        readonly property bool sel: root.current === index
        width: grid.cellWidth
        height: grid.cellHeight
        Rectangle {
            anchors.fill: parent
            anchors.margins: Theme.u
            color: tile.sel ? Qt.alpha(Theme.accent, 0.3) : tm.containsMouse ? Qt.alpha(Theme.accent, 0.14) : "transparent"
            border.width: tile.sel ? Math.max(1, Theme.u / 2) : 0
            border.color: Theme.accent
        }
        Column {
            anchors.centerIn: parent
            width: parent.width - Theme.u * 4
            spacing: Theme.u * 2
            AppIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                iconName: tile.modelData.icon || ""
                appId: tile.modelData.id || ""
                size: Theme.u * 15
                scale: tm.pressed ? 0.88 : 1
                Behavior on scale {
                    NumberAnimation {
                        duration: 90
                    }
                }
            }
            PxText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: tile.modelData.name
                kind: "tiny"
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
        PxIcon {
            visible: StartApps.isPinned(tile.modelData) && !root.query
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.u * 2
            name: "pin"
            pixel: Math.max(1, Theme.u - 1)
        }
        MouseArea {
            id: tm
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onEntered: root.current = tile.index
            onClicked: m => m.button === Qt.RightButton ? StartApps.togglePin(tile.modelData) : root.run(tile.modelData)
        }
    }

    Column {
        id: col
        x: Theme.u * 6
        y: Theme.u * 6
        width: parent.width - Theme.u * 12
        spacing: Theme.u * 5

        PxField {
            id: field
            width: parent.width
            icon: "search"
            placeholder: I18n.t("Поиск приложений…", "Search apps…")
            onEdited: {
                root.query = text;
                root.current = text ? 0 : -1;
            }
            onAccepted: if (root.shown.length)
                root.run(root.shown[Math.max(0, root.current)])
            onKeyPressed: e => root.nav(e)
        }

        Item {
            width: parent.width
            height: head.implicitHeight
            PxText {
                id: head
                text: root.query ? I18n.t("Найдено", "Results") : root.showAll ? I18n.t("Все приложения", "All apps") : I18n.t("Закреплённые", "Pinned")
                kind: "title"
                anchors.verticalCenter: parent.verticalCenter
            }
            PxButton {
                visible: !root.query
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                compact: true
                text: root.showAll ? I18n.t("‹ Назад", "‹ Back") : I18n.t("Все приложения ›", "All apps ›")
                onClicked: {
                    root.showAll = !root.showAll;
                    root.current = -1;
                }
            }
        }

        // pinned / results grid
        GridView {
            id: grid
            visible: !root.showAll || root.query !== ""
            width: parent.width
            height: cellHeight * Math.max(1, Math.min(root.rows, Math.ceil(count / root.columns)))
            cellWidth: width / root.columns
            cellHeight: Theme.u * 30
            interactive: count > root.columns * root.rows
            clip: true
            model: grid.visible ? root.shown : []
            delegate: Tile {}
        }

        // all apps, alphabetical with letter headers
        ListView {
            id: allList
            visible: root.showAll && root.query === ""
            width: parent.width
            height: grid.cellHeight * root.rows + recHead.implicitHeight + recFlow.implicitHeight + Theme.u * 5
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: allList.visible ? root.shown : []
            delegate: Item {
                id: li
                required property var modelData
                required property int index
                readonly property string letter: String(modelData.name || "?").charAt(0).toUpperCase()
                readonly property bool first: index === 0 || letter !== String(root.shown[index - 1].name || "?").charAt(0).toUpperCase()
                width: allList.width
                height: row.height + (first ? letterText.implicitHeight + Theme.u * 2 : 0)
                PxText {
                    id: letterText
                    visible: li.first
                    text: li.letter
                    kind: "title"
                    color: Theme.accent
                    topPadding: Theme.u * 2
                }
            Rectangle {
                id: row
                y: li.first ? letterText.implicitHeight + Theme.u * 2 : 0
                width: allList.width
                height: Theme.u * 14
                color: root.current === li.index ? Qt.alpha(Theme.accent, 0.3) : lm.containsMouse ? Qt.alpha(Theme.accent, 0.14) : "transparent"
                Row {
                    x: Theme.u * 3
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.u * 4
                    AppIcon {
                        iconName: li.modelData.icon || ""
                        appId: li.modelData.id || ""
                        size: Theme.u * 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    PxText {
                        text: li.modelData.name
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    id: lm
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.current = li.index
                    onClicked: m => m.button === Qt.RightButton ? StartApps.togglePin(li.modelData) : root.run(li.modelData)
                }
            }
            }
        }

        PxText {
            id: recHead
            visible: !root.showAll && !root.query
            text: I18n.t("Рекомендуем", "Recommended")
            kind: "title"
        }
        Flow {
            id: recFlow
            visible: !root.showAll && !root.query
            width: parent.width
            spacing: Theme.u * 2
            Repeater {
                model: root.recommended
                Rectangle {
                    id: rec
                    required property var modelData
                    width: (recFlow.width - recFlow.spacing) / 2
                    height: Theme.u * 17
                    color: rm.containsMouse ? Qt.alpha(Theme.accent, 0.14) : "transparent"
                    Row {
                        x: Theme.u * 3
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.u * 4
                        PxIcon {
                            name: rec.modelData.icon
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: rec.width - Theme.u * 20
                            PxText {
                                width: parent.width
                                elide: Text.ElideRight
                                text: rec.modelData.text
                            }
                            PxText {
                                width: parent.width
                                elide: Text.ElideRight
                                text: rec.modelData.hint
                                kind: "tiny"
                                dim: true
                            }
                        }
                    }
                    MouseArea {
                        id: rm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.act(rec.modelData.act)
                    }
                }
            }
        }
    }

    // user + power
    Rectangle {
        id: footer
        anchors.bottom: parent.bottom
        width: parent.width
        height: Theme.u * 20
        color: Qt.alpha(Theme.menuHeader, 0.55)
        Rectangle {
            width: parent.width
            height: Theme.u
            color: Theme.menuBorder
        }
        Row {
            x: Theme.u * 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u * 4
            PxBox {
                width: Theme.u * 13
                height: width
                color: Theme.accent
                anchors.verticalCenter: parent.verticalCenter
                PxIcon {
                    anchors.centerIn: parent
                    name: "heart"
                    fill: "#ffffff"
                }
            }
            PxText {
                text: StartApps.userName
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.u * 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u * 3
            PxButton {
                compact: true
                icon: "lock"
                onClicked: root.act(() => Shell.lock())
            }
            PxButton {
                compact: true
                icon: "power"
                onClicked: root.act(() => Shell.sessionOpen = true)
            }
        }
    }
}
