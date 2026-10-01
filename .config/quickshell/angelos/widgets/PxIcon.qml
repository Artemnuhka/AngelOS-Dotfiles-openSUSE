import QtQuick
import qs.config
import "Icons.js" as Icons

// Pixel-art icon rendered from an ASCII bitmap (see Icons.js).
Image {
    id: root

    property string name: "heart"
    property var bitmap: null   // optional custom rows, overrides `name`
    property int pixel: Theme.u
    // a fractional art pixel when the size has to match something exactly (AngelLogo's
    // pixel wordmarks next to text); 0 = `pixel`
    property real exactPixel: 0
    readonly property real _px: exactPixel > 0 ? exactPixel : pixel
    property bool hollow: false
    property color ink: Theme.dark ? Theme.text : Theme.edge
    property color fill: Theme.accent
    property color fill2: Theme.accent2
    property color fill3: Theme.accent3
    property color light: "#ffffff"
    property color body: Theme.dark ? Theme.faceAlt : Theme.sunken
    property color bad: Theme.danger
    // more colours for detailed art: {"char": "#rrggbb"}, also overriding the ones above
    property var palette: ({})

    readonly property var _svg: Icons.svg(bitmap && bitmap.length ? bitmap : name, Object.assign({
        "#": Theme.hex(ink),
        "o": Theme.hex(fill),
        "x": Theme.hex(fill2),
        "y": Theme.hex(fill3),
        "w": Theme.hex(light),
        "f": Theme.hex(body),
        "r": Theme.hex(bad)
    }, palette || {}), hollow)

    source: _svg.url
    width: Math.round(_svg.width * _px)
    height: Math.round(_svg.height * _px)
    sourceSize: Qt.size(width, height)
    smooth: false
    mipmap: false
    cache: true
}
