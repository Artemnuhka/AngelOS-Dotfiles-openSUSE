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
    readonly property string settingsSkin: Theme.settingsSkinFor(root.parent)
    // Enter applies and leaves the field, Esc just leaves it (issue #9) — unless
    // the field is the whole point of its window (launcher, search, passwords)
    property bool keepFocus: false
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
        visible: root.settingsSkin === "classic"
        sunken: true
        color: Theme.sunken
        edgeColor: input.activeFocus ? Theme.accent : Theme.edge
    }
    Rectangle {
        visible: root.settingsSkin !== "classic"
        anchors.fill: parent
        radius: root.settingsSkin === "stream" ? Theme.u * 2 : 0
        color: root.settingsSkin === "stream" ? Theme.streamPanel : Theme.windoseSticker
        border.width: Math.max(1, Theme.u / 2)
        border.color: input.activeFocus ? Theme.accent : root.settingsSkin === "stream" ? Theme.mix(Theme.streamLive, Theme.streamPanel, 0.4) : Theme.windoseLine
    }

    PxIcon {
        id: ico
        visible: root.icon !== ""
        name: root.icon || "search"
        x: Theme.u * 5
        anchors.verticalCenter: parent.verticalCenter
        ink: root.settingsSkin === "stream" ? Theme.streamLive : root.settingsSkin === "windose" ? Theme.windoseRose : Theme.dark ? Theme.text : Theme.edge
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
        // handwritten in the grimoire (Theme.scriptWindow), like PxText
        readonly property bool script: Theme.scriptWindow !== null && Window.window === Theme.scriptWindow
        font.family: script ? Theme.fontScript : root.kind === "title" ? Theme.fontTitle : Theme.fontBody
        font.pixelSize: script ? Theme.scriptPx(root.kind === "title" ? Theme.sizeTitle : Theme.sizeBody) : root.kind === "title" ? Theme.sizeTitle : Theme.sizeBody
        font.hintingPreference: Font.PreferFullHinting
        renderType: script ? Text.QtRendering : Text.NativeRendering
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        passwordCharacter: "♥"
        selectByMouse: true
        onAccepted: {
            root.accepted();
            if (!root.keepFocus)
                input.focus = false;
        }
        Keys.onPressed: e => {
            root.keyPressed(e);
            if (!e.accepted && !root.keepFocus && e.key === Qt.Key_Escape) {
                input.focus = false;
                e.accepted = true;
            }
        }
        onTextEdited: root.edited()

        cursorDelegate: Rectangle {
            id: caret
            width: Theme.u * 2
            color: Theme.accent
            visible: input.activeFocus
            onVisibleChanged: opacity = 1
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: input.activeFocus && !Motion.still
                onStopped: caret.opacity = 1
                PropertyAction {
                    value: 1
                }
                PauseAnimation {
                    duration: Motion.ms(480)
                }
                PropertyAction {
                    value: 0
                }
                PauseAnimation {
                    duration: Motion.ms(480)
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
