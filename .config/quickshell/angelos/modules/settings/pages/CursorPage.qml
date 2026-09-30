pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// Pixel cursor themes: download/build, preview, apply everywhere.
PxPage {
    id: page

    heading: I18n.t("Курсор", "Cursor")
    subtitle: I18n.t("Пиксельные курсоры одним нажатием — одинаковые в niri, GTK и Qt, X11/XWayland, Steam и Flatpak. Темы скачиваются с проверкой SHA-256.", "Pixel cursors in one click — the same in niri, GTK and Qt, X11/XWayland, Steam and Flatpak. Themes are downloaded with SHA-256 checks.")

    Component.onCompleted: Cursors.refresh()
    readonly property int size: Config.cursor.size || 24

    PxGroup {
        title: I18n.t("Пиксельные темы", "Pixel themes")
        icon: "cursor"
        width: parent.width

        Grid {
            width: parent.width
            columns: Math.max(1, Math.floor(width / (Theme.u * 150)))
            spacing: Theme.u * 3
            Repeater {
                model: Cursors.catalog
                PxBox {
                    id: card
                    required property var modelData
                    readonly property bool current: Cursors.theme === modelData.theme
                    readonly property bool working: Cursors.busy && (Cursors.working === modelData.id || Cursors.working === modelData.theme)
                    width: (parent.width - (parent.columns - 1) * parent.spacing) / parent.columns
                    height: cardCol.implicitHeight + Theme.u * 8
                    sunken: current
                    color: current ? Theme.mix(Theme.face, Theme.accent, 0.3) : Theme.face
                    Column {
                        id: cardCol
                        x: Theme.u * 4
                        y: Theme.u * 4
                        width: parent.width - Theme.u * 8
                        spacing: Theme.u * 2
                        PxText {
                            text: (card.current ? "♡ " : "") + card.modelData.name
                            font.bold: true
                        }
                        // preview strip: arrow, hand, text, wait, grab, forbidden
                        Rectangle {
                            width: parent.width
                            height: Theme.u * 22
                            color: Theme.dark ? "#1b1d24" : "#e9e3ec"
                            border.width: Math.max(1, Theme.u / 2)
                            border.color: Theme.lo
                            Image {
                                anchors.centerIn: parent
                                visible: card.modelData.installed && source !== ""
                                source: card.modelData.preview ? "file://" + card.modelData.preview + "?" + Cursors.catalog.length : ""
                                cache: false
                                smooth: false
                                height: parent.height - Theme.u * 4
                                fillMode: Image.PreserveAspectFit
                            }
                            PxText {
                                anchors.centerIn: parent
                                visible: !card.modelData.installed
                                text: I18n.t("ещё не скачан", "not downloaded yet")
                                kind: "tiny"
                                dim: true
                            }
                        }
                        PxText {
                            width: parent.width
                            text: card.modelData.about
                            kind: "tiny"
                            dim: true
                            wrapMode: Text.Wrap
                        }
                        PxText {
                            width: parent.width
                            text: "© " + card.modelData.license
                            kind: "tiny"
                            dim: true
                            wrapMode: Text.Wrap
                        }
                        Flow {
                            width: parent.width
                            spacing: Theme.u * 2
                            PxButton {
                                compact: true
                                visible: !card.modelData.installed
                                enabled: !Cursors.busy
                                icon: "download"
                                text: card.working ? I18n.t("качаю…", "downloading…") : I18n.t("Скачать и включить", "Get and use")
                                accent: true
                                onClicked: {
                                    Config.cursor.theme = card.modelData.theme;
                                    Cursors.install(card.modelData.id, true);
                                }
                            }
                            PxButton {
                                compact: true
                                visible: card.modelData.installed && !card.current
                                enabled: !Cursors.busy
                                text: card.working ? I18n.t("применяю…", "applying…") : I18n.t("Включить", "Use")
                                accent: true
                                onClicked: Cursors.apply(card.modelData.theme, page.size)
                            }
                            PxButton {
                                compact: true
                                visible: card.modelData.id === "angelos" && card.modelData.installed
                                enabled: !Cursors.busy
                                icon: "palette"
                                text: I18n.t("Под акцент", "Match accent")
                                onClicked: {
                                    if (card.current)
                                        Cursors.recolor();
                                    else
                                        Cursors.install("angelos", false);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    PxGroup {
        title: I18n.t("Размер и совместимость", "Size and compatibility")
        icon: "gear"
        width: parent.width
        SettingRow {
            label: I18n.t("Размер", "Size")
            hint: I18n.t("пиксельные темы angelOS чётче всего в 24, 36 и 48", "angelOS pixel themes are crispest at 24, 36 and 48")
            PxSegmented {
                model: [24, 32, 36, 48].map(v => ({
                            "label": String(v),
                            "value": v
                        }))
                currentValue: page.size
                onActivated: v => {
                    if (Cursors.theme)
                        Cursors.apply(Cursors.theme, v);
                    else
                        Config.cursor.size = v;
                }
            }
        }
        SettingRow {
            label: I18n.t("Flatpak-приложения", "Flatpak apps")
            hint: I18n.t("разрешить им читать темы курсоров (flatpak override --user)", "let them read cursor themes (flatpak override --user)")
            PxToggle {
                checked: Config.cursor.flatpak
                onToggled: c => Config.cursor.flatpak = c
            }
        }
        SettingRow {
            visible: Cursors.other.length > 0
            label: I18n.t("Другие темы в системе", "Other themes on the system")
            hint: I18n.t("например, вернуть прежний курсор", "for example, to go back to the old one")
            PxCombo {
                width: parent.width
                model: Cursors.other.map(n => ({
                            "label": n,
                            "value": n
                        }))
                currentValue: Cursors.other.includes(Cursors.theme) ? Cursors.theme : ""
                placeholder: I18n.t("выбрать…", "choose…")
                onActivated: v => Cursors.apply(v, page.size)
            }
        }
        // where the theme is really set right now
        Flow {
            width: parent.width
            spacing: Theme.u * 3
            Repeater {
                model: [
                    {
                        "k": "niri",
                        "v": Cursors.status.niri ? Cursors.status.niri[0] : null
                    },
                    {
                        "k": "GTK 3",
                        "v": Cursors.status["gtk-3.0"]
                    },
                    {
                        "k": "GTK 4",
                        "v": Cursors.status["gtk-4.0"]
                    },
                    {
                        "k": "X11 / Steam",
                        "v": Cursors.status.x11
                    },
                    {
                        "k": "gsettings",
                        "v": Cursors.status.gsettings
                    }
                ].filter(x => x.v !== undefined)
                PxText {
                    required property var modelData
                    readonly property bool same: !!Cursors.theme && modelData.v === Cursors.theme
                    text: (same ? "✓ " : "✕ ") + modelData.k + ": " + (modelData.v || "—")
                    kind: "tiny"
                    color: same ? Theme.ok : Theme.textDim
                }
            }
        }
        PxText {
            visible: Cursors.log !== ""
            width: parent.width
            wrapMode: Text.Wrap
            text: Cursors.log
            color: Cursors.log.startsWith(I18n.t("Ошибка", "Error")) ? Theme.danger : Theme.textDim
        }
    }
}
