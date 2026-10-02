import QtQuick
import qs.config

// Text with pixel-font defaults. kind: tiny | body | title | big | huge | mono
// In the grimoire's window (Theme.scriptWindow) it is handwritten instead (Theme.fontScript).
Text {
    property string kind: "body"
    property bool dim: false
    readonly property bool script: Theme.scriptWindow !== null && Window.window === Theme.scriptWindow && kind !== "mono"
    readonly property int basePx: kind === "tiny" ? Theme.sizeTiny : kind === "mono" ? Theme.sizeMono : kind === "title" ? Theme.sizeTitle : kind === "big" ? Theme.sizeBig : kind === "huge" ? Theme.sizeHuge : Theme.sizeBody

    color: dim ? Theme.textDim : Theme.text
    font.family: script ? Theme.fontScript : kind === "body" ? Theme.fontBody : kind === "mono" ? Theme.fontMono : Theme.fontTitle
    font.pixelSize: script ? Theme.scriptPx(Math.max(basePx, Theme.sizeTiny + 2)) : basePx
    font.hintingPreference: Font.PreferFullHinting
    renderType: script ? Text.QtRendering : Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    // AutoText would render HTML found in window titles, track names or the
    // clipboard (<img src=…> even fetches remote images). Opt in per use.
    textFormat: Text.PlainText
}
