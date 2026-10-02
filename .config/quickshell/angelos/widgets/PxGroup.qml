import QtQuick
import qs.config

// A group of settings. Classic: like macOS's System Settings — a caption above a raised
// pixel card that holds the rows (SettingRow draws the hairlines between them); Windose
// and Stream: their own boxes.
// `advanced` groups are sub-pages (the macOS "Title ›"): on their page they are not shown,
// the page lists them as links at its top (PxPage) and opens one on its own
// (Shell.settingsSub = its title); then the other groups of the page step aside. An
// advanced group that is only there sometimes says so with `shown`, not `visible`.
Item {
    id: root

    property string title: ""
    property string icon: ""
    readonly property string settingsSkin: Theme.settingsSkinFor(root.parent)
    property int spacing: Theme.u * 5
    property bool advanced: false
    property bool shown: true
    default property alias content: col.data

    // the page this is on (PxPage: focusGroup), if any
    readonly property var page: {
        for (let p = root.parent; p; p = p.parent)
            if (p.focusGroup !== undefined)
                return p;
        return null;
    }
    readonly property string openSub: page ? page.focusGroup : ""
    // a sub-page that isn't the one open, or another group while a sub-page is open
    readonly property bool steppedAside: !!page && (openSub !== "" ? title !== openSub : advanced)
    Binding {
        target: root
        property: "visible"
        value: root.shown && !root.steppedAside
        when: root.steppedAside || (root.advanced && root.openSub === root.title)
        restoreMode: Binding.RestoreBindingOrValue
    }

    readonly property bool classic: settingsSkin === "classic"
    readonly property int b: Math.max(1, Theme.u / 2)
    implicitWidth: col.implicitWidth + Theme.pad * 2
    implicitHeight: classic ? card.y + col.implicitHeight + Theme.pad * 2 : col.y + col.implicitHeight + Theme.pad

    // ---- Windose / Stream ----
    Rectangle {
        visible: !root.classic
        anchors.fill: parent
        radius: root.settingsSkin === "stream" ? Theme.u * 3 : 0
        color: root.settingsSkin === "stream" ? Theme.streamPanel : Theme.windosePaper
        border.width: Math.max(1, Theme.u / 2)
        border.color: root.settingsSkin === "stream" ? Theme.mix(Theme.streamLive, Theme.streamPanel, 0.38) : Theme.windoseLine
    }
    Rectangle {
        visible: !root.classic
        x: Theme.u
        y: Theme.u
        width: root.width - Theme.u * 2
        height: head.height + Theme.u * 4
        radius: root.settingsSkin === "stream" ? Theme.u * 2 : 0
        color: root.settingsSkin === "stream" ? Theme.mix(Theme.streamPanel, Theme.streamLive, 0.14) : Theme.mix(Theme.windosePaper, Theme.windoseRose, 0.22)
    }

    // ---- classic: the card under the caption ----
    PxBox {
        id: card
        visible: root.classic
        y: head.height + Theme.u * 2
        width: root.width
        height: root.height - y
        color: Theme.mix(Theme.face, Theme.faceAlt, 0.35)
    }

    Row {
        id: head
        // open as a sub-page, its title is the page's heading already
        visible: root.openSub !== root.title
        height: visible ? implicitHeight : 0
        x: root.classic ? Theme.u * 2 : Theme.u * 6
        y: root.classic ? 0 : Theme.u * 3
        spacing: Theme.u * 3
        leftPadding: root.classic ? 0 : Theme.u * 2
        rightPadding: Theme.u * 2
        PxIcon {
            visible: root.icon !== ""
            name: root.icon || "heart"
            anchors.verticalCenter: parent.verticalCenter
            pixel: root.classic ? Math.max(1, Theme.u - 1) : Theme.u
            ink: root.settingsSkin === "stream" ? Theme.streamLive : root.settingsSkin === "windose" ? Theme.windoseRose : Theme.textDim
        }
        PxText {
            text: root.title
            kind: root.classic ? "body" : "title"
            color: root.settingsSkin === "stream" ? Theme.streamText : root.settingsSkin === "windose" ? Theme.windoseInk : Theme.textDim
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Column {
        id: col
        readonly property bool fixedWidth: true // PxToggle wraps its label to fit
        x: Theme.pad
        y: root.classic ? card.y + Theme.pad : head.y + head.height + Theme.u * 4
        width: root.width - Theme.pad * 2
        spacing: root.spacing
    }
}
