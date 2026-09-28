import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

PxPage {
    heading: I18n.t("Лирика", "Lyrics")
    subtitle: I18n.t("Текущая строка песни посередине панели. Источник — lrclib.net, трек берётся из MPRIS. Клик по строке открывает эту страницу.", "The current lyric line appears in the bar. Lyrics come from lrclib.net; track metadata comes from MPRIS. Click the line to open this page.")

    PxGroup {
        title: I18n.t("Показ", "Display")
        icon: "mic"
        width: parent.width
        SettingRow {
            label: I18n.t("Включено", "Enabled")
            hint: I18n.t("Mod+Alt+Y — быстро спрятать/показать", "Mod+Alt+Y toggles lyrics")
            PxToggle {
                checked: Config.lyrics.enabled
                onToggled: c => Config.lyrics.enabled = c
            }
        }
        SettingRow {
            label: I18n.t("На каких панелях", "Show on displays")
            hint: I18n.t("ничего не выбрано = на всех (где хватает места)", "No selection = all displays with enough space")
            Flow {
                width: parent.width
                spacing: Theme.u * 6
                Repeater {
                    model: Quickshell.screens
                    PxCheck {
                        required property var modelData
                        text: modelData.name
                        checked: (Config.lyrics.screens || []).includes(modelData.name)
                        onToggled: c => {
                            const l = (Config.lyrics.screens || []).filter(s => s !== modelData.name);
                            if (c)
                                l.push(modelData.name);
                            Config.lyrics.screens = l;
                        }
                    }
                }
            }
        }
        SettingRow {
            label: I18n.t("Рядом с текстом", "Beside the lyrics")
            PxSegmented {
                model: [
                    {
                        label: I18n.t("Нота", "Music note"),
                        value: "note"
                    },
                    {
                        label: I18n.t("Обложка", "Album cover"),
                        value: "cover"
                    }
                ]
                currentValue: Config.lyrics.artwork
                onActivated: v => Config.lyrics.artwork = v
            }
        }
        SettingRow {
            label: I18n.t("Сдвиг по времени", "Timing offset")
            hint: I18n.t("если текст спешит или опаздывает", "Adjust if the lyrics are early or late")
            PxSlider {
                width: parent.width
                from: -2000
                to: 2000
                stepSize: 50
                value: Config.lyrics.offsetMs
                suffix: I18n.t(" мс", " ms")
                onMoved: v => Config.lyrics.offsetMs = v
            }
        }
        SettingRow {
            label: I18n.t("Печатная машинка", "Typewriter animation")
            PxToggle {
                checked: Config.lyrics.typewriter
                onToggled: c => Config.lyrics.typewriter = c
            }
        }
        SettingRow {
            label: I18n.t("Любимый плеер", "Preferred player")
            hint: I18n.t("если играет несколько — брать этот", "Prefer this player when several are playing")
            PxField {
                width: Theme.u * 90
                text: Config.lyrics.preferPlayer
                onEdited: Config.lyrics.preferPlayer = text
            }
        }
    }

    PxGroup {
        title: I18n.t("Сейчас", "Current")
        icon: "music"
        width: parent.width
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            text: Lyrics.player ? "♪ " + Lyrics.title + " — " + Lyrics.artist + "  (" + (Lyrics.player.identity || "?") + ")" : I18n.t("ничего не играет", "Nothing is playing")
        }
        PxText {
            text: ({
                    "idle": I18n.t("ждём трек…", "Waiting for a track…"),
                    "loading": I18n.t("ищу текст…", "Searching for lyrics…"),
                    "ok": I18n.t("синхронный текст: ", "Synced lyrics: ") + Lyrics.lines.length + I18n.t(" строк", " lines"),
                    "plain": I18n.t("есть только текст без таймкодов", "Only unsynchronized lyrics are available"),
                    "instrumental": I18n.t("инструментал ♪", "Instrumental ♪"),
                    "notfound": I18n.t("текст не найден", "Lyrics not found"),
                    "error": I18n.t("нет сети / lrclib недоступен", "Offline / lrclib unavailable")
                })[Lyrics.status] || Lyrics.status
            dim: true
        }
        Row {
            spacing: Theme.u * 4
            PxButton {
                text: I18n.t("Найти заново", "Search again")
                icon: "refresh"
                onClicked: Lyrics.refetch()
            }
            PxButton {
                text: Lyrics.visibleToggle ? I18n.t("Скрыть", "Hide") : I18n.t("Показать", "Show")
                icon: "mic"
                onClicked: Lyrics.visibleToggle = !Lyrics.visibleToggle
            }
        }
    }
    PxGroup {
        width: parent.width
        title: I18n.t("Текст песни", "Song lyrics")
        visible: Lyrics.plainText !== ""
        icon: "music"
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            text: Lyrics.plainText
            textFormat: Text.PlainText
        }
    }
}
