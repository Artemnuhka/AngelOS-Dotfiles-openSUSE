import QtQuick
import qs.config
import qs.widgets

// Shown in the panel next to the tray.
PxButton {
    property var plugin
    property string screenName
    property var barWindow

    compact: true
    icon: "heart"
    text: plugin ? plugin.get("label", "♡") : "♡"
    onClicked: plugin.set("clicks", plugin.get("clicks", 0) + 1)
}
