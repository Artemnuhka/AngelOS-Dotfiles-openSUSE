import QtQuick
import qs.config
import qs.widgets
import "."

PxButton {
    property var plugin
    property string screenName
    property var barWindow

    compact: true
    flat: true
    icon: "heart"
    text: Math.round(Stats.stress * 100) + "%"
}
