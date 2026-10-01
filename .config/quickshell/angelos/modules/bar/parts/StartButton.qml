import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

PxButton {
    id: root

    property bool above: true
    property bool small: false
    property string screenName: ""
    property var barWindow: null

    text: ""
    icon: ""
    implicitWidth: logo.implicitWidth + Theme.u * 8
    implicitHeight: Math.max(Theme.u * 15, logo.implicitHeight + Theme.u * 3)
    AngelLogo {
        id: logo
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.down ? Theme.u : 0
        anchors.verticalCenterOffset: root.down ? Theme.u : 0
        // Settings → Bar → Logo → "Wordmark on the Start button": off leaves the emblem
        emblemOnly: root.small || Config.bar.logoText === false
    }
    kind: small ? "body" : "title"
    checked: Shell.startScreen !== "" && Shell.startScreen === screenName
    compact: small
    onClicked: Shell.toggleStart(screenName)

    // the Start overlay opens right above/below this button
    Component.onCompleted: if (screenName && barWindow)
        Shell.registerStartButton(screenName, root, barWindow)
    Component.onDestruction: Shell.unregisterStartButton(screenName, root)
}
