import QtQuick
import qs.config

// Font-based wordmarks sharing the little heart-window emblem.
Item {
    id: root
    property bool emblemOnly: false
    property int pixel: Theme.u
    property string variant: Config.bar.logoStyle
    readonly property bool angel: variant === "angel"
    implicitWidth: emblemOnly ? emblem.width : emblem.width + pixel * 4 + wordmark.implicitWidth
    implicitHeight: pixel * 12

    Item {
        id: emblem
        width: root.pixel * 13
        height: root.pixel * 12
        Rectangle {
            x: root.pixel * 4
            width: root.pixel * 5
            height: root.pixel * 2
            radius: root.pixel
            color: "transparent"
            border.width: root.pixel / 2
            border.color: Theme.accent2
        }
        Rectangle {
            x: root.pixel
            y: root.pixel * 3
            width: root.pixel * 11
            height: root.pixel * 9
            color: Theme.face
            border.width: root.pixel / 2
            border.color: Theme.text
            Rectangle {
                x: root.pixel
                y: root.pixel
                width: parent.width - root.pixel * 2
                height: root.pixel * 2
                color: Theme.accent
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: root.pixel / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.pixel
                    height: root.pixel
                    color: Theme.selectText
                }
            }
            PxIcon {
                name: "heart"
                pixel: Math.max(1, root.pixel / 2)
                fill: Theme.accent
                anchors.horizontalCenter: parent.horizontalCenter
                y: root.pixel * 3.5
            }
        }
    }
    Row {
        id: wordmark
        visible: !root.emblemOnly
        x: emblem.width + root.pixel * 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.angel ? root.pixel : 0
        Text {
            text: "angel"
            color: Theme.text
            font.family: root.angel ? "Pixeloid Sans" : "Liberation Sans"
            font.pixelSize: root.pixel * (root.angel ? 9 : 10)
            font.bold: !root.angel
            font.hintingPreference: Font.PreferFullHinting
            renderType: Text.NativeRendering
        }
        Text {
            text: "OS"
            color: root.angel ? Theme.accent2 : Theme.text
            font.family: root.angel ? "Pixeloid Sans" : "Liberation Sans"
            font.pixelSize: root.pixel * (root.angel ? 9 : 10)
            font.bold: root.angel
            font.hintingPreference: Font.PreferFullHinting
            renderType: Text.NativeRendering
        }
        Text {
            visible: root.angel
            text: "+"
            color: Theme.accent
            font.family: "Pixeloid Sans"
            font.pixelSize: root.pixel * 6
            anchors.verticalCenter: parent.verticalCenter
            renderType: Text.NativeRendering
        }
    }
}
