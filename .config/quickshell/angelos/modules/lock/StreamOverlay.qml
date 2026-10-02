pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.widgets

// NEEDY GIRL OVERDOSE "stream" on the lock screen: blinking LIVE badge, a viewer
// counter and a chat that comments on what happens (typing, mistakes, unlock).
// Everything here is invented locally; nothing is sent anywhere.
Item {
    id: root

    required property var lockScope
    property int viewers: 800 + Math.floor(Math.random() * 1200)
    property var messages: []
    readonly property var nicks: ["ame_fan", "pixel_angel", "kangel_love", "p-chan", "OMGkawaii", "net_nomad", "hikiko", "sugar_rush", "ghost_viewer", "moe_moe", "chat_angel", "lurker404"]
    readonly property var idleLines: [I18n.t("ждём ангела ♡", "waiting for angel ♡"), I18n.t("стрим на паузе~", "stream paused~"), "brb?", I18n.t("кто тут?", "who's here?"), I18n.t("обожаю эти обои", "love this wallpaper"), I18n.t("пароль не подсматриваем 👀", "no peeking at the password 👀"), I18n.t("пейте воду, чат", "drink water, chat"), "OMG kawaii", I18n.t("ангел, возвращайся", "angel, come back"), "♡♡♡", I18n.t("лайк, подписка", "like and subscribe"), "internet angel ✧"]
    readonly property var typingLines: [I18n.t("она печатает…", "typing…"), I18n.t("вижу звёздочки ♥♥♥", "I see hearts ♥♥♥"), I18n.t("давай-давай!", "go go go!"), I18n.t("чат, тихо!", "chat, quiet!")]
    readonly property var failLines: ["F", I18n.t("ну пожааалуйста", "pleeease"), I18n.t("капс не нажат?", "caps lock?"), I18n.t("бывает ♡", "it happens ♡"), I18n.t("попробуй ещё", "try again")]
    readonly property var winLines: [I18n.t("УРА ♡", "YAY ♡"), I18n.t("ангел вернулся!!", "angel is back!!"), "GG", "✧ welcome back ✧"]

    function say(lines, nick) {
        const list = messages.concat([{
                "nick": nick || nicks[Math.floor(Math.random() * nicks.length)],
                "text": lines[Math.floor(Math.random() * lines.length)],
                "hue": Math.random()
            }]);
        messages = list.slice(-9);
    }
    Component.onCompleted: {
        say(idleLines);
        say(idleLines);
    }

    Timer {
        interval: 2600
        repeat: true
        running: root.visible
        onTriggered: {
            if (Math.random() < 0.7)
                root.say(root.idleLines);
            root.viewers = Math.max(1, root.viewers + Math.floor((Math.random() - 0.45) * 40));
        }
    }
    property real _lastTyping: 0
    Connections {
        target: root.lockScope
        function onTyped(length, added) {
            if (Date.now() - root._lastTyping > 2500) {
                root._lastTyping = Date.now();
                root.say(root.typingLines);
            }
        }
        function onShake() {
            root.say(root.failLines);
            root.say(root.failLines);
            root.viewers -= 7;
        }
        function onSuccess() {
            root.say(root.winLines);
            root.say(root.winLines);
            root.viewers += 99;
        }
    }

    // LIVE badge + viewers (top left)
    Row {
        x: Theme.u * 10
        y: Theme.u * 10
        spacing: Theme.u * 4
        PxBox {
            width: live.implicitWidth + Theme.u * 10
            height: Theme.u * 15
            color: Theme.danger
            Row {
                id: live
                anchors.centerIn: parent
                spacing: Theme.u * 3
                Rectangle {
                    id: dot
                    width: Theme.u * 4
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#ffffff"
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: root.visible
                        PropertyAction {
                            value: 1
                        }
                        PauseAnimation {
                            duration: 600
                        }
                        PropertyAction {
                            value: 0.2
                        }
                        PauseAnimation {
                            duration: 600
                        }
                    }
                }
                PxText {
                    text: "LIVE"
                    color: "#ffffff"
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
        PxBox {
            width: viewersRow.implicitWidth + Theme.u * 10
            height: Theme.u * 15
            color: Qt.alpha(Theme.face, 0.85)
            Row {
                id: viewersRow
                anchors.centerIn: parent
                spacing: Theme.u * 3
                PxIcon {
                    name: "heart"
                    anchors.verticalCenter: parent.verticalCenter
                }
                PxText {
                    text: root.viewers.toLocaleString(Qt.locale(), "f", 0) + I18n.t(" зрителей", " watching")
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
        PxText {
            anchors.verticalCenter: parent.verticalCenter
            text: Config.lock.streamTitle || I18n.t("ангел ушёл на перерыв ♡ скоро вернусь", "angel is on a break ♡ be right back")
            color: "#ffffff"
            style: Text.Outline
            styleColor: Theme.edge
        }
    }

    // chat (bottom right)
    PxWindow {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.u * 10
        width: Theme.u * 130
        height: titleHeight + chat.implicitHeight + Theme.pad * 2 + Theme.u * 6
        title: I18n.exe(I18n.t("чат", "chat"))
        icon: "bell"
        compact: true
        closable: false
        Column {
            id: chat
            width: parent.width
            spacing: Theme.u * 2
            Repeater {
                model: root.messages
                Row {
                    id: msg
                    required property var modelData
                    width: chat.width
                    spacing: Theme.u * 3
                    PxText {
                        text: msg.modelData.nick + ":"
                        color: Qt.hsla(msg.modelData.hue, 0.7, Theme.dark ? 0.7 : 0.4, 1)
                        font.bold: true
                    }
                    PxText {
                        width: chat.width - x
                        text: msg.modelData.text
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
