import QtQuick
import qs.config

Item {
    id: root

    property string text: ""
    property string icon: ""
    property bool checked: false
    property bool checkable: false
    property bool accent: false
    property bool danger: false
    property bool flat: false
    property bool compact: false
    property bool hell: false              // hell's palette (Theme.realm): obsidian, blood, bone text
    readonly property string settingsSkin: root.hell ? "classic" : Theme.settingsSkinFor(root.parent)
    property int iconPixel: Theme.u
    property bool middleButton: false      // also report middle clicks (task buttons close windows with them)
    property string kind: "body"
    property alias hovered: mouse.containsMouse
    property alias pressed: mouse.pressed
    readonly property bool down: mouse.pressed || checked
    signal clicked
    signal rightClicked
    signal middleClicked

    // left + right padding; -1 = by `compact` (the bar's dense right side sets it)
    property real hpad: -1
    implicitWidth: row.implicitWidth + (hpad >= 0 ? hpad : compact ? Theme.u * 6 : Theme.pad * 2 + Theme.u * 2)
    implicitHeight: Math.max(row.implicitHeight + Theme.u * (compact ? 5 : 8), Theme.u * (compact ? 11 : 15))
    opacity: enabled ? 1 : 0.45

    PxBox {
        anchors.fill: parent
        visible: root.settingsSkin === "classic" && (!root.flat || mouse.containsMouse || root.checked)
        sunken: root.down
        hell: root.hell
        color: root.hell ? (root.accent ? (mouse.containsMouse ? Qt.lighter(Theme.hellBlood, 1.15) : Theme.hellBlood) : root.checked ? Theme.mix(Theme.hellFace, Theme.hellBlood, 0.45) : mouse.containsMouse ? Theme.mix(Theme.hellFace, Theme.hellEmber, 0.2) : Theme.hellFace) : root.accent ? (mouse.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent) : root.danger && mouse.containsMouse ? Theme.danger : root.checked ? Theme.mix(Theme.face, Theme.accent, Theme.dark ? 0.4 : 0.3) : mouse.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.12) : Theme.face
    }

    Rectangle {
        visible: root.settingsSkin === "windose"
        x: Theme.u
        y: Theme.u
        width: parent.width - Theme.u
        height: parent.height - Theme.u
        radius: height / 2
        color: Qt.alpha(Theme.shadow, Theme.dark ? 0.25 : 0.12)
    }
    Rectangle {
        visible: root.settingsSkin === "windose"
        x: root.down ? Theme.u : 0
        y: root.down ? Theme.u : 0
        width: parent.width - Theme.u
        height: parent.height - Theme.u
        radius: height / 2
        color: root.danger ? Theme.danger : root.accent || root.checked ? Theme.windoseRose : mouse.containsMouse ? Theme.mix(Theme.windoseSticker, Theme.windoseLavender, 0.24) : Theme.windoseSticker
        border.width: Math.max(1, Theme.u / 2)
        border.color: Theme.windoseLine
    }
    Rectangle {
        visible: root.settingsSkin === "stream"
        anchors.fill: parent
        anchors.margins: root.down ? Theme.u : 0
        radius: Theme.u * 2
        color: root.danger ? Theme.danger : root.accent || root.checked ? Theme.streamLive : mouse.containsMouse ? Theme.mix(Theme.streamPanel, Theme.streamLive, 0.2) : Theme.streamPanel
        border.width: Math.max(1, Theme.u / 2)
        border.color: root.danger ? Theme.danger : Theme.streamLive
        Rectangle {
            width: Theme.u * 2
            height: parent.height
            radius: Theme.u
            color: root.danger ? Theme.danger : Theme.streamLive
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.down ? Theme.u : 0
        anchors.verticalCenterOffset: root.down ? Theme.u : 0
        spacing: Theme.u * 3

        PxIcon {
            visible: root.icon !== ""
            name: root.icon || "heart"
            pixel: root.iconPixel
            anchors.verticalCenter: parent.verticalCenter
            ink: root.hell ? Theme.hellText : root.settingsSkin !== "classic" ? (root.accent || root.checked ? Theme.selectText : Theme.text) : root.accent ? Theme.selectText : (Theme.dark ? Theme.text : Theme.edge)
        }
        PxText {
            visible: root.text !== ""
            text: root.text
            kind: root.kind
            anchors.verticalCenter: parent.verticalCenter
            color: root.hell ? Theme.hellText : root.settingsSkin !== "classic" ? (root.danger ? "#ffffff" : root.accent || root.checked ? Theme.selectText : Theme.text) : root.accent ? Theme.selectText : root.danger && mouse.containsMouse ? "#ffffff" : Theme.text
            font.bold: root.checked
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton | Qt.RightButton | (root.middleButton ? Qt.MiddleButton : 0)
        cursorShape: Qt.PointingHandCursor
        onClicked: e => {
            if (e.button === Qt.RightButton) {
                root.rightClicked();
                return;
            }
            if (e.button === Qt.MiddleButton) {
                root.middleClicked();
                return;
            }
            if (root.checkable)
                root.checked = !root.checked;
            root.clicked();
        }
    }
}
