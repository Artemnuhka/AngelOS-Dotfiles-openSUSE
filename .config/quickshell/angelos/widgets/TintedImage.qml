import QtQuick
import qs.config

// Image that can be recolored to the theme (mode: off | mono | accent).
Item {
    id: root

    property alias source: img.source
    property string mode: "off"
    property int size: Theme.u * 8

    implicitWidth: size
    implicitHeight: size

    Image {
        id: img
        anchors.fill: parent
        sourceSize: Qt.size(root.size, root.size)
        smooth: false
        asynchronous: true
        visible: root.mode === "off"
    }
    ShaderEffect {
        anchors.fill: parent
        visible: root.mode !== "off" && img.status === Image.Ready
        property var source: img
        property color dark: root.mode === "mono" ? (Theme.dark ? Theme.textDim : Theme.edge) : Theme.mix(Theme.accent, Theme.dark ? Theme.face : Theme.edge, 0.35)
        property color light: root.mode === "mono" ? Theme.text : Theme.mix(Theme.accent, "#ffffff", Theme.dark ? 0.55 : 0.2)
        property real levels: 4
        fragmentShader: Qt.resolvedUrl("../shaders/tint.frag.qsb")
    }
}
