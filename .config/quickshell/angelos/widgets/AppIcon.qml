import QtQuick
import Quickshell
import qs.config

// App icon by app-id / icon name; falls back to a pixel window.
Item {
    id: root

    property string appId: ""
    property string iconName: ""
    property int size: Theme.u * 8
    property string tint: "off"   // off | mono | accent

    readonly property string resolved: {
        let name = iconName;
        if (!name && appId) {
            const e = DesktopEntries.heuristicLookup(appId);
            name = e && e.icon ? e.icon : appId;
        }
        if (!name)
            return "";
        if (name.startsWith("/") || name.includes("://"))
            return name.startsWith("/") ? "file://" + name : name;
        return Quickshell.iconPath(name, true) || Quickshell.iconPath(name.toLowerCase(), true) || "";
    }

    implicitWidth: size
    implicitHeight: size

    TintedImage {
        anchors.fill: parent
        visible: root.resolved !== ""
        source: root.resolved
        size: root.size
        mode: root.tint
    }
    PxIcon {
        anchors.centerIn: parent
        visible: root.resolved === ""
        name: "window"
        pixel: Math.max(1, Math.floor(root.size / 10))
    }
}
