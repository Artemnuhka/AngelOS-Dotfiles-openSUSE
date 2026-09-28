import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.bar

PxButton {
    id: root

    property bool above: true
    property bool small: false

    text: ""
    icon: ""
    implicitWidth: logo.implicitWidth + Theme.u * 8
    implicitHeight: Math.max(Theme.u * 15, logo.implicitHeight + Theme.u * 3)
    AngelLogo {
        id: logo
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.down ? Theme.u : 0
        anchors.verticalCenterOffset: root.down ? Theme.u : 0
        emblemOnly: root.small
    }
    kind: small ? "body" : "title"
    checked: menu.visible
    compact: small
    onClicked: menu.toggle()

    StartMenu {
        id: menu
        anchorItem: root
        above: root.above
    }
}
