pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// Win98 task buttons for windows on this screen's active workspace (or all).
// Titles show while every button still gets a readable width; when the windows
// reach the lyrics or other widgets the row turns into icons, and when even the
// icons don't fit it scrolls (mouse wheel, arrows at the edges).
Item {
    id: root

    required property string screenName
    property bool iconsOnly: false         // compact / island bars, or titles switched off
    property bool above: true              // the window menu opens above a bottom bar
    readonly property var ws: Niri.activeWorkspace(screenName)
    readonly property var list: Niri.sortedWindows(Config.bar.allWindows ? Niri.windows : Niri.windows.filter(w => ws && w.workspace_id === ws.id))
    readonly property int count: list.length
    readonly property int spacing: Theme.u * 2
    readonly property int iconWidth: height
    // a title button narrower than this shows two letters and an ellipsis — use icons instead
    readonly property int labelMin: Theme.u * Math.max(28, Config.bar.taskMinWidth)
    readonly property int maxW: Theme.u * Math.max(28, Config.bar.taskMinWidth, Config.bar.taskMaxWidth)
    readonly property real share: count ? (width - (count - 1) * spacing) / count : 0
    readonly property bool labels: !iconsOnly && share >= labelMin
    readonly property int buttonWidth: labels ? Math.min(maxW, Math.floor(share)) : iconWidth
    readonly property real rowWidth: count * buttonWidth + Math.max(0, count - 1) * spacing
    readonly property bool overflow: rowWidth > width + 0.5

    clip: true

    function scrollBy(dx) {
        const max = Math.max(0, flick.contentWidth - flick.width);
        glide.stop();
        glide.to = Math.max(0, Math.min(max, flick.contentX + dx));
        glide.start();
    }
    // keep the focused window's button in view when the row scrolls
    function reveal() {
        if (!overflow)
            return;
        const i = list.findIndex(w => w.is_focused);
        if (i < 0)
            return;
        const x0 = i * (buttonWidth + spacing), x1 = x0 + buttonWidth;
        if (x0 < flick.contentX)
            scrollBy(x0 - flick.contentX - Theme.u * 8);
        else if (x1 > flick.contentX + flick.width)
            scrollBy(x1 - flick.contentX - flick.width + Theme.u * 8);
    }
    onListChanged: Qt.callLater(reveal)
    onOverflowChanged: if (!overflow)
        flick.contentX = 0

    NumberAnimation {
        id: glide
        target: flick
        property: "contentX"
        duration: 140
        easing.type: Easing.OutCubic
    }

    WindowMenu {
        id: menu
        anchorItem: root
        above: root.above
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: root.rowWidth
        contentHeight: height
        interactive: root.overflow
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        pixelAligned: true

        Row {
            id: row
            height: flick.height
            spacing: root.spacing

            Repeater {
                model: root.list
                PxButton {
                    id: btn
                    required property var modelData
                    width: root.buttonWidth
                    height: row.height
                    checked: modelData.is_focused
                    middleButton: true
                    onClicked: Niri.focusWindow(modelData.id)
                    onMiddleClicked: if (Config.bar.taskMiddleClose)
                        Niri.closeWindow(modelData.id)
                    onRightClicked: {
                        const mode = Config.bar.taskRightClick || "menu";
                        if (mode === "close")
                            Niri.closeWindow(modelData.id);
                        else if (mode === "menu")
                            menu.openFor(btn, modelData);
                    }

                    AppIcon {
                        id: ico
                        x: (root.labels ? Theme.u * 4 : (btn.width - width) / 2) + (btn.down ? Theme.u : 0)
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        anchors.verticalCenterOffset: btn.down ? Theme.u : 0
                        appId: btn.modelData.app_id || ""
                        size: root.labels ? Theme.u * 8 : Math.max(Theme.u * 8, btn.height - Theme.u * 6)
                        tint: Config.bar.tintTasks && !btn.modelData.is_focused ? Config.bar.trayTint : "off"
                    }
                    PxText {
                        visible: root.labels
                        anchors.left: ico.right
                        anchors.leftMargin: Theme.u * 3
                        anchors.right: parent.right
                        anchors.rightMargin: closeX.visible ? closeX.width + Theme.u * 4 : Theme.u * 4
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: btn.down ? Theme.u : 0
                        text: btn.modelData.title || btn.modelData.app_id || "?"
                        elide: Text.ElideRight
                        font.bold: btn.modelData.is_focused
                        color: btn.modelData.is_urgent ? Theme.danger : Theme.text
                    }
                    // × on hover (Settings → Bar → Closing windows)
                    Rectangle {
                        id: closeX
                        visible: Config.bar.taskHoverClose && btn.hovered
                        readonly property int s: root.labels ? Theme.u * 9 : Theme.u * 7
                        width: s
                        height: s
                        x: btn.width - width - Theme.u * 2
                        y: root.labels ? (btn.height - height) / 2 : Theme.u * 2
                        color: xm.containsMouse ? Theme.danger : Qt.alpha(Theme.face, 0.85)
                        border.width: Math.max(1, Theme.u / 2)
                        border.color: Theme.edge
                        PxIcon {
                            anchors.centerIn: parent
                            name: "close"
                            pixel: Math.max(1, Theme.u - 1)
                            ink: xm.containsMouse ? "#ffffff" : Theme.text
                        }
                        MouseArea {
                            id: xm
                            anchors.fill: parent
                            anchors.margins: -Theme.u
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Niri.closeWindow(btn.modelData.id)
                        }
                    }
                }
            }
        }
    }

    // wheel scrolls the row sideways once it overflows
    WheelHandler {
        enabled: root.overflow
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: e => {
            const d = e.pixelDelta.x !== 0 ? -e.pixelDelta.x : e.pixelDelta.y !== 0 ? -e.pixelDelta.y : -(e.angleDelta.y || e.angleDelta.x) / 120 * (root.buttonWidth + root.spacing);
            root.scrollBy(d);
        }
    }

    // edge arrows while there is more to see on that side
    Repeater {
        model: [-1, 1]
        PxButton {
            required property int modelData
            visible: root.overflow && (modelData < 0 ? flick.contentX > 1 : flick.contentX < flick.contentWidth - flick.width - 1)
            compact: true
            icon: modelData < 0 ? "arrowLeft" : "arrowRight"
            iconPixel: Math.max(1, Theme.u - 1)
            width: Theme.u * 8
            height: root.height
            x: modelData < 0 ? 0 : root.width - width
            onClicked: root.scrollBy(modelData * Math.max(root.buttonWidth + root.spacing, flick.width * 0.6))
        }
    }
}
