import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

PxPage {
    heading: I18n.t("Лирика", "Lyrics")
    subtitle: I18n.t("Текущая строка песни посередине панели. Трек берётся из любого MPRIS-плеера (Spotify, браузер с YouTube, mpv…), текст ищется по названию песни в нескольких источниках. Клик по строке открывает эту страницу.", "The current lyric line appears in the bar. Any MPRIS player works (Spotify, a browser with YouTube, mpv…); lyrics are searched by the song title in several sources. Click the line to open this page.")
    id: page

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
        title: I18n.t("Источники", "Sources")
        icon: "search"
        width: parent.width
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            text: I18n.t("Проверяются по порядку, пока не найдётся текст с таймкодами. Название чистится от «(Official Video)», «[MV]», feat. и «- Topic»; «Артист - Песня» из браузера разбирается на части.", "Tried in order until synced lyrics turn up. Titles lose “(Official Video)”, “[MV]”, feat. and “- Topic”; “Artist - Song” from a browser is split.")
        }
        Repeater {
            model: [["lrclib", "lrclib.net", I18n.t("синхронный текст, открытая база", "synced lyrics, open database")], ["netease", "NetEase Cloud Music", I18n.t("синхронный текст, много азиатской и мировой музыки", "synced lyrics, large Asian and worldwide catalogue")], ["ovh", "lyrics.ovh", I18n.t("только текст без таймкодов, запасной вариант", "plain text only, last resort")]]
            SettingRow {
                required property var modelData
                label: modelData[1]
                hint: modelData[2]
                PxToggle {
                    checked: (Config.lyrics.sources || []).includes(modelData[0])
                    onToggled: c => {
                        const order = ["lrclib", "netease", "ovh"];
                        const on = (Config.lyrics.sources || []).filter(s => s !== modelData[0]);
                        if (c)
                            on.push(modelData[0]);
                        Config.lyrics.sources = order.filter(s => on.includes(s));
                    }
                }
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
                    "error": I18n.t("нет сети / источники недоступны", "Offline / sources unavailable")
                })[Lyrics.status] || Lyrics.status
            dim: true
        }
        PxText {
            visible: !!Lyrics.player
            width: parent.width
            wrapMode: Text.Wrap
            kind: "tiny"
            dim: true
            text: I18n.t("ищу как: ", "searching as: ") + Lyrics.cleaned.artist + " — " + Lyrics.cleaned.title + (Lyrics.source ? I18n.t(" · источник: ", " · source: ") + Lyrics.source : "")
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
        title: I18n.t("Найти по названию", "Search by title")
        icon: "search"
        width: parent.width
        visible: !!Lyrics.player && Lyrics.title !== ""
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            text: I18n.t("Если нашлось не то или ничего: введи название (и артиста), выбери результат — он запомнится для этого трека.", "Wrong or no lyrics? Type the title (and artist) and pick a result — it is remembered for this track.")
        }
        Row {
            width: parent.width
            spacing: Theme.u * 3
            PxField {
                id: q
                width: parent.width - searchButton.width - Theme.u * 3
                placeholder: Lyrics.cleaned.artist + " " + Lyrics.cleaned.title
                onAccepted: Lyrics.search(text || placeholder)
            }
            PxButton {
                id: searchButton
                text: Lyrics.searching ? "…" : I18n.t("Искать", "Search")
                icon: "search"
                enabled: !Lyrics.searching
                onClicked: Lyrics.search(q.text || q.placeholder)
            }
        }
        Repeater {
            model: Lyrics.results
            PxBox {
                id: res
                required property var modelData
                width: parent.width
                height: resCol.implicitHeight + Theme.u * 6
                color: resMouse.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.15) : Theme.face
                Column {
                    id: resCol
                    x: Theme.u * 4
                    y: Theme.u * 3
                    width: parent.width - Theme.u * 8
                    PxText {
                        width: parent.width
                        elide: Text.ElideRight
                        text: res.modelData.title + " — " + res.modelData.artist
                        font.bold: true
                    }
                    PxText {
                        kind: "tiny"
                        dim: true
                        text: res.modelData.source + " · " + (res.modelData.synced ? I18n.t("с таймкодами", "synced") : I18n.t("без таймкодов", "plain")) + (res.modelData.duration ? " · " + Math.floor(res.modelData.duration / 60) + ":" + String(Math.round(res.modelData.duration % 60)).padStart(2, "0") : "")
                    }
                }
                MouseArea {
                    id: resMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Lyrics.pick(res.modelData)
                }
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
