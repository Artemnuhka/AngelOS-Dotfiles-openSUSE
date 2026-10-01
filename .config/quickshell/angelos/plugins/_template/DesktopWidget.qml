import QtQuick
import qs.config
import qs.widgets

// Desktop widget content. angelOS wraps it in a draggable "__NAME__" window
// (title from manifest "desktopTitle"); size comes from implicitWidth/implicitHeight.
// Optional: `property bool wantVisible` hides the frame when false.
// Heaven and hell (manifest "realms"): while the demon rules Theme.hell is true —
// the host burns the widget over and draws the hell frame, the content draws its
// own hell look with the same data (docs/PLUGINS.md, "Два измерения").
Item {
    property var plugin
    property string screenName
    property var widget          // {uid, x, y, settings} of this instance

    implicitWidth: label.implicitWidth + Theme.u * 10
    implicitHeight: label.implicitHeight + Theme.u * 4

    PxText {
        id: label
        anchors.centerIn: parent
        // the same count; in hell they are souls, in blackletter if the text is Latin
        text: (Theme.hell ? I18n.t("душ: ", "souls: ") : I18n.t("кликов: ", "clicks: ")) + (plugin ? plugin.get("clicks", 0) : 0)
        font.family: Theme.hell && Theme.latin(text) ? Theme.fontHell : Theme.fontBody
        font.pixelSize: Theme.hell && Theme.latin(text) ? Theme.hellPx(Theme.fs) : Theme.sizeBody
        color: Theme.hell ? Theme.hellFlame : Theme.text
    }
}
