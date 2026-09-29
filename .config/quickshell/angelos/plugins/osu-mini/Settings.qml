import QtQuick
import qs.config
import qs.services
import qs.widgets

Column {
    id: root
    property var plugin
    width: parent ? parent.width : 400
    spacing: Theme.u * 5

    PxGroup {
        title: "osu!mini"
        icon: "heart"
        width: parent.width
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            text: I18n.t("Кликай по сердечкам, когда сжимающийся контур совпадает с ними (или жми Z / X, наведя курсор). 300 / 100 / 50 — по точности, промах разбивает сердце и сбрасывает комбо. Сердечки здоровья тают со временем и пополняются попаданиями.", "Click each heart when the shrinking outline meets it (or press Z / X with the cursor on it). 300 / 100 / 50 by timing; a miss breaks the heart and the combo. The health hearts drain over time and refill with hits.")
        }
        SettingRow {
            label: I18n.t("Звуки попаданий", "Hit sounds")
            PxToggle {
                checked: root.plugin ? root.plugin.get("sound", true) : true
                onToggled: c => root.plugin.set("sound", c)
            }
        }
        Repeater {
            model: ["easy", "normal", "hard", "insane"]
            SettingRow {
                required property string modelData
                label: I18n.t("Рекорды · ", "Best · ") + modelData
                PxText {
                    text: [30, 45, 90].map(s => s + I18n.t(" с: ", " s: ") + (root.plugin ? root.plugin.get("best_" + modelData + "_" + s, 0) : 0)).join("   ")
                    dim: true
                }
            }
        }
        PxButton {
            text: I18n.t("Играть ♡", "Play ♡")
            icon: "play"
            accent: true
            onClicked: {
                Shell.settingsOpen = false;
                Shell.gameOpen = true;
            }
        }
    }
}
