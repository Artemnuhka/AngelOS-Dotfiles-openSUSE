pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Frame around one desktop widget: title bar drags it, ✕ (in edit mode) removes it.
Item {
    id: host

    required property string uid
    required property string screenName
    required property Item area
    readonly property var widget: DesktopWidgets.byUid(uid)
    readonly property var info: widget ? DesktopWidgets.typeInfo(widget.type) : null
    readonly property bool wants: !content.item || content.item.wantVisible === undefined || content.item.wantVisible
    property bool dragging: dragArea.drag.active

    function clampX(v) {
        return Math.max(0, Math.min(area.width - width, v));
    }
    function clampY(v) {
        return Math.max(0, Math.min(area.height - height, v));
    }

    visible: !!widget && (wants || DesktopWidgets.editMode)
    opacity: wants ? 1 : 0.45
    width: frame.width
    height: frame.height
    Binding on x {
        when: !host.dragging && !!host.widget
        value: host.clampX(host.widget.x < 0 ? host.area.width + host.widget.x - host.width : host.widget.x)
    }
    Binding on y {
        when: !host.dragging && !!host.widget
        value: host.clampY(host.widget.y < 0 ? host.area.height + host.widget.y - host.height : host.widget.y)
    }

    PxWindow {
        id: frame
        width: Math.max(Theme.u * 70, content.implicitWidth + (inset + bodyPadding) * 2)
        height: titleHeight + content.implicitHeight + bodyPadding * 2 + inset * 2 + Theme.u * 2
        readonly property int inset: Theme.u * 2
        title: host.info ? host.info.title : ""
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

    // drag by the title bar (leaves the ✕ clickable)
    MouseArea {
        id: dragArea
        x: frame.titleBar.x
        y: frame.titleBar.y
        width: frame.titleBar.width - (DesktopWidgets.editMode ? frame.titleHeight : 0)
        height: frame.titleBar.height
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: host
        drag.threshold: 2
        drag.minimumX: 0
        drag.minimumY: 0
        drag.maximumX: host.area.width - host.width
        drag.maximumY: host.area.height - host.height
        property bool moved: false
        onPressed: moved = false
        onPositionChanged: if (pressed && drag.active)
            moved = true
        onReleased: if (moved)
            DesktopWidgets.move(host.uid, host.x, host.y)
        onDoubleClicked: DesktopWidgets.editMode = !DesktopWidgets.editMode
    }
}
