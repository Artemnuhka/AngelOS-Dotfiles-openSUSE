import QtQuick
import qs.config

// Text with pixel-font defaults. kind: tiny | body | title | big | huge | mono
Text {
    property string kind: "body"
    property bool dim: false

    color: dim ? Theme.textDim : Theme.text
    font.family: kind === "body" ? Theme.fontBody : kind === "mono" ? Theme.fontMono : Theme.fontTitle
    font.pixelSize: kind === "tiny" ? Theme.sizeTiny : kind === "mono" ? Theme.sizeMono : kind === "title" ? Theme.sizeTitle : kind === "big" ? Theme.sizeBig : kind === "huge" ? Theme.sizeHuge : Theme.sizeBody
    font.hintingPreference: Font.PreferFullHinting
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    // AutoText would render HTML found in window titles, track names or the
    // clipboard (<img src=…> even fetches remote images). Opt in per use.
    textFormat: Text.PlainText
}
