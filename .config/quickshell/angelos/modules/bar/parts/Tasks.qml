pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// Win98 task buttons for windows on this screen's active workspace (or all).
Item {
    id: root

    required property string screenName
    property bool iconsOnly: false
    readonly property var ws: Niri.activeWorkspace(screenName)
    readonly property var list: Niri.sortedWindows(Config.bar.allWindows ? Niri.windows : Niri.windows.filter(w => ws && w.workspace_id === ws.id))
    readonly property int minW: Theme.u * Math.max(16, Config.bar.taskMinWidth)
    readonly property int maxW: Theme.u * Math.max(Config.bar.taskMinWidth, Config.bar.taskMaxWidth)
    readonly property int buttonWidth: iconsOnly ? root.height : Math.max(minW, Math.min(maxW, (width - (list.length - 1) * row.spacing) / Math.max(1, list.length)))

    clip: true

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.u * 2

        Repeater {
            model: root.list
            PxButton {
                id: btn
                required property var modelData
                width: root.buttonWidth
                height: root.height
                checked: modelData.is_focused
                onClicked: Niri.focusWindow(modelData.id)
                onRightClicked: Niri.closeWindow(modelData.id)

                AppIcon {
                    id: ico
                    x: (root.iconsOnly ? (btn.width - width) / 2 : Theme.u * 4) + (btn.down ? Theme.u : 0)
                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                    anchors.verticalCenterOffset: btn.down ? Theme.u : 0
                    appId: btn.modelData.app_id || ""
                    size: root.iconsOnly ? Math.max(Theme.u * 8, btn.height - Theme.u * 6) : Theme.u * 8
                    tint: Config.bar.tintTasks && !btn.modelData.is_focused ? Config.bar.trayTint : "off"
                }
                PxText {
                    visible: !root.iconsOnly
                    anchors.left: ico.right
                    anchors.leftMargin: Theme.u * 3
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.u * 4
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: btn.down ? Theme.u : 0
                    text: btn.modelData.title || btn.modelData.app_id || "?"
                    elide: Text.ElideRight
                    font.bold: btn.modelData.is_focused
                    color: btn.modelData.is_urgent ? Theme.danger : Theme.text
                }
            }
        }
    }
}
