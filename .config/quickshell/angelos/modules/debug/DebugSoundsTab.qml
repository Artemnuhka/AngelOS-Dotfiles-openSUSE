pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Every sound: each file of the synthesised pack and of sounds/custom (what is on disk, so
// a new one shows up by itself), at the volume the shell would play it (the volume, "Her
// voice" for the helper's own); and each event the way the shell routes it (its tweaks, the
// Windose pack).
Column {
    id: root

    spacing: Theme.u * 5

    PxGroup {
        width: parent.width
        title: I18n.t("Файлы", "Files")
        icon: "speaker"
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            kind: "tiny"
            text: Sounds.dir + I18n.t(" · громкость ", " · volume ") + Math.round(Config.y2k.soundVolume * 100) + "%" + I18n.t(" · её голос ", " · her voice ") + Math.round(Config.y2k.helperVolume * 100) + "%" + (Sounds.ready ? "" : I18n.t(" · пакет ещё собирается", " · the pack is still being made"))
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 2
            Repeater {
                model: GameDebug.soundFiles
                PxButton {
                    required property string modelData
                    compact: true
                    icon: "play"
                    text: (modelData.indexOf("/custom/") >= 0 ? "custom/" : "") + modelData.split("/").pop()
                    onClicked: GameDebug.playFile(modelData)
                }
            }
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 2
            PxButton {
                compact: true
                icon: "refresh"
                text: I18n.t("Пересканировать", "Rescan")
                onClicked: GameDebug.rescan()
            }
            PxButton {
                compact: true
                icon: "sparkle"
                text: I18n.t("Пересобрать пакет", "Make the pack again")
                onClicked: {
                    Quickshell.execDetached(["python3", Quickshell.shellDir + "/scripts/y2k-sounds.py", Sounds.dir]);
                    GameDebug.note(I18n.t("пакет собирается заново", "the pack is being made again"));
                }
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("События (как играет оболочка)", "Events (as the shell plays them)")
        icon: "bell"
        Flow {
            width: parent.width
            spacing: Theme.u * 2
            Repeater {
                model: Sounds.events
                PxButton {
                    required property string modelData
                    compact: true
                    icon: Sounds.isOn(modelData) ? "speaker" : "speakerMute"
                    text: modelData
                    onClicked: {
                        Sounds.preview(modelData);
                        GameDebug.note("▶ " + modelData);
                    }
                }
            }
        }
    }
}
