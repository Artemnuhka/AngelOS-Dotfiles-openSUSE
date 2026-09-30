pragma Singleton

import QtQuick
import Quickshell

// Only one bar popup may be open at a time.
Singleton {
    id: root

    property var active: null
    property var registered: []
    // A popup's input grab only ends on clicks outside angelOS, so presses on the
    // bar itself close the open popup here. The click that follows such a press
    // must not reopen the popup it just closed (its own button toggles it).
    property var dismissed: null
    property double dismissedAt: 0
    function barPressed() {
        if (!active)
            return;
        dismissed = active;
        dismissedAt = Date.now();
        close(active);
    }
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
        if (popup === dismissed && Date.now() - dismissedAt < 600) {
            dismissed = null;
            return;
        }
        dismissed = null;
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
