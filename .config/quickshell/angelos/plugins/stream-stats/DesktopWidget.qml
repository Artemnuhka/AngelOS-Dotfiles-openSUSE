import QtQuick
import qs.config
import qs.widgets
import "."

// NGO-style stats ("stats.exe"). The host draws the frame and handles dragging.
Item {
    id: root
    property var plugin
    property string screenName
    property var widget

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    Column {
        id: col
        spacing: Theme.u * 4
        Repeater {
            // hell (manifest "realms"): the same stats as sins, skulls instead of hearts
            model: [
                {
                    "label": I18n.t("Стресс", "Stress"),
                    "hell": I18n.t("Гнев", "Wrath"),
                    "v": Stats.stress,
                    "c": Theme.danger,
                    "hc": Theme.hellBlood
                },
                {
                    "label": I18n.t("Тьма", "Darkness"),
                    "hell": I18n.t("Бездна", "Abyss"),
                    "v": Stats.darkness,
                    "c": Theme.accent4,
                    "hc": Theme.hellEmber
                },
                {
                    "label": I18n.t("Любовь", "Love"),
                    "hell": I18n.t("Одержимость", "Obsession"),
                    "v": Stats.love,
                    "c": Theme.accent,
                    "hc": Theme.hellFlame
                }
            ]
            Row {
                required property var modelData
                spacing: Theme.u * 4
                PxText {
                    width: Theme.u * 30
                    text: Theme.hell ? modelData.hell : modelData.label
                    font.family: Theme.hell && Theme.latin(text) ? Theme.fontHell : Theme.fontBody
                    font.pixelSize: Theme.hell && Theme.latin(text) ? Theme.hellPx(Theme.fs) : Theme.sizeBody
                    color: Theme.hell ? Theme.hellText : Theme.text
                }
                PxHearts {
                    count: 8
                    value: modelData.v
                    icon: Theme.hell ? "skull" : "heart"
                    fill: Theme.hell ? modelData.hc : modelData.c
                }
            }
        }
    }
}
