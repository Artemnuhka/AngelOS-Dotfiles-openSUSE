import QtQuick
import qs.config
import qs.services
import qs.widgets

// Cover, track and controls of the current MPRIS player.
// In hell (Theme.realm) the cover is the label of a burning record: a pixel disc
// that turns while the music plays, flames licking up from under it.
Item {
    id: root

    property string screenName
    property var widget
    readonly property var p: Lyrics.player
    property real pos: 0
    readonly property bool playing: !!p && p.isPlaying
    readonly property bool live: visible && !Shell.hiddenScreen(screenName)

    implicitWidth: Theme.u * 150
    implicitHeight: Theme.u * 44

    Timer {
        interval: 1000
        running: root.visible && root.playing
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
        text: Theme.hell ? I18n.t("тишина", "silence") : I18n.t("ничего не играет ♡", "nothing is playing ♡")
        color: Theme.hell ? Theme.hellTextDim : Theme.textDim
    }

    Row {
        visible: !!root.p && !!Lyrics.title
        anchors.fill: parent
        spacing: Theme.u * 5

        Item {
            width: parent.height
            height: parent.height

            PxBox {
                anchors.fill: parent
                visible: !Theme.hell
                sunken: true
                color: Theme.sunken
            }
            Image {
                // heaven: the whole box; hell: the record's label in the middle
                readonly property int side: Theme.hell ? vinyl.labelPx * 2 : parent.width
                anchors.centerIn: parent
                width: side
                height: side
                source: root.p ? (root.p.trackArtUrl || "") : ""
                sourceSize: Qt.size(Theme.u * 24, Theme.u * 24)   // tiny source + no smoothing = pixel cover
                fillMode: Image.PreserveAspectCrop
                smooth: false
                asynchronous: true
            }

            // ---- hell: the record ----
            // Drawn art pixel by art pixel in the circle's palette: grooves, a dull glint that
            // moves an eighth of a turn every few seconds while it plays (hell is slow), and a
            // clear hole where the cover shows through as the label.
            Canvas {
                id: vinyl
                visible: Theme.hell
                anchors.fill: parent
                readonly property int n: Math.max(8, Math.floor(width / Theme.u))   // art pixels across
                readonly property int labelPx: Math.round(n * 0.22) * Theme.u
                property int step: 0
                renderStrategy: Canvas.Cooperative
                onStepChanged: requestPaint()
                onNChanged: requestPaint()
                onVisibleChanged: if (visible)
                    requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    const u = width / n, c = (n - 1) / 2, R = n / 2 - 0.5, L = n * 0.22;
                    ctx.clearRect(0, 0, width, height);
                    const glint = step * Math.PI / 4;
                    for (let y = 0; y < n; y++)
                        for (let x = 0; x < n; x++) {
                            const dx = x - c, dy = y - c, r = Math.sqrt(dx * dx + dy * dy);
                            if (r > R || r <= L)
                                continue;
                            let col = String(Theme.hellSunken);
                            if (r > R - 1)
                                col = String(Theme.hellFaceAlt);
                            else if (Math.round(r) % 3 === 0)
                                col = String(Theme.hellFace);
                            // the glint: a short arc that moves an eighth of a turn a step
                            let a = Math.atan2(dy, dx) - glint;
                            a = Math.atan2(Math.sin(a), Math.cos(a));
                            if (Math.abs(a) < 0.28 && r > L + 1 && r < R - 1)
                                col = String(Theme.hellRim);
                            if (r <= L + 1)
                                col = String(Theme.hellBlood);
                            ctx.fillStyle = col;
                            ctx.fillRect(Math.round(x * u), Math.round(y * u), Math.ceil(u), Math.ceil(u));
                        }
                }
                Timer {
                    interval: 6000
                    repeat: true
                    running: vinyl.visible && root.playing && root.live
                    onTriggered: vinyl.step = (vinyl.step + 1) % 8
                }
            }
        }
        Column {
            width: parent.width - parent.height - Theme.u * 5
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u * 2
            PxText {
                width: parent.width
                text: Lyrics.title
                font.bold: !Theme.hell
                font.family: Theme.hell ? Theme.fontHellText : Theme.fontBody
                font.pixelSize: Theme.hell ? Theme.hellTextPx(Theme.fs) : Theme.sizeBody
                color: Theme.hell ? Theme.hellText : Theme.text
                elide: Text.ElideRight
            }
            PxText {
                width: parent.width
                text: Lyrics.artist
                font.family: Theme.hell ? Theme.fontHellText : Theme.fontBody
                font.pixelSize: Theme.hell ? Theme.hellTextPx(Theme.fs) : Theme.sizeBody
                color: Theme.hell ? Theme.hellTextDim : Theme.textDim
                elide: Text.ElideRight
            }
            PxBox {
                width: parent.width
                height: Theme.u * 4
                sunken: true
                hell: Theme.hell
                color: Theme.hell ? Theme.hellSunken : Theme.sunken
                Rectangle {
                    height: parent.height
                    width: root.p && root.p.length > 0 ? parent.width * Math.min(1, root.pos / root.p.length) : 0
                    color: Theme.hell ? Theme.hellBlood : Theme.accent
                }
            }
            Row {
                spacing: Theme.u * 2
                PxButton {
                    compact: true
                    hell: Theme.hell
                    icon: "prev"
                    iconPixel: Math.max(1, Theme.u - 1)
                    onClicked: root.p.previous()
                }
                PxButton {
                    compact: true
                    hell: Theme.hell
                    icon: root.playing ? "pause" : "play"
                    iconPixel: Math.max(1, Theme.u - 1)
                    onClicked: root.p.togglePlaying()
                }
                PxButton {
                    compact: true
                    hell: Theme.hell
                    icon: "next"
                    iconPixel: Math.max(1, Theme.u - 1)
                    onClicked: root.p.next()
                }
            }
        }
    }
}
