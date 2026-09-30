import QtQuick
import qs.config
import qs.services
import qs.widgets

// ♪ title — artist + transport.
Row {
    id: root

    property int maxWidth: Theme.u * 160
    property bool showTitle: true
    readonly property var player: Lyrics.player

    visible: !!player && Lyrics.title !== "" && Config.bar.showMedia
    spacing: Theme.u * 2

    PxButton {
        compact: true
        flat: true
        icon: "prev"
        iconPixel: Math.max(1, Theme.u - 1)
        onClicked: root.player.previous()
    }
    PxButton {
        compact: true
        flat: true
        icon: root.player && root.player.isPlaying ? "pause" : "play"
        iconPixel: Math.max(1, Theme.u - 1)
        onClicked: root.player.togglePlaying()
    }
    PxButton {
        compact: true
        flat: true
        icon: "next"
        iconPixel: Math.max(1, Theme.u - 1)
        onClicked: root.player.next()
    }
    Item {
        visible: root.showTitle && root.maxWidth > 0
        width: Math.min(label.implicitWidth + note.width + Theme.u * 4, root.maxWidth)
        height: parent.height
        PxIcon {
            id: note
            name: "music"
            pixel: Math.max(1, Theme.u - 1)
            anchors.verticalCenter: parent.verticalCenter
        }
        PxText {
            id: label
            anchors.left: note.right
            anchors.leftMargin: Theme.u * 3
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Lyrics.title + (Lyrics.artist ? " — " + Lyrics.artist : "")
            elide: Text.ElideRight
        }
        // left: lyrics on/off, right: pause / play
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: m => {
                if (m.button === Qt.RightButton)
                    root.player.togglePlaying();
                else
                    Lyrics.visibleToggle = !Lyrics.visibleToggle;
            }
        }
    }
}
