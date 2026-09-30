import QtQuick
import qs.config
import qs.services

// angelOS logo: a pixel angel-heart (halo + wings) and a wordmark.
//   classic — "angel" + a Win98 "OS" plate
//   angel   — pink "angel" + cyan "OS" with sparkles
// While the demon rules (services/Angel) the heart wears horns instead of the halo.
Item {
    id: root

    property bool emblemOnly: false
    property int pixel: Theme.u
    property string variant: Config.bar.logoStyle === "angel" ? "angel" : "classic"
    property int fontSize: Theme.sizeTitle
    readonly property bool angel: variant === "angel"
    property bool horns: Angel.demon

    // 19×12 art pixels: '#' outline, 'o' heart, 'w' wings/shine, 'y' halo, 'r' horns
    readonly property var emblemRows: (horns ? [
            "...r...........r...",
            "...rr.........rr...",
            "....rr.......rr....",
            ".....rr.....rr....."
        ] : [
            "......yyyyyyy......",
            ".....y.......y.....",
            "......yyyyyyy......",
            "..................."
        ]).concat(heartRows)
    readonly property var heartRows: [
        "#.....##...##.....#",
        "#w#..#wo#.#oo#..#w#",
        "#ww###ooo#ooo###ww#",
        ".#www#ooooooo#www#.",
        "..#w#.#ooooo#.#w#..",
        "...##..#ooo#..##...",
        "........#o#........",
        ".........#........."
    ]

    implicitWidth: emblemOnly ? emblem.width : row.implicitWidth
    implicitHeight: Math.max(emblem.height, wordmark.implicitHeight)

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.pixel * 4

        PxIcon {
            id: emblem
            anchors.verticalCenter: parent.verticalCenter
            bitmap: root.emblemRows
            pixel: root.pixel
            ink: Theme.dark ? Theme.mix(Theme.accent, Theme.edge, 0.55) : Theme.edge
            fill: Theme.accent
            light: "#ffffff"
            fill3: Theme.mix(Theme.accent3, Qt.color("#ffd84a"), 0.6)
            bad: "#e0203a"
        }

        Row {
            id: wordmark
            visible: !root.emblemOnly
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.angel ? 0 : root.pixel * 2

            PxText {
                anchors.verticalCenter: parent.verticalCenter
                text: "angel"
                font.family: Theme.fontTitle
                font.pixelSize: root.fontSize
                color: root.angel ? Theme.accent : Theme.text
                style: root.angel ? Text.Outline : Text.Normal
                styleColor: Qt.alpha(Theme.edge, 0.8)
            }

            // classic: "OS" on a bevelled plate
            PxBox {
                visible: !root.angel
                anchors.verticalCenter: parent.verticalCenter
                width: os.implicitWidth + root.pixel * 6
                height: root.fontSize + root.pixel * 2
                color: Theme.accent
                hiColor: Theme.mix(Theme.accent, "#ffffff", 0.45)
                loColor: Theme.mix(Theme.accent, Theme.edge, 0.5)
                PxText {
                    id: os
                    anchors.centerIn: parent
                    text: "OS"
                    font.family: Theme.fontTitle
                    font.pixelSize: root.fontSize
                    font.bold: true
                    color: Theme.selectText
                }
            }

            // angel: cyan "OS" and a sparkle
            PxText {
                visible: root.angel
                anchors.verticalCenter: parent.verticalCenter
                text: "OS"
                font.family: Theme.fontTitle
                font.pixelSize: root.fontSize
                font.bold: true
                color: Theme.accent2
                style: Text.Outline
                styleColor: Qt.alpha(Theme.edge, 0.8)
            }
            PxIcon {
                visible: root.angel
                anchors.top: parent.top
                name: "sparkle"
                pixel: Math.max(1, root.pixel - 1)
                fill: Theme.accent3
            }
        }
    }
}
