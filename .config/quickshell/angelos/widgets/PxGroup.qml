import QtQuick
import qs.config

// Win98 group box: etched frame with the title cut into the top edge.
// `advanced` groups fold into a "▸ Дополнительно" header in the simple settings
// view (Settings → Эксперт off); clicking the header unfolds them.
Item {
    id: root

    property string title: ""
    property string icon: ""
    readonly property string settingsSkin: Theme.settingsSkinFor(root.parent)
    property int spacing: Theme.u * 5
    property bool advanced: false
    property bool open: false
    readonly property bool folded: advanced && !open && !Config.settingsUi.expert
    default property alias content: col.data

    implicitWidth: col.implicitWidth + Theme.pad * 2
    implicitHeight: root.settingsSkin === "classic" ? folded ? head.height + Theme.u * 4 : col.implicitHeight + head.height + Theme.pad * 2 : folded ? head.y + head.height + Theme.u * 5 : col.y + col.implicitHeight + Theme.pad

    readonly property int lineY: head.height / 2
    readonly property int b: Math.max(1, Theme.u / 2)

    Rectangle {
        visible: root.settingsSkin !== "classic"
        anchors.fill: parent
        radius: root.settingsSkin === "stream" ? Theme.u * 3 : 0
        color: root.settingsSkin === "stream" ? Theme.streamPanel : Theme.windosePaper
        border.width: Math.max(1, Theme.u / 2)
        border.color: root.settingsSkin === "stream" ? Theme.mix(Theme.streamLive, Theme.streamPanel, 0.38) : Theme.windoseLine
    }
    Rectangle {
        visible: root.settingsSkin !== "classic"
        x: Theme.u
        y: Theme.u
        width: root.width - Theme.u * 2
        height: head.height + Theme.u * 4
        radius: root.settingsSkin === "stream" ? Theme.u * 2 : 0
        color: root.settingsSkin === "stream" ? Theme.mix(Theme.streamPanel, Theme.streamLive, 0.14) : Theme.mix(Theme.windosePaper, Theme.windoseRose, 0.22)
    }

    // etched frame: lo line + hi line offset by one
    Repeater {
        model: root.settingsSkin === "classic" ? 2 : 0
        Item {
            required property int index
            readonly property color c: index === 0 ? Theme.lo : Theme.hi
            readonly property int o: index * root.b
            x: o
            y: root.lineY + o
            width: root.width - root.b
            height: root.height - root.lineY - root.b
            Rectangle { x: 0; y: 0; width: Theme.u * 4; height: root.b; color: parent.c }
            Rectangle { x: head.x + head.width + Theme.u * 2 - parent.o; y: 0; width: Math.max(0, parent.width - x); height: root.b; color: parent.c }
            Rectangle { x: 0; y: 0; width: root.b; height: parent.height; color: parent.c }
            Rectangle { x: parent.width - root.b; y: 0; width: root.b; height: parent.height; color: parent.c }
            Rectangle { x: 0; y: parent.height - root.b; width: parent.width; height: root.b; color: parent.c }
        }
    }

    Row {
        id: head
        x: Theme.u * 6
        y: root.settingsSkin === "classic" ? 0 : Theme.u * 3
        spacing: Theme.u * 3
        leftPadding: Theme.u * 2
        rightPadding: Theme.u * 2
        PxIcon {
            visible: root.icon !== ""
            name: root.icon || "heart"
            anchors.verticalCenter: parent.verticalCenter
            ink: root.settingsSkin === "stream" ? Theme.streamLive : root.settingsSkin === "windose" ? Theme.windoseRose : Theme.dark ? Theme.text : Theme.edge
        }
        PxText {
            visible: root.advanced && !Config.settingsUi.expert
            text: root.folded ? "▸" : "▾"
            kind: "title"
            color: Theme.dark ? Theme.accent : Theme.edge
            anchors.verticalCenter: parent.verticalCenter
        }
        PxText {
            text: root.title
            kind: "title"
            color: root.settingsSkin === "stream" ? Theme.streamText : root.settingsSkin === "windose" ? Theme.windoseInk : Theme.dark ? Theme.accent : Theme.edge
            font.bold: root.settingsSkin !== "classic"
            anchors.verticalCenter: parent.verticalCenter
        }
        PxText {
            visible: root.folded
            text: I18n.t("· дополнительно", "· advanced")
            kind: "tiny"
            dim: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    MouseArea {
        visible: root.advanced && !Config.settingsUi.expert
        x: head.x
        y: head.y
        width: head.width
        height: head.height
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open = !root.open
    }

    Column {
        id: col
        readonly property bool fixedWidth: true // PxToggle wraps its label to fit
        visible: !root.folded
        x: Theme.pad
        y: head.y + head.height + Theme.u * 4
        width: root.width - Theme.pad * 2
        spacing: root.spacing
    }
}
