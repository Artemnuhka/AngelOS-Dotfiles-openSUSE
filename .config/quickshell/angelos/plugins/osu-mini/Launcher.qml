import QtQuick
import qs.config
import qs.services

// "osu" in the launcher opens the game.
QtObject {
    property var plugin
    property string pluginId
    readonly property string prefix: "osu"
    readonly property bool global: true
    signal changed

    function query(text, prefixed) {
        const q = text.toLowerCase();
        if (!prefixed && !("osu".startsWith(q) || q.startsWith("osu") || "игра".startsWith(q) || "game".startsWith(q)))
            return [];
        return [
            {
                "id": "play",
                "title": "osu!mini ♡",
                "subtitle": I18n.t("мини-игра: сердечки в такт", "mini game: hearts on the beat"),
                "icon": "heart",
                "score": prefixed ? 100 : 60
            }
        ];
    }
    function activate(id) {
        Shell.gameOpen = true;
    }
}
