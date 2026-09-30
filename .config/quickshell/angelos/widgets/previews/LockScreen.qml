pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.widgets

// The lock screen's options (Settings → Lock): pixelate | hearts | reactions |
// indicators | stream. A small lock screen with the clock and the password box;
// the option being shown plays on top of it.
Scene {
    id: root

    readonly property int typed: variant === "reactions" ? Math.min(5, Math.floor(seg(0.1, 0.55) * 6)) : Math.floor(seg(0.2, 0.8) * 4)
    readonly property bool mistake: variant === "reactions" && t > 0.62 && t < 0.8

    // the wallpaper: soft blobs, or big pixel blocks when pixelated
    Grid {
        anchors.fill: parent
        columns: root.variant === "pixelate" ? 8 : 32
        readonly property int rowsN: root.variant === "pixelate" ? 5 : 20
        Repeater {
            model: parent.columns * parent.rowsN
            Rectangle {
                required property int index
                readonly property int c: index % parent.columns
                readonly property int r: Math.floor(index / parent.columns)
                width: root.width / parent.columns
                height: root.height / parent.rowsN
                readonly property real u: (c + 0.5) / parent.columns
                readonly property real v: (r + 0.5) / parent.rowsN
                color: Theme.mix(Theme.mix(Theme.desk, Theme.accent, 0.35 + 0.3 * Math.sin(u * 5 + v * 3)), Theme.accent2, 0.25 + 0.25 * Math.cos(u * 7 - v * 4))
            }
        }
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha("#000000", 0.25)
    }

    // clock and password box
    Column {
        anchors.centerIn: parent
        spacing: Theme.u * 2
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "12:00"
            kind: "title"
            color: "#ffffff"
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.width * 0.36
            height: Theme.u * 9
            color: Theme.face
            border.width: Math.max(1, Theme.u / 2)
            border.color: root.mistake ? Theme.danger : Theme.edge
            x: root.mistake ? Math.sin(root.t * 90) * Theme.u : 0
            Row {
                anchors.centerIn: parent
                spacing: Theme.u
                Repeater {
                    model: root.typed
                    PxIcon {
                        name: "heartSmall"
                        pixel: 1
                    }
                }
            }
        }
    }

    // floating hearts
    Repeater {
        model: root.variant === "hearts" ? 7 : 0
        PxIcon {
            required property int index
            name: index % 3 ? "heartSmall" : "heart"
            pixel: Math.max(1, Math.round(Theme.u / 2))
            x: root.width * ((index * 0.137 + 0.08) % 0.9)
            y: root.height - ((root.t * root.height * 1.2 + index * root.height * 0.19) % (root.height * 1.1))
            opacity: 0.8
        }
    }
    // reactions: a heart pops per character, a broken one on the mistake
    PxIcon {
        visible: root.variant === "reactions" && root.typed > 0 && !root.mistake && root.t < 0.6
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * 0.3 - (root.t * 40 % 10) * Theme.u / 2
        name: "heart"
        pixel: Theme.u
    }
    PxIcon {
        visible: root.mistake
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height * 0.28
        name: "heartBroken"
        pixel: Theme.u
    }
    // indicators row
    Row {
        visible: root.variant === "indicators"
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.u * 3
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.u * 3
        opacity: root.seg(0.1, 0.3)
        PxText {
            text: "CAPS"
            kind: "tiny"
            color: root.t > 0.5 ? Theme.accent3 : "#ffffff"
        }
        PxText {
            text: "EN"
            kind: "tiny"
            color: "#ffffff"
        }
        PxText {
            text: "87%"
            kind: "tiny"
            color: "#ffffff"
        }
        PxIcon {
            name: "bell"
            pixel: 1
        }
    }
    // the NGO stream: LIVE, viewers, a chat
    Rectangle {
        visible: root.variant === "stream"
        x: Theme.u * 3
        y: Theme.u * 3
        width: live.implicitWidth + Theme.u * 4
        height: live.implicitHeight + Theme.u * 2
        color: Theme.danger
        opacity: Math.floor(root.t * 8) % 2 ? 1 : 0.75
        PxText {
            id: live
            anchors.centerIn: parent
            text: "● LIVE  " + (1200 + Math.floor(root.t * 90))
            kind: "tiny"
            color: "#ffffff"
        }
    }
    Column {
        visible: root.variant === "stream"
        x: root.width - width - Theme.u * 3
        y: Theme.u * 3
        width: root.width * 0.3
        spacing: Theme.u
        Repeater {
            model: Math.min(4, 1 + Math.floor(root.t * 5))
            Rectangle {
                required property int index
                width: parent.width * [0.9, 0.7, 0.8, 0.6][index]
                height: Theme.u * 3
                color: Qt.alpha("#ffffff", 0.7)
            }
        }
    }
}
