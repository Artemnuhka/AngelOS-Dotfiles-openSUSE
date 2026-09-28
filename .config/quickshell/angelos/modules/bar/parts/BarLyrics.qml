import QtQuick
import qs.config
import qs.services
import qs.widgets

// Current lyric line in the middle of the bar: typewriter reveal, old line slides away.
Item {
    id: root

    required property string screenName
    property real maxWidth: Theme.u * 250
    property bool fixedWidth: false        // island: keep a constant width so the bar doesn't jump
    readonly property bool onThisScreen: !Config.lyrics.screens || Config.lyrics.screens.length === 0 || Config.lyrics.screens.includes(screenName)
    readonly property bool active: Config.lyrics.enabled && Lyrics.visibleToggle && Lyrics.hasLyrics && onThisScreen
    readonly property string line: Lyrics.current !== "" ? Lyrics.current : "♪ ~ ♪"

    visible: active && maxWidth >= Theme.u * 50
    implicitWidth: fixedWidth ? maxWidth : Math.min(maxWidth, measure.implicitWidth + note.width + Theme.u * 6)
    implicitHeight: Theme.u * 13
    clip: true

    readonly property bool coverReady: cover.status === Image.Ready
    property string shown: ""
    property string previous: ""
    property int typed: 0

    onLineChanged: {
        previous = shown;
        shown = line;
        if (!Config.lyrics.typewriter) {
            typed = shown.length;
        } else {
            typed = 0;
            const dur = Math.max(0.3, Lyrics.lineEnd - Lyrics.lineStart);
            typer.interval = Math.max(12, Math.min(38, dur * 1000 * 0.45 / Math.max(1, shown.length)));
            typer.restart();
        }
        slide.restart();
    }
    Component.onCompleted: {
        shown = line;
        typed = shown.length;
    }

    Timer {
        id: typer
        repeat: true
        onTriggered: {
            root.typed = Math.min(root.shown.length, root.typed + 1);
            if (root.typed >= root.shown.length)
                stop();
        }
    }

    PxText {
        id: measure
        visible: false
        text: root.shown
        font.family: Theme.fontBody
        font.pixelSize: Theme.sizeBody
    }

    Item {
        id: note
        width: Config.lyrics.artwork === "cover" ? Theme.u * 12 : Theme.u * 8
        height: Theme.u * 12
        anchors.verticalCenter: parent.verticalCenter
        x: root.fixedWidth ? Math.max(0, (root.width - width - Theme.u * 4 - Math.min(measure.implicitWidth, root.width - width - Theme.u * 6)) / 2) : 0
        Image {
            id: cover
            anchors.fill: parent
            source: Config.lyrics.artwork === "cover" ? Lyrics.artUrl : ""
            sourceSize: Qt.size(width * 2, height * 2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
            clip: true
        }
        PxIcon {
            anchors.centerIn: parent
            name: "music"
            visible: cover.status !== Image.Ready
            pixel: Math.max(1, Theme.u - 1)
        }
    }

    Item {
        id: textBox
        anchors.left: note.right
        anchors.leftMargin: Theme.u * 4
        anchors.right: parent.right
        height: parent.height

        // previous line sliding up and out
        PxText {
            id: old
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            text: root.previous
            elide: Text.ElideRight
            color: Theme.textDim
            opacity: 0
        }
        PxText {
            id: cur
            width: parent.width
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            textFormat: Text.StyledText
            color: Lyrics.current === "" ? Theme.textDim : Theme.text
            text: {
                const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;");
                const t = root.shown;
                return esc(t.slice(0, root.typed)) + (root.typed < t.length ? "<font color='" + Theme.hex(Theme.accent) + "'>▌</font>" : "");
            }
        }

        ParallelAnimation {
            id: slide
            NumberAnimation {
                target: old
                property: "anchors.verticalCenterOffset"
                from: 0
                to: -Theme.u * 8
                duration: 220
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: old
                property: "opacity"
                from: 0.8
                to: 0
                duration: 220
            }
            NumberAnimation {
                target: cur
                property: "anchors.verticalCenterOffset"
                from: Theme.u * 6
                to: 0
                duration: 180
                easing.type: Easing.OutBack
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Shell.openSettings("lyrics")
    }
}
