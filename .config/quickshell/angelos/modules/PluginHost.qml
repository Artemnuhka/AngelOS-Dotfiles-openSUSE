pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services

// Instantiates background services of enabled plugins (manifest "main").
Scope {
    Instantiator {
        model: Plugins.services
        delegate: LazyLoader {
            id: loader
            required property var modelData
            active: true
            source: Plugins.url(modelData, modelData.main)
            onItemChanged: if (item && item.hasOwnProperty("plugin"))
                item.plugin = Plugins.context(modelData)
        }
    }
}
