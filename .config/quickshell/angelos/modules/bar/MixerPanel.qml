pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

BarPopup {
    id: root

    title: I18n.t("звук.exe", "audio.exe")
    icon: "speaker"
    contentWidth: Theme.u * 170
    contentHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: Theme.u * 5

        PxText {
            kind: "title"
            text: I18n.t("Выход", "Output")
        }
        PxCombo {
            width: parent.width
            model: Audio.sinks.map(n => ({
                        "label": Audio.nodeName(n),
                        "value": n.id
                    }))
            currentValue: Audio.sink ? Audio.sink.id : -1
            onActivated: v => Audio.setDefaultSink(Audio.sinks.find(n => n.id === v))
        }
        Row {
            width: parent.width
            spacing: Theme.u * 3
            PxButton {
                compact: true
                icon: Audio.muted ? "speakerMute" : "speaker"
                onClicked: Audio.toggleMute()
            }
            PxSlider {
                width: parent.width - Theme.u * 20
                anchors.verticalCenter: parent.verticalCenter
                from: 0
                to: 1.5
                value: Audio.volume
                valueScale: 100
                suffix: "%"
                onMoved: v => Audio.setVolume(v)
            }
        }
        PxText {
            kind: "title"
            text: I18n.t("Микрофон", "Microphone")
        }
        Row {
            width: parent.width
            spacing: Theme.u * 3
            PxButton {
                compact: true
                icon: Audio.micMuted ? "micMute" : "mic"
                onClicked: Audio.toggleMic()
            }
            PxSlider {
                width: parent.width - Theme.u * 20
                anchors.verticalCenter: parent.verticalCenter
                from: 0
                to: 1.5
                value: Audio.micVolume
                valueScale: 100
                suffix: "%"
                onMoved: v => {
                    if (Audio.source && Audio.source.audio)
                        Audio.source.audio.volume = v;
                }
            }
        }
        PxText {
            visible: Audio.streams.length > 0
            kind: "title"
            text: I18n.t("Приложения", "Applications")
        }
        Repeater {
            model: Audio.streams
            Column {
                id: s
                required property var modelData
                width: col.width
                spacing: Theme.u
                PxText {
                    width: parent.width
                    elide: Text.ElideRight
                    text: s.modelData.properties["application.name"] || Audio.nodeName(s.modelData)
                    dim: true
                }
                PxSlider {
                    width: parent.width
                    from: 0
                    to: 1.5
                    value: s.modelData.audio ? s.modelData.audio.volume : 0
                    valueScale: 100
                    suffix: "%"
                    onMoved: v => s.modelData.audio.volume = v
                }
            }
        }
    }
}
