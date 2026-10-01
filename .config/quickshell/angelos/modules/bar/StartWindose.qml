pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Windose Start (NEEDY GIRL OVERDOSE's OS): a pink pixel window by the Start button —
// "Windose.exe ♡" title bar with its little buttons, a candy side banner, the pinned
// apps as stickers (white plates, a pink outline, a hard drop shadow, names in
// bubbles), every program in a list with heart bullets and a heart scroll thumb, the
// user and a ♡ power button at the bottom. Typing searches, ↑↓ walk the list, Enter
// runs, right click pins, Esc clears / closes.
Rectangle {
    id: root

    signal closeRequested
    property int current: -1
    property string query: ""
    readonly property bool searching: query.trim() !== ""
    readonly property real sizeFactor: Math.max(0.7, Math.min(1.8, (Config.bar.startWidth || 100) / 100))
    readonly property var pins: StartApps.pinned.slice(0, 8)
    readonly property var rows: {
        if (!searching)
            return StartApps.apps.map(a => ({
                        "label": a.name,
                        "app": a,
                        "run": () => StartApps.launch(a)
                    }));
        return StartApps.searchAll(query, 40).map(r => r.kind === "app" ? {
                "label": r.app.name,
                "app": r.app,
                "run": () => StartApps.launch(r.app)
            } : r.kind === "setting" ? {
                "label": r.doc.title,
                "icon": r.doc.icon || "gear",
                "run": () => StartApps.openSetting(r.doc)
            } : {
                "label": r.calc.title + "  " + (r.calc.subtitle || ""),
                "icon": "calc",
                "run": () => Calc.copy(r.calc)
            });
    }

    // NGO candy colours, leaning on the theme's accents
    readonly property color pink: Theme.mix(Theme.accent, "#ffb3d9", 0.5)
    readonly property color lilac: Theme.mix(Theme.accent2, "#c7b5ff", 0.5)
    readonly property color mint: Theme.mix(Theme.accent3, "#9fe8ff", 0.5)
    readonly property color ink: "#4a2a5e"
    readonly property color paper: Theme.dark ? "#2b1d33" : "#fff4fb"
    readonly property color paperText: Theme.dark ? "#ffe6f4" : ink

    function setQuery(t) {
        field.text = t;
        query = t;
        current = t ? 0 : -1;
    }
    function reset() {
        query = "";
        field.text = "";
        current = -1;
        list.positionViewAtBeginning();
        Qt.callLater(() => field.focusField());
    }
    function runRow(r) {
        if (!r)
            return;
        closeRequested();
        Qt.callLater(r.run);
    }
    function act(fn) {
        closeRequested();
        Qt.callLater(fn);
    }
    function move(d) {
        current = Math.max(0, Math.min(rows.length - 1, current + d));
        list.positionViewAtIndex(current, ListView.Contain);
    }
    function key(e) {
        if (nav(e))
            return;
        if (e.text && e.text.trim() !== "" && !(e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            field.text += e.text;
            query = field.text;
            current = 0;
            field.focusField();
            e.accepted = true;
        }
    }
    function nav(e) {
        if (e.key === Qt.Key_Escape || e.key === Qt.Key_Super_L || e.key === Qt.Key_Super_R) {
            if (searching && e.key === Qt.Key_Escape)
                setQuery("");
            else
                closeRequested();
        } else if (e.key === Qt.Key_Down)
            move(1);
        else if (e.key === Qt.Key_Up)
            move(-1);
        else if (e.key === Qt.Key_PageDown)
            move(8);
        else if (e.key === Qt.Key_PageUp)
            move(-8);
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
            runRow(rows[Math.max(0, current)]);
        else
            return false;
        e.accepted = true;
        return true;
    }

    width: Math.round(Theme.u * 170 * sizeFactor)
    height: Theme.u * 230
    color: ink
    // the window: an ink frame, a pink rim, the paper inside
    Rectangle {
        anchors.fill: parent
        anchors.margins: Math.max(1, Theme.u / 2)
        color: root.pink
        Rectangle {
            id: paper
            anchors.fill: parent
            anchors.margins: Theme.u
            anchors.topMargin: titleBar.height + Theme.u
            color: root.paper
        }
    }

    // ---- title bar ----
    Rectangle {
        id: titleBar
        x: Theme.u
        y: Theme.u
        width: parent.width - Theme.u * 2
        height: Theme.u * 13
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: root.pink
            }
            GradientStop {
                position: 1
                color: root.lilac
            }
        }
        PxText {
            x: Theme.u * 4
            anchors.verticalCenter: parent.verticalCenter
            font.bold: true
            color: "#ffffff"
            style: Text.Outline
            styleColor: root.ink
            text: "Windose.exe ♡"
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.u * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u
            Repeater {
                model: ["minimize", "maximize", "close"]
                Rectangle {
                    id: tb
                    required property string modelData
                    width: Theme.u * 9
                    height: width
                    color: tbm.containsMouse && tb.modelData === "close" ? Theme.mix(root.pink, "#ff4f8b", 0.6) : "#ffffff"
                    border.width: Math.max(1, Theme.u / 2)
                    border.color: root.ink
                    PxIcon {
                        anchors.centerIn: parent
                        name: tb.modelData
                        pixel: Math.max(1, Theme.u / 2)
                        ink: root.ink
                    }
                    MouseArea {
                        id: tbm
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.closeRequested()
                    }
                }
            }
        }
    }

    // ---- the candy side banner ----
    Rectangle {
        id: banner
        x: Theme.u * 2
        y: titleBar.y + titleBar.height + Theme.u
        width: Theme.u * 15
        height: footer.y - y - Theme.u
        gradient: Gradient {
            GradientStop {
                position: 0
                color: root.mint
            }
            GradientStop {
                position: 0.5
                color: root.lilac
            }
            GradientStop {
                position: 1
                color: root.pink
            }
        }
        PxText {
            anchors.centerIn: parent
            rotation: -90
            kind: "title"
            font.bold: true
            color: "#ffffff"
            style: Text.Outline
            styleColor: root.ink
            text: "angelOS ♡ Windose"
        }
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: Theme.u * 4
            spacing: Theme.u * 3
            Repeater {
                model: 3
                PxIcon {
                    required property int index
                    name: index === 1 ? "star" : "heartSmall"
                    pixel: Math.max(1, Theme.u / 2)
                    fill: "#ffffff"
                    ink: root.ink
                }
            }
        }
    }

    // ---- search, stickers, programs ----
    Item {
        id: main
        x: banner.x + banner.width + Theme.u * 4
        y: banner.y + Theme.u * 2
        width: parent.width - x - Theme.u * 5
        height: banner.height - Theme.u * 3

        Rectangle {
            id: searchPill
            width: parent.width
            height: Theme.u * 15
            radius: height / 2
            color: "#ffffff"
            border.width: Math.max(1, Theme.u / 2)
            border.color: root.ink
            PxIcon {
                id: searchIcon
                x: Theme.u * 5
                anchors.verticalCenter: parent.verticalCenter
                name: "heartSmall"
                fill: root.pink
                ink: root.ink
            }
            PxField {
                id: field
                keepFocus: true
                anchors.left: searchIcon.right
                anchors.leftMargin: Theme.u * 2
                anchors.right: parent.right
                anchors.rightMargin: Theme.u * 6
                anchors.verticalCenter: parent.verticalCenter
                placeholder: I18n.t("найти… ♡", "find… ♡")
                onEdited: {
                    root.query = text;
                    root.current = text ? 0 : -1;
                }
                onAccepted: root.runRow(root.rows[Math.max(0, root.current)])
                onKeyPressed: e => root.nav(e)
            }
        }

        // the pinned apps as stickers
        Grid {
            id: stickers
            visible: !root.searching && root.pins.length > 0
            y: searchPill.height + Theme.u * 5
            width: parent.width
            columns: 4
            readonly property real cell: Math.floor((width - columnSpacing * 3) / 4)
            columnSpacing: Theme.u * 2
            rowSpacing: Theme.u * 3
            Repeater {
                model: root.pins
                Item {
                    id: st
                    required property var modelData
                    width: stickers.cell
                    height: plate.height + bubble.height + Theme.u * 2
                    // the hard sticker shadow
                    Rectangle {
                        x: plate.x + Theme.u
                        y: plate.y + Theme.u
                        width: plate.width
                        height: plate.height
                        radius: plate.radius
                        color: Qt.alpha(root.ink, 0.35)
                    }
                    Rectangle {
                        id: plate
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(st.width, Theme.u * 24)
                        height: width
                        radius: Theme.u * 4
                        color: "#ffffff"
                        border.width: Theme.u
                        border.color: sm.containsMouse ? root.lilac : root.pink
                        scale: sm.pressed ? 0.92 : sm.containsMouse ? 1.06 : 1
                        rotation: sm.containsMouse ? -3 : 0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 90
                            }
                        }
                        Behavior on rotation {
                            NumberAnimation {
                                duration: 90
                            }
                        }
                        AppIcon {
                            anchors.centerIn: parent
                            iconName: st.modelData.icon || ""
                            appId: st.modelData.id || ""
                            size: Math.round(plate.width * 0.62)
                        }
                    }
                    Rectangle {
                        id: bubble
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: plate.bottom
                        anchors.topMargin: Theme.u * 2
                        width: Math.min(st.width, stLabel.implicitWidth + Theme.u * 4)
                        height: stLabel.implicitHeight + Theme.u
                        radius: height / 2
                        color: root.pink
                        PxText {
                            id: stLabel
                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, st.width - Theme.u * 4)
                            elide: Text.ElideRight
                            kind: "tiny"
                            color: root.ink
                            text: st.modelData.name
                        }
                    }
                    MouseArea {
                        id: sm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: m => m.button === Qt.RightButton ? StartApps.togglePin(st.modelData) : root.act(() => StartApps.launch(st.modelData))
                    }
                }
            }
        }
        // ♡ every program ♡
        PxText {
            id: divider
            y: stickers.visible ? stickers.y + stickers.height + Theme.u * 4 : searchPill.height + Theme.u * 4
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            kind: "tiny"
            font.bold: true
            color: root.searching ? root.paperText : Theme.mix(root.paperText, root.pink, 0.4)
            text: root.searching ? I18n.t("♡ нашлось ♡", "♡ found ♡") : I18n.t("· · ♡ все программы ♡ · ·", "· · ♡ every program ♡ · ·")
        }
        ListView {
            id: list
            y: divider.y + divider.height + Theme.u * 2
            width: parent.width - scroll.width - Theme.u * 2
            height: parent.height - y
            clip: true
            model: root.rows
            boundsBehavior: Flickable.StopAtBounds
            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                readonly property bool sel: index === root.current || rm.containsMouse
                width: list.width
                height: Theme.u * 13
                radius: height / 2
                color: sel ? Qt.alpha(root.pink, 0.75) : "transparent"
                PxIcon {
                    id: bullet
                    x: Theme.u * 3
                    anchors.verticalCenter: parent.verticalCenter
                    name: "heartSmall"
                    pixel: Math.max(1, Theme.u / 2)
                    fill: row.sel ? "#ffffff" : root.pink
                    ink: root.ink
                }
                AppIcon {
                    id: appGlyph
                    visible: !!row.modelData.app
                    anchors.left: bullet.right
                    anchors.leftMargin: Theme.u * 2
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: row.modelData.app ? row.modelData.app.icon || "" : ""
                    appId: row.modelData.app ? row.modelData.app.id || "" : ""
                    size: Theme.u * 9
                }
                PxIcon {
                    id: pxGlyph
                    visible: !row.modelData.app
                    anchors.left: bullet.right
                    anchors.leftMargin: Theme.u * 2
                    anchors.verticalCenter: parent.verticalCenter
                    name: row.modelData.icon || "heart"
                    pixel: Math.max(1, Theme.u / 2)
                }
                PxText {
                    anchors.left: bullet.right
                    anchors.leftMargin: Theme.u * 13
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.u * 3
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    color: row.sel ? root.ink : root.paperText
                    font.bold: row.sel
                    text: row.modelData.label
                }
                MouseArea {
                    id: rm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: m => {
                        if (m.button === Qt.RightButton && row.modelData.app)
                            StartApps.togglePin(row.modelData.app);
                        else
                            root.runRow(row.modelData);
                    }
                }
            }
        }
        // the heart scroll bar
        Rectangle {
            id: scroll
            anchors.right: parent.right
            y: list.y
            width: Theme.u * 7
            height: list.height
            radius: width / 2
            color: Qt.alpha(root.lilac, 0.45)
            visible: list.contentHeight > list.height
            PxIcon {
                readonly property real room: scroll.height - height
                anchors.horizontalCenter: parent.horizontalCenter
                y: list.contentHeight > list.height ? room * list.contentY / (list.contentHeight - list.height) : 0
                name: "heart"
                pixel: Math.max(1, Theme.u / 2)
                fill: root.pink
                ink: root.ink
            }
            MouseArea {
                anchors.fill: parent
                onPressed: m => list.contentY = Math.max(0, Math.min(list.contentHeight - list.height, (m.y / height) * (list.contentHeight - list.height)))
                onPositionChanged: m => list.contentY = Math.max(0, Math.min(list.contentHeight - list.height, (m.y / height) * (list.contentHeight - list.height)))
            }
        }
    }

    // ---- user + power ----
    Rectangle {
        id: footer
        x: Theme.u * 2
        y: parent.height - height - Theme.u * 2
        width: parent.width - Theme.u * 4
        height: Theme.u * 18
        color: Theme.mix(root.paper, root.pink, 0.35)
        border.width: Math.max(1, Theme.u / 2)
        border.color: root.ink
        Row {
            x: Theme.u * 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u * 3
            Rectangle {
                width: Theme.u * 12
                height: width
                radius: width / 2
                color: "#ffffff"
                border.width: Math.max(1, Theme.u / 2)
                border.color: root.ink
                PxIcon {
                    anchors.centerIn: parent
                    name: "heart"
                    pixel: Math.max(1, Theme.u / 2)
                    fill: root.pink
                    ink: root.ink
                }
            }
            PxText {
                anchors.verticalCenter: parent.verticalCenter
                font.bold: true
                color: root.paperText
                text: StartApps.userName
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.u * 3
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u * 2
            Repeater {
                model: [
                    {
                        "icon": "gear",
                        "run": () => Shell.openSettings("")
                    },
                    {
                        "icon": "lock",
                        "run": () => Shell.lock()
                    },
                    {
                        "icon": "power",
                        "run": () => Shell.sessionOpen = true
                    }
                ]
                Rectangle {
                    id: fb
                    required property var modelData
                    width: Theme.u * 13
                    height: width
                    radius: width / 2
                    color: fbm.containsMouse ? root.pink : "#ffffff"
                    border.width: Math.max(1, Theme.u / 2)
                    border.color: root.ink
                    PxIcon {
                        anchors.centerIn: parent
                        name: fb.modelData.icon
                        pixel: Math.max(1, Theme.u / 2)
                        ink: root.ink
                        fill: root.pink
                    }
                    MouseArea {
                        id: fbm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.act(fb.modelData.run)
                    }
                }
            }
        }
    }
}
