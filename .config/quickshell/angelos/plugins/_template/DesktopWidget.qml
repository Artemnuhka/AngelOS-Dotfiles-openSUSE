import QtQuick
import qs.config
import qs.widgets

// Drawn on the wallpaper layer of every screen (fills the screen; position yourself).
Item {
    property var plugin
    property string screenName

    PxWindow {
        x: Theme.u * 20
        y: Theme.u * 20
        width: Theme.u * 100
        height: Theme.u * 50
        title: "__NAME__"
        closable: false
        PxText {
            text: I18n.t("кликов: ", "Clicks: ") + (plugin ? plugin.get("clicks", 0) : 0)
        }
    }
}
