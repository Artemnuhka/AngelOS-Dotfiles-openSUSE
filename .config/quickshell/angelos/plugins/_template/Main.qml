import QtQuick
import Quickshell
import qs.services

// Background service: lives while the plugin is enabled.
Item {
    property var plugin

    Component.onCompleted: console.log("plugin", plugin ? plugin.id : "?", "started")
}
