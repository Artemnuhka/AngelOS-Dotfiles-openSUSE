pragma Singleton

import QtQuick
import Quickshell

// Only one bar popup may be open at a time.
Singleton {
    id: root

    property var active: null
    property var registered: []
    function registerPopup(popup) {
        registered = registered.concat([popup]);
    }
    function unregisterPopup(popup) {
        if (active === popup)
            active = null;
        registered = registered.filter(p => p !== popup);
    }
    function showPanel(name, output) {
        const popup = registered.find(p => p.panelId === name && (!output || p.outputName === output));
        if (popup)
            toggle(popup);
        return !!popup;
    }

    function toggle(popup) {
        if (!popup)
            return;
        if (active === popup) {
            popup.visible = false;
            active = null;
            return;
        }
        if (active)
            active.visible = false;
        active = popup;
        popup.visible = true;
    }

    function close(popup) {
        if (popup)
            popup.visible = false;
        if (active === popup)
            active = null;
    }
}
