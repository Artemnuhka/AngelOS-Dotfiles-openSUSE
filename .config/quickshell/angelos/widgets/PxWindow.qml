import QtQuick
import qs.config

// NGO-style window: bevelled frame, gradient title bar, pixel buttons.
// `hell` (Theme.realm, desktop widgets): obsidian frame, blackletter title,
// pixel flames licking up from the top edge and blood dripping off the bottom.
Item {
    id: root

    property bool hell: false
    // the settings skins (Config.settingsUi.skin): "" / classic, windose (a candy NGO window:
    // pink rim, ink outline, white buttons) or stream (a broadcast panel with a LIVE pill)
    property string skin: Config.settingsUi.skin === "windose" ? "windose" : ""
    readonly property bool windose: skin === "windose" && !hell
    readonly property bool streamSkin: skin === "stream" && !hell
    readonly property string settingsSkin: windose ? "windose" : streamSkin ? "stream" : "classic"
    property bool flamesLive: true         // the flames move (off while nobody sees them)
    property bool trim: true               // flames and drips (a copy drawn over its twin leaves them to it)

    property string title: ""
    property string icon: "heart"
    property bool closable: true
    property bool minimizable: false
    property bool maximizable: false
    property bool translucent: true
    property bool compact: false
    property bool decor: true
    property bool active: true
    property bool shadow: Config.appearance.shadows
    property color bodyColor: translucent ? Theme.panel : Theme.face
    property int bodyPadding: Theme.pad
    readonly property int titleHeight: hell ? Theme.hellPx(Theme.fs) + Theme.u * 3 : compact ? Theme.sizeBody + Theme.u * 5 : Theme.sizeTitle + Theme.u * 5
    readonly property int chrome: frame.inset + Theme.u
    property alias titleBar: bar
    property alias titleMouse: titleMouse
    default property alias content: body.data

    signal closeClicked
    signal minimizeClicked
    signal maximizeClicked
    signal titlePressed(var mouse)

    PxBox {
        id: frame
        anchors.fill: parent
        hell: root.hell
        color: root.windose ? Theme.windosePaper : root.streamSkin ? Theme.streamBg : root.hell && root.bodyColor.a > 0 ? Theme.hellPanel : root.bodyColor
        edgeColor: root.windose ? Theme.windoseLine : root.hell ? Theme.hellEdge : Theme.edge
        hiColor: root.windose ? Theme.mix(Theme.windosePaper, Theme.text, 0.15) : root.hell ? Theme.hellHi : Theme.hi
        loColor: root.windose ? Theme.windoseLine : root.hell ? Theme.hellLo : Theme.lo
        shadow: root.shadow
    }

    // ---- hell's trim ----
    ShaderEffect {
        id: flames
        visible: root.hell && root.trim
        readonly property int rows: 7
        width: root.width
        height: Theme.u * rows
        y: -height + Theme.u
        property real time: 0
        readonly property real seed: (root.title.length * 3.17) % 11
        readonly property size cells: Qt.size(Math.max(1, Math.round(width / Theme.u)), rows)
        fragmentShader: Qt.resolvedUrl("../shaders/hell_flames.frag.qsb")
        Timer {
            interval: 140
            repeat: true
            running: flames.visible && root.flamesLive && root.visible
            onTriggered: flames.time += 0.14
        }
    }
    // blood dripping off the bottom edge, at fixed spots
    Repeater {
        model: root.hell && root.trim ? [[0.11, 3], [0.24, 5], [0.43, 2], [0.6, 4], [0.78, 2], [0.9, 6]] : []
        Item {
            id: drip
            required property var modelData
            x: Math.round(root.width * modelData[0] / Theme.u) * Theme.u
            y: root.height - Theme.u
            width: Theme.u * 2
            height: Theme.u * (modelData[1] + 2)
            Rectangle {
                x: Theme.u / 2
                width: Theme.u
                height: Theme.u * drip.modelData[1]
                color: Theme.hellBlood
            }
            Rectangle {
                y: Theme.u * drip.modelData[1]
                width: Theme.u * 2
                height: Theme.u * 2
                color: Theme.hellBlood
                Rectangle {
                    width: Theme.u
                    height: Theme.u
                    color: "#e8404f"
                }
            }
        }
    }

    Rectangle {
        id: bar
        x: frame.inset + Theme.u
        y: frame.inset + Theme.u
        width: root.width - 2 * x
        height: root.titleHeight
        color: root.windose ? Theme.windoseRose : root.streamSkin ? Theme.streamPanel : root.hell ? (root.active ? Theme.mix(Theme.hellFaceAlt, Theme.hellBlood, 0.35) : Theme.hellFace) : root.active ? Theme.menuHeader : Theme.faceAlt
        // Windose: the candy gradient from pink to lilac
        gradient: root.windose ? candy : null
        Gradient {
            id: candy
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0
                color: Theme.windoseRose
            }
            GradientStop {
                position: 1
                color: Theme.windoseLavender
            }
        }

        MouseArea {
            id: titleMouse
            anchors.fill: parent
            onPressed: m => root.titlePressed(m)
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: Theme.u * 3
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u * 3

            PxIcon {
                name: root.icon
                anchors.verticalCenter: parent.verticalCenter
                ink: root.hell ? Theme.hellEdge : root.windose ? Theme.windoseInk : Theme.edge
                fill: root.hell ? Theme.hellFlame : root.windose ? Theme.windoseSticker : "#ffffff"
                light: root.hell ? Theme.hellText : root.windose ? Theme.windoseLavender : Theme.accent3
                fill2: root.hell ? Theme.hellEmber : root.windose ? Theme.windoseRose : "#ffffff"
                body: root.hell ? Theme.hellFace : root.windose ? Theme.windoseSticker : "#ffffff"
                bad: root.hell ? Theme.hellEmber : Theme.danger
            }
            // stream: the red LIVE pill before the title
            Rectangle {
                visible: root.streamSkin
                anchors.verticalCenter: parent.verticalCenter
                width: liveLabel.implicitWidth + Theme.u * 6
                height: liveLabel.implicitHeight + Theme.u
                radius: height / 2
                color: Theme.streamLive
                PxText {
                    id: liveLabel
                    anchors.centerIn: parent
                    text: "● LIVE"
                    kind: "tiny"
                    font.bold: true
                    color: Theme.selectText
                }
            }
            PxText {
                text: root.title
                kind: root.compact ? "body" : "title"
                readonly property bool gothic: root.hell && Theme.latin(root.title)
                font.family: gothic ? Theme.fontHell : root.compact ? Theme.fontBody : Theme.fontTitle
                font.pixelSize: gothic ? Theme.hellPx(Theme.fs) : root.compact ? Theme.sizeBody : Theme.sizeTitle
                font.bold: root.windose
                color: root.windose ? Theme.text : root.streamSkin ? Theme.streamText : root.hell ? Theme.hellFlame : Theme.text
                style: Text.Normal
                styleColor: Qt.alpha(Theme.edge, 0.55)
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, bar.width - buttons.width - Theme.u * 30)
                elide: Text.ElideRight
            }
        }

        Row {
            id: buttons
            anchors.right: parent.right
            anchors.rightMargin: Theme.u * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u * 2

            Row {
                visible: root.decor && !root.compact
                spacing: Theme.u
                anchors.verticalCenter: parent.verticalCenter
                rightPadding: Theme.u * 3
                PxIcon {
                    name: "heartSmall"
                    fill: "#ffffff"
                    ink: Qt.alpha(Theme.edge, 0.7)
                    anchors.verticalCenter: parent.verticalCenter
                }
                PxIcon {
                    name: "sparkle"
                    fill: "#ffffff"
                    light: Theme.accent3
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Repeater {
                model: [
                    {
                        id: "min",
                        icon: "minimize",
                        show: root.minimizable
                    },
                    {
                        id: "max",
                        icon: "maximize",
                        show: root.maximizable
                    },
                    {
                        id: "close",
                        icon: "close",
                        show: root.closable
                    }
                ]
                delegate: Item {
                    id: tb
                    required property var modelData
                    visible: modelData.show
                    width: root.titleHeight - Theme.u * 4
                    height: width
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

                    PxBox {
                        anchors.fill: parent
                        sunken: tbMouse.pressed
                        hell: root.hell
                        edgeColor: root.windose ? Theme.windoseLine : root.hell ? Theme.hellEdge : Theme.edge
                        color: tbMouse.containsMouse && tb.modelData.id === "close" ? (root.hell ? Theme.hellBlood : Theme.danger) : root.windose ? Theme.windoseSticker : root.streamSkin ? Theme.streamBg : root.hell ? Theme.hellFace : Theme.face
                    }
                    PxIcon {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: tbMouse.pressed ? Theme.u : 0
                        name: tb.modelData.icon
                        pixel: Math.max(1, Math.floor(Theme.u * (root.compact ? 0.5 : 1)))
                        ink: tbMouse.containsMouse && tb.modelData.id === "close" ? "#ffffff" : root.windose ? Theme.windoseInk : root.streamSkin ? Theme.streamText : root.hell ? Theme.hellText : (Theme.dark ? Theme.text : Theme.edge)
                    }
                    MouseArea {
                        id: tbMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (tb.modelData.id === "close")
                                root.closeClicked();
                            else if (tb.modelData.id === "min")
                                root.minimizeClicked();
                            else
                                root.maximizeClicked();
                        }
                    }
                }
            }
        }
    }

    Item {
        id: body
        anchors {
            top: bar.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: root.bodyPadding
            leftMargin: frame.inset + root.bodyPadding
            rightMargin: frame.inset + root.bodyPadding
            bottomMargin: frame.inset + root.bodyPadding
        }
    }

    WindoseDecor {
        visible: root.windose && !root.compact && root.width >= Theme.u * 180 && root.height >= Theme.u * 110
        x: bar.x + Theme.u
        y: bar.y + bar.height + Theme.u
        width: bar.width - Theme.u * 2
        height: root.height - y - frame.inset - Theme.u
        z: 2
    }
}
