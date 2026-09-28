import QtQuick
import qs.config

// NGO-style window: bevelled frame, gradient title bar, pixel buttons.
Item {
    id: root

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
    readonly property int titleHeight: compact ? Theme.sizeBody + Theme.u * 5 : Theme.sizeTitle + Theme.u * 5
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
        color: root.bodyColor
        shadow: root.shadow
    }

    Rectangle {
        id: bar
        x: frame.inset + Theme.u
        y: frame.inset + Theme.u
        width: root.width - 2 * x
        height: root.titleHeight
        color: root.active ? Theme.menuHeader : Theme.faceAlt

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
                ink: Theme.edge
                fill: "#ffffff"
                light: Theme.accent3
                fill2: "#ffffff"
                body: "#ffffff"
            }
            PxText {
                text: root.title
                kind: root.compact ? "body" : "title"
                color: Theme.text
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
                        color: tbMouse.containsMouse && tb.modelData.id === "close" ? Theme.danger : Theme.face
                    }
                    PxIcon {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: tbMouse.pressed ? Theme.u : 0
                        name: tb.modelData.icon
                        pixel: Math.max(1, Math.floor(Theme.u * (root.compact ? 0.5 : 1)))
                        ink: tbMouse.containsMouse && tb.modelData.id === "close" ? "#ffffff" : (Theme.dark ? Theme.text : Theme.edge)
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
}
