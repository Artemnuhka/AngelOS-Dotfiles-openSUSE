import QtQuick
import qs.config
import qs.services
import qs.widgets

PxButton {
    visible: Niri.keyboardLayouts.length > 1
    compact: true
    text: Niri.layoutShort
    onClicked: Niri.switchLayout(true)
}
