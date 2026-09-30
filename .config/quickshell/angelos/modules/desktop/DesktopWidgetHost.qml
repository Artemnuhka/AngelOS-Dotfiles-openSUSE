pragma ComponentBehavior: Bound

import QtQuick
import QtTest
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Frame around one desktop widget, drawn in the wallpaper surface (niri backdrop:
// it stays put while workspaces move and shows once in the overview). That
// surface gets no input: WidgetProxy on the desktop surface drags the title bar
// and replays the pointer here as real Qt mouse events (QtTest's TestEvent sends
// them straight to this window), so buttons, hover and wheel behave as usual.
Item {
    id: host

    required property string uid
    required property string screenName
    required property Item area
    readonly property var widget: DesktopWidgets.byUid(uid)
    readonly property var info: widget ? DesktopWidgets.typeInfo(widget.type) : null
    readonly property bool wants: !content.item || content.item.wantVisible === undefined || content.item.wantVisible
    readonly property bool dragging: DesktopWidgets.drag.uid === uid
    readonly property alias frame: frame
    // 70–130 %: the frame is drawn scaled, the host takes the scaled size, so the
    // proxy, clamping and replayed input all work in scaled coordinates
    readonly property real zoom: DesktopWidgets.scaleOf(widget)

    function clampX(v) {
        return Math.max(0, Math.min(area.width - width, v));
    }
    function clampY(v) {
        return Math.max(0, Math.min(area.height - height, v));
    }

    visible: !!widget && (wants || DesktopWidgets.editMode)
    opacity: wants ? 1 : 0.45
    width: Math.round(frame.width * zoom)
    height: Math.round(frame.height * zoom)
    x: dragging ? DesktopWidgets.drag.x : widget ? clampX(widget.x < 0 ? area.width + widget.x - width : widget.x) : 0
    y: dragging ? DesktopWidgets.drag.y : widget ? clampY(widget.y < 0 ? area.height + widget.y - height : widget.y) : 0

    Component.onCompleted: DesktopWidgets.registerHost(uid, host)
    Component.onDestruction: DesktopWidgets.unregisterHost(uid, host)

    // ---- input forwarding (called by WidgetProxy with host coordinates) ----
    // The deepest visible, enabled item under the point that has `signalName`
    // (a MouseArea's clicked/wheel/doubleClicked, or a widget's own signal).
    function targetAt(px, py, signalName) {
        let item = host, x = px, y = py, found = null;
        while (item) {
            if (item !== host && item.visible && item.enabled !== false && typeof item[signalName] === "function")
                found = {
                    "item": item,
                    "x": x,
                    "y": y
                };
            const child = item.childAt(x, y);
            if (!child)
                break;
            const p = item.mapToItem(child, x, y);
            item = child;
            x = p.x;
            y = p.y;
        }
        return found;
    }
    function inTitle(px, py) {
        const p = host.mapToItem(frame.titleBar, px, py);
        return p.x >= 0 && p.y >= 0 && p.x < frame.titleBar.width && p.y < frame.titleBar.height;
    }
    function isTitleDrag(px, py) {
        // on the title bar, but not on one of its buttons
        const t = targetAt(px, py, "clicked");
        return inTitle(px, py) && (!t || t.item === frame.titleMouse);
    }
    // does anything under the point take this button? (else the desktop menu opens)
    function takes(px, py, button) {
        const t = targetAt(px, py, "clicked");
        return !!t && t.item !== frame.titleMouse && (t.item.acceptedButtons === undefined || !!(t.item.acceptedButtons & button));
    }
    function press(px, py, button) {
        sim.mousePress(host, px, py, button, Qt.NoModifier, -1);
    }
    function release(px, py, button) {
        sim.mouseRelease(host, px, py, button, Qt.NoModifier, -1);
    }
    function move(px, py, buttons) {
        sim.mouseMove(host, px, py, -1, buttons, Qt.NoModifier);
    }
    function leave() {
        // hover leaves every item of the widget
        sim.mouseMove(host, -Theme.u * 4, -Theme.u * 4, -1, Qt.NoButton, Qt.NoModifier);
    }
    function doubleClick(px, py, button) {
        if (button === Qt.LeftButton && isTitleDrag(px, py)) {
            DesktopWidgets.editMode = !DesktopWidgets.editMode;
            return;
        }
        if (targetAt(px, py, "doubleClicked"))
            sim.mouseDoubleClick(host, px, py, button, Qt.NoModifier, -1);
    }
    function wheel(px, py, angleDelta) {
        if (!targetAt(px, py, "wheel"))
            return false;
        sim.mouseWheel(host, px, py, Qt.NoButton, Qt.NoModifier, angleDelta.x, angleDelta.y, -1);
        return true;
    }
    function cursorAt(px, py) {
        if (isTitleDrag(px, py))
            return Qt.OpenHandCursor;
        const t = targetAt(px, py, "clicked");
        return t && t.item.cursorShape !== undefined ? t.item.cursorShape : Qt.ArrowCursor;
    }

    TestEvent {
        id: sim
    }

    PxWindow {
        id: frame
        scale: host.zoom
        transformOrigin: Item.TopLeft
        width: Math.max(Theme.u * 70, content.implicitWidth + (inset + bodyPadding) * 2)
        height: titleHeight + content.implicitHeight + bodyPadding * 2 + inset * 2 + Theme.u * 2
        readonly property int inset: Theme.u * 2
        title: DesktopWidgets.titleOf(host.info)
        icon: host.info ? host.info.icon : "heart"
        compact: true
        decor: false
        closable: DesktopWidgets.editMode
        active: !host.dragging
        onCloseClicked: DesktopWidgets.remove(host.uid)

        Loader {
            id: content
            width: implicitWidth
            height: implicitHeight
            Component.onCompleted: {
                if (!host.widget || !host.info)
                    return;
                const props = {
                    "screenName": host.screenName,
                    "widget": Qt.binding(() => host.widget)
                };
                if (host.info.plugin) {
                    props.plugin = Plugins.context(host.info.plugin);
                    setSource(Plugins.url(host.info.plugin, host.info.plugin.desktopWidget), props);
                } else {
                    const name = host.info.type.charAt(0).toUpperCase() + host.info.type.slice(1);
                    setSource(Qt.resolvedUrl("widgets/" + ({
                            "Nowplaying": "NowPlaying"
                        }[name] || name) + "Widget.qml"), props);
                }
            }
        }
    }
}
