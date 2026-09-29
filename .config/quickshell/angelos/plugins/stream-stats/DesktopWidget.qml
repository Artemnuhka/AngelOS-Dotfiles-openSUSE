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
            model: [
                {
                    "label": I18n.t("Стресс", "Stress"),
                    "v": Stats.stress,
                    "c": Theme.danger
                },
                {
                    "label": I18n.t("Тьма", "Darkness"),
                    "v": Stats.darkness,
                    "c": Theme.accent4
                },
                {
                    "label": I18n.t("Любовь", "Love"),
                    "v": Stats.love,
                    "c": Theme.accent
                }
            ]
            Row {
                required property var modelData
                spacing: Theme.u * 4
                PxText {
                    width: Theme.u * 30
                    text: modelData.label
                }
                PxHearts {
                    count: 8
                    value: modelData.v
                    fill: modelData.c
                }
            }
        }
    }
}
