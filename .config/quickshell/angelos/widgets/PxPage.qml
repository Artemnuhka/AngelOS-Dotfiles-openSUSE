import QtQuick
import qs.config
import qs.services
import qs.widgets

// Scrollable settings page: a column of PxGroups, and at the bottom "Reset this
// page" for the settings the page shows (services/SettingsKeys) — asks once
// more before it resets; "Undo" at the top brings everything back.
// Like macOS: at the top the way up ("‹ Sound" on a sub-page), then a card of links
// ("Title ›") to the section's other pages and to this page's advanced groups, which
// open on their own (focusGroup = Shell.settingsSub: the rest of the page steps aside).
PxScroll {
    id: root

    property string heading: ""
    property string subtitle: ""
    readonly property string settingsSkin: Theme.settingsSkinFor(root.parent)
    property color headingColor: settingsSkin === "windose" ? Theme.windoseTitle : settingsSkin === "stream" ? Theme.streamLive : Theme.dark ? Theme.accent : Theme.edge
    property color subtitleColor: Theme.textDim
    default property alias items: col.data
    readonly property int innerWidth: col.width
    // the settings page this is (plugin pages and the home tiles have nothing to reset)
    property string pageId: Shell.settingsPage
    readonly property var changed: SettingsKeys.loaded ? SettingsKeys.changedOn(pageId) : []
    property bool confirming: false
    property int resetCount: -1
    // the sub-page open on this page: one of its advanced groups (PxGroup steps the others aside)
    readonly property string focusGroup: pageId === Shell.settingsPage ? Shell.settingsSub : ""
    readonly property var view: Shell.settingsView
    // the properties view shows the section's pages and the sub-pages as its tabs
    readonly property bool tabsOutside: !!view && view.ownsSubpages === true && pageId === Shell.settingsPage
    // the way up: from a sub-page to its page, from a section's other page to its first one
    readonly property var up: {
        if (focusGroup !== "")
            return {
                "label": heading,
                "page": pageId,
                "sub": ""
            };
        const parentId = view && view.parentOf ? view.parentOf(pageId) : "";
        return parentId ? {
            "label": view.labelOf(parentId),
            "page": parentId,
            "sub": ""
        } : null;
    }
    // the links at the top: the section's other pages, then this page's advanced groups
    readonly property var advancedGroups: Array.from(col.children).filter(c => c.advanced === true && c.title && c.shown !== false)
    readonly property var links: focusGroup !== "" || tabsOutside ? [] : (view && view.subpagesOf ? view.subpagesOf(pageId) : []).map(p => ({
                "label": p.label,
                "icon": p.icon,
                "tint": view.tintOf(p.id),
                "page": p.id,
                "sub": ""
            })).concat(advancedGroups.map(g => ({
                "label": g.title,
                "icon": g.icon || "gear",
                "tint": "",
                "page": pageId,
                "sub": g.title
            })))
    function go(l) {
        if (!l)
            return;
        if (Shell.settingsPage !== l.page)
            Shell.settingsPage = l.page;
        Shell.settingsSub = l.sub || "";
        scrollBy(-flick.contentY);
    }
    // everything else on the page steps aside while a sub-page is open
    Component {
        id: asideBinding
        Binding {
            property: "visible"
            value: false
            restoreMode: Binding.RestoreBindingOrValue
        }
    }
    property var _aside: []
    function bindAside() {
        for (const c of col.children) {
            if (c === head || c === linkCard || c.advanced !== undefined || root._aside.indexOf(c) >= 0)
                continue;
            root._aside.push(c);
            asideBinding.createObject(root, {
                "target": c,
                "when": Qt.binding(() => root.focusGroup !== "")
            });
        }
    }
    Connections {
        target: col
        function onChildrenChanged() {
            Qt.callLater(root.bindAside);
        }
    }

    contentHeight: col.implicitHeight + (footer.visible ? footer.height + Theme.u * 8 : 0) + Theme.u * 10

    Column {
        id: col
        x: Theme.u * 4
        y: Theme.u * 4
        width: parent.width - Theme.u * 8
        spacing: Theme.u * (root.settingsSkin === "stream" ? 6 : 8)

        Column {
            id: head
            visible: root.heading !== ""
            width: parent.width
            spacing: Theme.u * (root.settingsSkin === "classic" ? 1 : 2)
            // "‹ Sound": up to the page or the section this is part of
            PxText {
                id: upLink
                visible: !!root.up && !root.tabsOutside
                text: "‹ " + (root.up ? root.up.label : "")
                color: upMouse.containsMouse ? Theme.accent : Theme.textDim
                font.bold: true
                MouseArea {
                    id: upMouse
                    anchors.fill: parent
                    anchors.margins: -Theme.u * 2
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.go(root.up)
                }
            }
            PxText {
                visible: root.settingsSkin !== "classic"
                text: root.settingsSkin === "stream" ? "● LIVE  /  angelOS" : "▸ settings.exe / angelOS"
                kind: "tiny"
                color: root.settingsSkin === "stream" ? Theme.streamLive : Theme.windoseLavender
                font.bold: true
            }
            PxText {
                text: root.focusGroup || root.heading
                kind: "big"
                color: root.headingColor
            }
            Rectangle {
                visible: root.settingsSkin !== "classic"
                width: parent.width
                height: Theme.u * (root.settingsSkin === "stream" ? 2 : 1)
                color: root.settingsSkin === "stream" ? Theme.streamLive : Theme.windoseRose
            }
            PxText {
                visible: root.subtitle !== "" && root.focusGroup === ""
                width: parent.width
                text: root.subtitle
                color: root.subtitleColor
                wrapMode: Text.Wrap
            }
        }

        // "Title ›": the section's other pages and this page's sub-pages, one card
        PxBox {
            id: linkCard
            visible: root.links.length > 0
            width: parent.width
            height: links.implicitHeight + inset * 2
            color: root.settingsSkin === "classic" ? Theme.mix(Theme.face, Theme.faceAlt, 0.35) : root.settingsSkin === "stream" ? Theme.streamPanel : Theme.windosePaper
            Column {
                id: links
                width: parent.width
                Repeater {
                    model: root.links
                    Item {
                        id: link
                        required property var modelData
                        required property int index
                        width: links.width
                        height: Theme.u * 17
                        Rectangle {
                            anchors.fill: parent
                            color: lm.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.16) : "transparent"
                        }
                        Rectangle {
                            visible: link.index > 0
                            x: Theme.u * 18
                            width: parent.width - x - Theme.u * 3
                            height: Math.max(1, Theme.u / 2)
                            color: Qt.alpha(Theme.lo, Theme.dark ? 0.9 : 0.55)
                        }
                        Row {
                            x: Theme.u * 4
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.u * 4
                            SettingsTile {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: link.modelData.icon
                                tint: link.modelData.tint || Theme.mix(Theme.accent, Theme.face, 0.25)
                            }
                            PxText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: link.modelData.label
                            }
                        }
                        PxText {
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.u * 5
                            anchors.verticalCenter: parent.verticalCenter
                            text: "›"
                            kind: "title"
                            dim: true
                        }
                        MouseArea {
                            id: lm
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.go(link.modelData)
                        }
                    }
                }
            }
        }
    }

    Row {
        id: footer
        visible: root.pageId !== "home" && root.pageId !== "more" && SettingsKeys.keysOf(root.pageId).length > 0 && (root.changed.length > 0 || root.resetCount >= 0)
        x: col.x
        y: col.y + col.implicitHeight + Theme.u * 8
        spacing: Theme.u * 4
        PxButton {
            compact: true
            danger: root.confirming
            icon: "refresh"
            enabled: root.changed.length > 0
            text: root.confirming ? I18n.t("Точно сбросить? Нажми ещё раз", "Sure? Click again") : I18n.t("Сбросить эту страницу", "Reset this page")
            onClicked: {
                if (!root.confirming) {
                    root.confirming = true;
                    unconfirm.restart();
                    return;
                }
                root.confirming = false;
                root.resetCount = Config.resetKeys(root.changed);
            }
        }
        PxText {
            anchors.verticalCenter: parent.verticalCenter
            kind: "tiny"
            dim: true
            text: root.resetCount >= 0 && root.changed.length === 0 ? I18n.t("Сброшено ♡ «Отменить» вверху вернёт как было", "Reset ♡ “Undo” at the top brings it back") : I18n.t("изменено здесь: ", "changed here: ") + root.changed.length
        }
    }
    Timer {
        id: unconfirm
        interval: 4000
        onTriggered: root.confirming = false
    }
    Component.onCompleted: {
        SettingsKeys.load();
        bindAside();
    }
}
