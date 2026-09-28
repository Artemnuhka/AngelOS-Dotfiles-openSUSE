pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

Item {
    id: root

    required property string screenName
    required property bool primary
    required property var lockScope

    readonly property var ws: Niri.activeWorkspace(screenName)
    readonly property string wall: Wallpapers.resolve(screenName, ws ? ws.idx : 1)

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Image {
        id: img
        anchors.fill: parent
        source: root.wall ? "file://" + root.wall : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(width, height)
        asynchronous: true
        visible: !Config.lock.pixelate
    }
    ShaderEffect {
        anchors.fill: parent
        visible: Config.lock.pixelate
        property var source: ShaderEffectSource {
            sourceItem: img
            hideSource: true
        }
        property real block: Theme.u * 8
        property size resolution: Qt.size(width, height)
        fragmentShader: Qt.resolvedUrl("../../shaders/pixelate.frag.qsb")
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.desk, 0.35)
    }

    Column {
        anchors.centerIn: parent
        spacing: Theme.u * 10

        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, "HH:mm")
            font.family: Theme.fontTitle
            font.pixelSize: 72 * Theme.fs
            color: "#ffffff"
            style: Text.Outline
            styleColor: Theme.edge
        }
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.locale("ru_RU").toString(clock.date, "dddd, d MMMM")
            kind: "title"
            color: "#ffffff"
            style: Text.Outline
            styleColor: Theme.edge
        }

        PxWindow {
            id: box
            visible: root.primary
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.u * 160
            height: titleHeight + Theme.u * 60
            title: I18n.t("вход.exe", "login.exe")
            icon: "lock"
            closable: false
            translucent: false

            property real shakeX: 0
            transform: Translate {
                x: box.shakeX
            }
            SequentialAnimation {
                id: shakeAnim
                loops: 3
                NumberAnimation {
                    target: box
                    property: "shakeX"
                    to: Theme.u * 6
                    duration: 40
                }
                NumberAnimation {
                    target: box
                    property: "shakeX"
                    to: -Theme.u * 6
                    duration: 40
                }
                NumberAnimation {
                    target: box
                    property: "shakeX"
                    to: 0
                    duration: 40
                }
            }
            Connections {
                target: root.lockScope
                function onShake() {
                    shakeAnim.restart();
                    field.text = "";
                }
            }

            Column {
                width: parent.width
                spacing: Theme.u * 5

                Row {
                    spacing: Theme.u * 4
                    PxIcon {
                        name: "heart"
                        pixel: Theme.u * 2
                    }
                    PxText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Quickshell.env("USER") + I18n.t(", с возвращением~", ", welcome back~")
                        kind: "title"
                    }
                }
                PxField {
                    id: field
                    width: parent.width
                    password: true
                    placeholder: I18n.t("пароль", "password")
                    enabled: !root.lockScope.busy
                    onAccepted: root.lockScope.submit(text)
                    Component.onCompleted: focusField()
                }
                PxText {
                    text: root.lockScope.status
                    color: root.lockScope.fails > 0 ? Theme.danger : Theme.textDim
                }
            }
        }
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Theme.u * 20
        spacing: Theme.u * 6
        visible: root.primary && Lyrics.title !== ""
        PxIcon {
            name: "music"
        }
        PxText {
            text: Lyrics.title + (Lyrics.artist ? " — " + Lyrics.artist : "")
            color: "#ffffff"
            style: Text.Outline
            styleColor: Theme.edge
        }
    }
}
