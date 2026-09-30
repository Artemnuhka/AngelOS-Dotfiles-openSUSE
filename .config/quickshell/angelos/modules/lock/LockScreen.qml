pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.widgets

Item {
    id: root

    required property string screenName
    required property bool primary
    required property var lockScope
    property bool preview: false

    readonly property var ws: Niri.activeWorkspace(screenName)
    readonly property string wall: Wallpapers.resolve(screenName, ws ? ws.idx : 1)
    readonly property bool reactions: Config.lock.reactions
    readonly property int minutesLocked: Math.floor((clock.date.getTime() - lockScope.lockedAt) / 60000)
    readonly property int missed: Notifs.history.filter(h => h.time > lockScope.lockedAt).length
    readonly property string greeting: {
        const h = clock.date.getHours();
        return h < 5 ? I18n.t("доброй ночи", "good night") : h < 12 ? I18n.t("доброе утро", "good morning") : h < 18 ? I18n.t("добрый день", "good afternoon") : I18n.t("добрый вечер", "good evening");
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Image {
        id: img
        anchors.fill: parent
        source: root.wall ? "file://" + Wallpapers.display(root.wall) : ""
        fillMode: Image.PreserveAspectCrop
        // physical pixels: sharp on a scaled monitor (issue #18)
        sourceSize: Qt.size(Math.ceil(width * Math.max(1, Screen.devicePixelRatio)), Math.ceil(height * Math.max(1, Screen.devicePixelRatio)))
        asynchronous: true
        visible: !Config.lock.pixelate
        onStatusChanged: if (status === Image.Error)
            Wallpapers.fit(root.wall)
    }
    ShaderEffect {
        id: pixels
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
        id: shade
        anchors.fill: parent
        color: Qt.alpha(Theme.desk, 0.35)
    }

    FloatingHearts {
        anchors.fill: parent
        visible: Config.lock.hearts
        count: 22
        maxOpacity: 0.5
    }

    // ---- NGO stream overlay: LIVE badge, viewers, a cute fake chat ----
    Loader {
        anchors.fill: parent
        active: Config.lock.stream && root.primary
        sourceComponent: StreamOverlay {
            lockScope: root.lockScope
        }
    }

    // ---- indicators (top right) ----
    Row {
        visible: Config.lock.indicators
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: Theme.u * 10
        spacing: Theme.u * 4
        Repeater {
            model: [
                {
                    "show": UPower.displayDevice && UPower.displayDevice.isLaptopBattery,
                    "icon": "power",
                    "text": UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) + "%" + (UPower.onBattery ? "" : " ⚡") : ""
                },
                {
                    "show": root.missed > 0,
                    "icon": "bell",
                    "text": String(root.missed)
                },
                {
                    "show": Niri.layoutShort !== "",
                    "icon": "keyboard",
                    "text": Niri.layoutShort
                },
                {
                    "show": true,
                    "icon": "lock",
                    "text": root.minutesLocked < 1 ? I18n.t("только что", "just now") : root.minutesLocked + I18n.t(" мин", " min")
                }
            ].filter(i => i.show)
            PxBox {
                id: ind
                required property var modelData
                width: indRow.implicitWidth + Theme.u * 8
                height: Theme.u * 15
                color: Qt.alpha(Theme.face, 0.8)
                Row {
                    id: indRow
                    anchors.centerIn: parent
                    spacing: Theme.u * 3
                    PxIcon {
                        name: ind.modelData.icon
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    PxText {
                        text: ind.modelData.text
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    Column {
        id: center
        anchors.centerIn: parent
        spacing: Theme.u * 10

        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, "HH") + (clock.date.getSeconds() % 2 || !root.reactions ? ":" : " ") + Qt.formatTime(clock.date, "mm")
            font.family: Theme.fontTitle
            font.pixelSize: Theme.crisp(72, Theme.fontTitle) * Theme.fs
            color: "#ffffff"
            style: Text.Outline
            styleColor: Theme.edge
        }
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.locale(Config.appearance.language === "en" ? "en_US" : "ru_RU").toString(clock.date, "dddd, d MMMM")
            kind: "title"
            color: "#ffffff"
            style: Text.Outline
            styleColor: Theme.edge
        }

        PxWindow {
            id: box
            visible: root.primary
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.u * 170
            height: titleHeight + form.implicitHeight + Theme.pad * 2 + Theme.u * 8
            title: root.preview ? I18n.t("вход.exe · предпросмотр", "login.exe · preview") : I18n.t("вход.exe", "login.exe")
            icon: "lock"
            closable: root.preview
            onCloseClicked: Shell.lockPreview = false
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

            Column {
                id: form
                width: parent.width
                spacing: Theme.u * 5

                Row {
                    spacing: Theme.u * 5
                    // the heart beats while typing and breaks on a wrong password
                    Item {
                        width: bigHeart.width
                        height: bigHeart.height
                        PxIcon {
                            id: bigHeart
                            name: heartState.broken ? "heartBroken" : "heart"
                            pixel: Theme.u * 3
                            fill: heartState.broken ? Theme.danger : Theme.accent
                            scale: heartState.beat
                            transformOrigin: Item.Center
                        }
                        QtObject {
                            id: heartState
                            property bool broken: false
                            property real beat: 1
                        }
                        SequentialAnimation {
                            id: beatAnim
                            PropertyAction {
                                target: heartState
                                property: "beat"
                                value: 1.18
                            }
                            PauseAnimation {
                                duration: 70
                            }
                            PropertyAction {
                                target: heartState
                                property: "beat"
                                value: 1
                            }
                        }
                        Timer {
                            id: mend
                            interval: 1400
                            onTriggered: heartState.broken = false
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        PxText {
                            text: root.greeting + ", " + (Quickshell.env("USER") || "angel") + " ♡"
                            kind: "title"
                        }
                        PxText {
                            text: I18n.t("с возвращением~", "welcome back~")
                            dim: true
                        }
                    }
                }
                PxField {
                    id: field
                    keepFocus: true
                    width: parent.width
                    password: true
                    placeholder: I18n.t("пароль", "password")
                    enabled: !root.lockScope.busy
                    property int lastLength: 0
                    onAccepted: root.lockScope.submit(text)
                    onTextChanged: {
                        const added = text.length > lastLength;
                        if (text.length !== lastLength)
                            root.lockScope.typed(text.length, added);
                        lastLength = text.length;
                    }
                    Component.onCompleted: focusField()
                }
                Row {
                    spacing: Theme.u * 4
                    visible: Config.lock.indicators && (root.lockScope.caps || Niri.layoutShort !== "")
                    PxBox {
                        visible: root.lockScope.caps
                        width: capsText.implicitWidth + Theme.u * 8
                        height: Theme.u * 11
                        color: Theme.danger
                        PxText {
                            id: capsText
                            anchors.centerIn: parent
                            text: "CAPS LOCK"
                            kind: "tiny"
                            color: "#ffffff"
                            font.bold: true
                        }
                    }
                    PxText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Niri.layoutShort !== ""
                        text: I18n.t("раскладка: ", "layout: ") + Niri.layoutShort
                        kind: "tiny"
                        dim: true
                    }
                }
                PxText {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: root.lockScope.status || (root.preview ? I18n.t("предпросмотр: пароль не проверяется, Esc — выход", "preview: the password is not checked, Esc to exit") : "")
                    color: root.lockScope.fails > 0 ? Theme.danger : Theme.textDim
                }
            }
            Keys.onEscapePressed: if (root.preview)
                Shell.lockPreview = false
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

    // hearts thrown by typing, failing and unlocking
    HeartBurst {
        id: burst
        anchors.fill: parent
    }
    // goodbye: the screen dissolves into big pixels
    NumberAnimation {
        id: dissolve
        target: pixels
        property: "block"
        from: Theme.u * 8
        to: Theme.u * 64
        duration: 600
        easing.type: Easing.InQuad
    }

    Connections {
        target: root.lockScope
        function onShake() {
            shakeAnim.restart();
            field.text = "";
            field.lastLength = 0;
            if (!root.reactions || !root.primary)
                return;
            heartState.broken = true;
            mend.restart();
            const p = bigHeart.mapToItem(root, bigHeart.width / 2, bigHeart.height / 2);
            for (let i = 0; i < 4; i++)
                burst.drop(p.x + (i - 1.5) * Theme.u * 4, p.y);
        }
        function onSuccess() {
            if (!root.reactions)
                return;
            const p = root.primary ? box.mapToItem(root, box.width / 2, box.height / 2) : Qt.point(root.width / 2, root.height / 2);
            burst.burst(p.x, p.y, root.primary ? 40 : 16, Theme.u * 9);
            dissolve.restart();
            fade.restart();
        }
        function onTyped(length, added) {
            if (!root.reactions || !root.primary)
                return;
            beatAnim.restart();
            const p = field.mapToItem(root, Math.min(field.width - Theme.u * 10, Theme.u * 12 + length * Theme.u * 7), 0);
            if (added)
                burst.pop(p.x, p.y);
        }
    }
    NumberAnimation {
        id: fade
        target: center
        property: "opacity"
        from: 1
        to: 0
        duration: 500
    }
}
