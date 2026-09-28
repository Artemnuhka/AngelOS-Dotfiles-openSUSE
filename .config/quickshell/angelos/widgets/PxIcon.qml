import QtQuick
import qs.config
import "Icons.js" as Icons

// Pixel-art icon rendered from an ASCII bitmap (see Icons.js).
Image {
    id: root

    property string name: "heart"
    property var bitmap: null   // optional custom rows, overrides `name`
    property int pixel: Theme.u
    property bool hollow: false
    property color ink: Theme.dark ? Theme.text : Theme.edge
    property color fill: Theme.accent
    property color fill2: Theme.accent2
    property color fill3: Theme.accent3
    property color light: "#ffffff"
    property color body: Theme.dark ? Theme.faceAlt : Theme.sunken
    property color bad: Theme.danger

    readonly property var _svg: Icons.svg(bitmap && bitmap.length ? bitmap : name, {
        "#": Theme.hex(ink),
        "o": Theme.hex(fill),
        "x": Theme.hex(fill2),
        "y": Theme.hex(fill3),
        "w": Theme.hex(light),
        "f": Theme.hex(body),
        "r": Theme.hex(bad)
    }, hollow)

    source: _svg.url
    width: _svg.width * pixel
    height: _svg.height * pixel
    sourceSize: Qt.size(width, height)
    smooth: false
    mipmap: false
    cache: true
}
