pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services

// Invisible stand-in for one desktop widget on the angelos-desktop surface.
// The widget itself is drawn in the wallpaper surface (pinned, see
// DesktopWidgetHost); this item sits at the same place, drags the widget by
// its title bar and replays everything else to the visible copy.
Item {
    id: proxy

    required property string uid
    required property Item area
    readonly property var host: DesktopWidgets.hosts[uid] || null
    // right-click on nothing clickable: the desktop menu, as before
    signal contextMenu(real x, real y)

    visible: !!host && host.visible
    x: host ? host.x : 0
    y: host ? host.y : 0
    width: host ? host.width : 0
    height: host ? host.height : 0

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.ArrowCursor

        property bool dragging: false
        property int forwarded: Qt.NoButton   // button whose press went to the widget
        property point start                  // pointer at press, in area coordinates
        property point origin                 // widget position at press
        // Both surfaces share one Qt pointer device, so a replayed event can come
        // straight back here (this area still holds the grab) and replay itself
        // again, until the JS stack runs out. Ignore our own events.
        property bool replaying: false

        function replay(fn) {
            if (replaying)
                return;
            replaying = true;
            try {
                fn();
            } finally {
                replaying = false;
            }
        }

        onPositionChanged: m => {
            if (!proxy.host || replaying)
                return;
            if (dragging) {
                // the button went up where this surface never saw it (hot corner →
                // overview, another surface): the widget stayed glued to the pointer
                if (!(m.buttons & Qt.LeftButton)) {
                    endDrag();
                    return;
                }
                const p = mapToItem(proxy.area, m.x, m.y);
                DesktopWidgets.drag = {
                    "uid": proxy.uid,
                    "x": proxy.host.clampX(origin.x + p.x - start.x),
                    "y": proxy.host.clampY(origin.y + p.y - start.y)
                };
                return;
            }
            // a held button the widget never saw (pressed on a bare spot) is not replayed
            if (!pressed || forwarded !== Qt.NoButton)
                replay(() => proxy.host.move(m.x, m.y, m.buttons));
            if (!pressed)
                cursorShape = proxy.host.cursorAt(m.x, m.y);
        }
        onExited: if (proxy.host && !pressed)
            replay(() => proxy.host.leave())
        onPressed: m => {
            if (replaying)
                return;
            dragging = false;
            forwarded = Qt.NoButton;
            if (!proxy.host)
                return;
            if (m.button === Qt.LeftButton && proxy.host.isTitleDrag(m.x, m.y)) {
                dragging = true;
                start = mapToItem(proxy.area, m.x, m.y);
                origin = Qt.point(proxy.host.x, proxy.host.y);
                cursorShape = Qt.ClosedHandCursor;
                return;
            }
            if (proxy.host.takes(m.x, m.y, m.button)) {
                forwarded = m.button;
                replay(() => proxy.host.press(m.x, m.y, m.button));
            }
        }
        // save where the widget was dropped and stop following the pointer
        function endDrag() {
            dragging = false;
            cursorShape = Qt.OpenHandCursor;
            const d = DesktopWidgets.drag;
            if (d.uid !== proxy.uid)
                return;
            if (Math.abs(d.x - origin.x) + Math.abs(d.y - origin.y) > 1)
                DesktopWidgets.move(proxy.uid, d.x, d.y);
            // the saved position is already in place, stop following the pointer
            Qt.callLater(() => DesktopWidgets.drag = {
                    "uid": "",
                    "x": 0,
                    "y": 0
                });
        }
        // the grab was taken mid-drag (hot corner, compositor grab): without this
        // the widget hung where it was and jumped back on the next drag
        onCanceled: if (dragging)
            endDrag()
        onReleased: m => {
            if (replaying)
                return;
            if (dragging) {
                endDrag();
                return;
            }
            if (proxy.host && forwarded === m.button) {
                replay(() => proxy.host.release(m.x, m.y, m.button));
                forwarded = Qt.NoButton;
            } else if (proxy.host && m.button === Qt.RightButton) {
                const p = mapToItem(proxy.area, m.x, m.y);
                proxy.contextMenu(p.x, p.y);
            }
        }
        onDoubleClicked: m => {
            if (proxy.host && !replaying)
                replay(() => proxy.host.doubleClick(m.x, m.y, m.button));
        }
        onWheel: w => {
            let taken = false;
            if (proxy.host && !replaying)
                replay(() => taken = proxy.host.wheel(w.x, w.y, w.angleDelta));
            if (!taken)
                w.accepted = false;
        }
    }
}
