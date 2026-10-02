import QtQuick
import qs.config

// For a picture's layer.effect while it sits in the grimoire (shaders/grimoire_photo.frag):
// it comes out as an engraving the right way round instead of a negative. Use with
//   layer.enabled: Theme.scriptWindow !== null && Window.window === Theme.scriptWindow
//   layer.effect: GrimoirePhoto {}
ShaderEffect {
    fragmentShader: Qt.resolvedUrl("../shaders/grimoire_photo.frag.qsb")
    property real invert: Theme.dark ? 1 : 0
}
