import QtQuick
import qs.config
import qs.services
import qs.widgets

// Cover, track and controls of the current MPRIS player.
Item {
    id: root

    property string screenName
    property var widget
    readonly property var p: Lyrics.player
    property real pos: 0

    implicitWidth: Theme.u * 150
    implicitHeight: Theme.u * 44

    Timer {
        interval: 1000
        running: root.visible && !!root.p && root.p.isPlaying
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.p.positionChanged();
            root.pos = root.p.position;
        }
    }

    PxText {
        visible: !root.p || !Lyrics.title
        anchors.centerIn: parent
        text: I18n.t("ничего не играет ♡", "nothing is playing ♡")
        dim: true
    }

    Row {
        visible: !!root.p && !!Lyrics.title
        anchors.fill: parent
        spacing: Theme.u * 5

        PxBox {
            width: parent.height
            height: parent.height
            sunken: true
            color: Theme.sunken
            Image {
                anchors.fill: parent
                source: root.p ? (root.p.trackArtUrl || "") : ""
                sourceSize: Qt.size(Theme.u * 24, Theme.u * 24)   // tiny source + no smoothing = pixel cover
                fillMode: Image.PreserveAspectCrop
                smooth: false
                asynchronous: true
            }
        }
        Column {
            width: parent.width - parent.height - Theme.u * 5
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u * 2
            PxText {
                width: parent.width
                text: Lyrics.title
                font.bold: true
                elide: Text.ElideRight
            }
            PxText {
                width: parent.width
                text: Lyrics.artist
                dim: true
                elide: Text.ElideRight
            }
            PxBox {
                width: parent.width
                height: Theme.u * 4
                sunken: true
                color: Theme.sunken
                Rectangle {
                    height: parent.height
                    width: root.p && root.p.length > 0 ? parent.width * Math.min(1, root.pos / root.p.length) : 0
                    color: Theme.accent
                }
            }
            Row {
                spacing: Theme.u * 2
                PxButton {
                    compact: true
                    icon: "prev"
                    iconPixel: Math.max(1, Theme.u - 1)
                    onClicked: root.p.previous()
                }
                PxButton {
                    compact: true
                    icon: root.p && root.p.isPlaying ? "pause" : "play"
                    iconPixel: Math.max(1, Theme.u - 1)
                    onClicked: root.p.togglePlaying()
                }
                PxButton {
                    compact: true
                    icon: "next"
                    iconPixel: Math.max(1, Theme.u - 1)
                    onClicked: root.p.next()
                }
            }
        }
    }
}
