import QtQuick
import qs.config

Item {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder: ""
    property bool password: false
    property string icon: ""
    property string kind: "body"
    signal accepted
    signal edited
    signal keyPressed(var event)

    implicitWidth: Theme.u * 100
    implicitHeight: input.font.pixelSize + Theme.u * 10

    function focusField() {
        input.forceActiveFocus();
    }

    PxBox {
        anchors.fill: parent
        sunken: true
        color: Theme.sunken
        edgeColor: input.activeFocus ? Theme.accent : Theme.edge
    }

    PxIcon {
        id: ico
        visible: root.icon !== ""
        name: root.icon || "search"
        x: Theme.u * 5
        anchors.verticalCenter: parent.verticalCenter
    }

    TextInput {
        id: input
        anchors.left: ico.visible ? ico.right : parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.u * 5
        anchors.rightMargin: Theme.u * 5
        anchors.verticalCenter: parent.verticalCenter
        clip: true
        color: Theme.text
        selectionColor: Theme.select
        selectedTextColor: Theme.selectText
        font.family: root.kind === "title" ? Theme.fontTitle : Theme.fontBody
        font.pixelSize: root.kind === "title" ? Theme.sizeTitle : Theme.sizeBody
        font.hintingPreference: Font.PreferFullHinting
        renderType: Text.NativeRendering
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        passwordCharacter: "♥"
        selectByMouse: true
        onAccepted: root.accepted()
        Keys.onPressed: e => root.keyPressed(e)
        onTextEdited: root.edited()

        cursorDelegate: Rectangle {
            width: Theme.u * 2
            color: Theme.accent
            visible: input.activeFocus
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: input.activeFocus
                PropertyAction {
                    value: 1
                }
                PauseAnimation {
                    duration: 480
                }
                PropertyAction {
                    value: 0
                }
                PauseAnimation {
                    duration: 480
                }
            }
        }
    }

    PxText {
        anchors.fill: input
        visible: input.text === "" && !input.inputMethodComposing
        text: root.placeholder
        dim: true
        font: input.font
        elide: Text.ElideRight
    }
}
