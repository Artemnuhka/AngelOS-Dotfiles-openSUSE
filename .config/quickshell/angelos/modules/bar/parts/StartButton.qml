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
    // in hell (Y2K → Angel or demon → Start in hell) the button is hers: obsidian and blood,
    // the Hell wordmark, horns, and little flames licking up from its foot
    readonly property bool hellish: Angel.demon && !!Config.y2k.hellStart
    hell: hellish
    ShaderEffect {
        id: flames
        visible: root.hellish
        readonly property int rows: 5
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.u
        x: Theme.u
        width: parent.width - Theme.u * 2
        height: Theme.u * rows
        opacity: 0.85
        property real time: 0
        property real seed: 1.7
        property size cells: Qt.size(Math.max(1, Math.round(width / Theme.u)), rows)
        fragmentShader: Qt.resolvedUrl("../../../shaders/hell_flames.frag.qsb")
        Timer {
            interval: 160
            repeat: true
            running: flames.visible && root.visible
            onTriggered: flames.time += 0.16
        }
    }
    implicitWidth: logo.implicitWidth + Theme.u * 8
    implicitHeight: Math.max(Theme.u * 15, logo.implicitHeight + Theme.u * 3)
    AngelLogo {
        id: logo
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.down ? Theme.u : 0
        anchors.verticalCenterOffset: root.down ? Theme.u : 0
        // Settings → Bar → Logo → "Wordmark on the Start button": off leaves the emblem
        emblemOnly: root.small || Config.bar.logoText === false
        hell: root.hellish
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
