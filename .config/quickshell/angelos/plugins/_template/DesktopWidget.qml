import QtQuick
import qs.config
import qs.widgets

// Desktop widget content. angelOS wraps it in a draggable "__NAME__" window
// (title from manifest "desktopTitle"); size comes from implicitWidth/implicitHeight.
// Optional: `property bool wantVisible` hides the frame when false.
Item {
    property var plugin
    property string screenName
    property var widget          // {uid, x, y, settings} of this instance

    implicitWidth: label.implicitWidth + Theme.u * 10
    implicitHeight: label.implicitHeight + Theme.u * 4

    PxText {
        id: label
        anchors.centerIn: parent
        text: "кликов: " + (plugin ? plugin.get("clicks", 0) : 0)
    }
}
