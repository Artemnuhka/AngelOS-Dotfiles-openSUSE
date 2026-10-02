import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.bar
import "."

PxButton {
    id: root

    property var plugin
    property string screenName
    property var barWindow

    compact: true
    flat: true
    icon: "gauge"
    text: Speed.running ? "…" : ""
    checked: popup.visible
    onClicked: popup.toggle()

    BarPopup {
        id: popup
        panelId: "speedtest"
        anchorItem: root
        above: BarLayout.bottom
        title: "speedtest.exe"
        icon: "gauge"
        contentWidth: Theme.u * 150
        contentHeight: Theme.u * 205
        PxScroll {
            anchors.fill: parent
            contentHeight: panel.implicitHeight
            Panel {
                id: panel
                width: parent.width
                plugin: root.plugin
            }
        }
    }
}
