pragma ComponentBehavior: Bound

import QtQuick
import QtTest
import Quickshell
import qs.config
import qs.services
import qs.widgets

// One desktop widget in its frame. Every widget lives twice (Background):
//   face   in the backdrop (angelos-wallpaper): what you see. niri never slides
//          the backdrop, so the widget stays put while workspaces switch —
//          however the switch starts — and shows in the overview. No input there.
//   input  on angelos-desktop, which niri draws inside every workspace: the
//          same widget at opacity 0 that takes the pointer (Qt delivers input to
//          invisible items). It shows itself only where it has something the
//          face can't: hover and presses on buttons (NowPlaying) — while hovered,
//          dragged or in edit mode — and steps aside while workspaces slide.
//          Widgets with nothing to click (clock, sysmon, cava, the companions'
//          orbs) keep their input copy empty: one set of timers and processes.
// Dragged by the title bar, double click on the title toggles edit mode, Ctrl +
// wheel (or the wheel in edit mode) resizes it, a right click on a bare spot
// opens the desktop menu.
Item {
    id: host

    required property string uid
    required property string screenName
    required property Item area
    property string role: "input"            // input | face
    readonly property bool face: role === "face"
    readonly property var body: content.item
    // the content has something to click or hover (a button): see scanInput()
    property bool interactive: false
    readonly property var widget: DesktopWidgets.byUid(uid)
    readonly property var info: widget ? DesktopWidgets.typeInfo(widget.type) : null
    readonly property bool wants: !content.item || content.item.wantVisible === undefined || content.item.wantVisible
    readonly property bool dragging: DesktopWidgets.drag.uid === uid
    readonly property alias frame: frame
    // 70–130 %: the frame is drawn scaled, the host takes the scaled size
    readonly property real zoom: DesktopWidgets.scaleOf(widget)
    signal contextMenu(real x, real y)

    function clampX(v) {
        return Math.max(0, Math.min(area.width - width, v));
    }
    function clampY(v) {
        return Math.max(0, Math.min(area.height - height, v));
    }

    visible: !!widget && (wants || DesktopWidgets.editMode)
    readonly property real baseOpacity: wants ? 1 : 0.45

    // ---- which copy shows ----
    // input: over the face while it matters (hover, a drag, edit mode), and a
    // moment longer so the face (a later frame on another surface) is back first
    readonly property bool engaged: interactive && (hover.hovered || dragging || DesktopWidgets.editMode)
    property bool lingering: false
    onEngagedChanged: if (!engaged && !face) {
        lingering = true;
        linger.restart();
    }
    Timer {
        id: linger
        interval: 160
        onTriggered: host.lingering = false
    }
    readonly property bool shown: !face && (engaged || lingering) && !DesktopWidgets.steppedAside(screenName)
    // face: always, except while its input copy is dragged around on top of it
    readonly property var twin: face ? DesktopWidgets.hosts[uid] || null : null
    opacity: face ? (twin && twin.interactive && twin.dragging ? 0 : baseOpacity) : (shown ? baseOpacity : 0)
    width: Math.round(frame.width * zoom)
    height: Math.round(frame.height * zoom)
    x: dragging ? DesktopWidgets.drag.x : widget ? clampX(widget.x < 0 ? area.width + widget.x - width : widget.x) : 0
    y: dragging ? DesktopWidgets.drag.y : widget ? clampY(widget.y < 0 ? area.height + widget.y - height : widget.y) : 0

    Component.onCompleted: face ? DesktopWidgets.registerFace(uid, host) : DesktopWidgets.registerHost(uid, host)
    Component.onDestruction: face ? DesktopWidgets.unregisterFace(uid, host) : DesktopWidgets.unregisterHost(uid, host)

    HoverHandler {
        id: hover
        enabled: !host.face
    }

    // under the widget: right click on a bare spot → the desktop menu; the wheel
    // resizes in edit mode or with Ctrl
    MouseArea {
        anchors.fill: parent
        enabled: !host.face
        z: -1
        acceptedButtons: Qt.RightButton
        onClicked: m => {
            const p = mapToItem(host.area, m.x, m.y);
            host.contextMenu(p.x, p.y);
        }
        onWheel: w => {
            if (DesktopWidgets.editMode || (w.modifiers & Qt.ControlModifier)) {
                const notch = (w.angleDelta.y || w.angleDelta.x) / 120;
                if (notch)
                    DesktopWidgets.setScale(host.uid, host.zoom + notch * 0.05);
            } else {
                w.accepted = false;
            }
        }
    }

    // ---- dragging by the title bar (PxWindow's own title MouseArea) ----
    property point dragStart
    property point dragOrigin
    function endDrag() {
        const d = DesktopWidgets.drag;
        if (d.uid !== uid)
            return;
        if (Math.abs(d.x - dragOrigin.x) + Math.abs(d.y - dragOrigin.y) > 1)
            DesktopWidgets.move(uid, d.x, d.y);
        // the saved position is already in place, stop following the pointer
        Qt.callLater(() => DesktopWidgets.drag = {
                "uid": "",
                "x": 0,
                "y": 0
            });
    }
    Connections {
        target: frame.titleMouse
        enabled: !host.face
        function onPressed(m) {
            host.dragStart = frame.titleMouse.mapToItem(host.area, m.x, m.y);
            host.dragOrigin = Qt.point(host.x, host.y);
            DesktopWidgets.drag = {
                "uid": host.uid,
                "x": host.x,
                "y": host.y
            };
        }
        function onPositionChanged(m) {
            if (!host.dragging)
                return;
            const p = frame.titleMouse.mapToItem(host.area, m.x, m.y);
            DesktopWidgets.drag = {
                "uid": host.uid,
                "x": host.clampX(host.dragOrigin.x + p.x - host.dragStart.x),
                "y": host.clampY(host.dragOrigin.y + p.y - host.dragStart.y)
            };
        }
        function onReleased() {
            host.endDrag();
        }
        // the grab was taken mid-drag (hot corner, a compositor grab)
        function onCanceled() {
            host.endDrag();
        }
        function onDoubleClicked() {
            DesktopWidgets.editMode = !DesktopWidgets.editMode;
        }
    }
    Binding {
        target: frame.titleMouse
        property: "cursorShape"
        value: host.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
    }

    // Anything clickable in the content? Buttons (PxButton), MouseAreas and tap
    // handlers all have a `clicked` or `tapped` signal. A content item may say
    // so itself: `readonly property bool passive: true`.
    function scanInput(item, depth) {
        if (!item || depth > 12)
            return false;
        if (typeof item.clicked === "function" || typeof item.tapped === "function")
            return true;
        for (const c of item.children || [])
            if (scanInput(c, depth + 1))
                return true;
        return false;
    }
    function checkInput() {
        const it = content.item;
        interactive = !!it && (it.passive === undefined ? scanInput(it, 0) : !it.passive);
    }

    // ---- scripted input for `angelos widgetClick/widgetProbe` (tests) ----
    // The deepest visible, enabled item under the point that has `signalName`.
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
    function isTitleDrag(px, py) {
        const p = host.mapToItem(frame.titleBar, px, py);
        const t = targetAt(px, py, "clicked");
        return p.x >= 0 && p.y >= 0 && p.x < frame.titleBar.width && p.y < frame.titleBar.height && (!t || t.item === frame.titleMouse);
    }
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
            // the input copy of a widget with nothing to click runs nothing: the face shows it
            visible: host.face || host.interactive
            onLoaded: host.checkInput()
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
