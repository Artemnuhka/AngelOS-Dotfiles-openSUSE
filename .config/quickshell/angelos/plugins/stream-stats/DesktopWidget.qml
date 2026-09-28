import QtQuick
import qs.config
import qs.widgets
import "."

Item {
    id: root
    property var plugin
    property string screenName
    readonly property string onScreen: plugin ? plugin.get("screen", "") : ""

    PxWindow {
        visible: root.onScreen === "" || root.onScreen === root.screenName
        x: root.width - width - Theme.u * 20
        y: Theme.u * 30
        width: Theme.u * 160
        height: titleHeight + col.implicitHeight + Theme.pad * 2 + Theme.u * 8
        title: "stats.exe"
        icon: "heart"
        compact: true
        closable: false

        Column {
            id: col
            width: parent.width
            spacing: Theme.u * 4
            Repeater {
                model: [
                    {
                        "label": I18n.t("Стресс", "Stress"),
                        "icon": "heart",
                        "v": Stats.stress,
                        "c": Theme.danger
                    },
                    {
                        "label": I18n.t("Тьма", "Darkness"),
                        "icon": "heart",
                        "v": Stats.darkness,
                        "c": Theme.accent4
                    },
                    {
                        "label": I18n.t("Любовь", "Love"),
                        "icon": "heart",
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
}
