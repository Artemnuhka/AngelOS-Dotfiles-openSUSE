import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.bar
import "."

Item {
    id: root

    property var plugin
    property string screenName
    property var barWindow

    readonly property string limitMode: plugin ? plugin.get("barLimit", "off") : "off"   // five | week | both | off
    visible: !plugin || plugin.get("barAlways", true) || Pulse.state !== "none"
    implicitWidth: visible ? Theme.u * (limitMode === "off" ? 14 : limitMode === "both" ? 50 : 32) : 0
    implicitHeight: Theme.u * 13

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.u * 2
        Breath {
            anchors.verticalCenter: parent.verticalCenter
            plugin: root.plugin
        }
        PxText {
            visible: root.limitMode !== "off"
            width: Theme.u * (root.limitMode === "both" ? 36 : 18)
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
            text: !Usage.ok ? "—" : root.limitMode === "week" ? Usage.weekLeft + "%" : root.limitMode === "both" ? Usage.fiveLeft + "% · " + Usage.weekLeft + "%" : Usage.fiveLeft + "%"
            color: Usage.colorFor(root.limitMode === "week" ? Usage.weekLeft : Math.min(Usage.fiveLeft, root.limitMode === "both" ? Usage.weekLeft : 100), Theme)
            font.bold: true
        }
        PxText {
            visible: root.limitMode !== "off" && (Pulse.state === "needs_attention" || Pulse.state === "error")
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.u * 5
            text: "!"
            kind: "tiny"
            color: Pulse.colorFor(Pulse.state, Theme)
        }
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => {
            panel.tab = m.button === Qt.RightButton ? "sessions" : m.button === Qt.MiddleButton ? "ask" : "limits";
            if (!popup.visible)
                Usage.refresh(true);
            popup.toggle();
        }
    }

    BarPopup {
        id: popup
        panelId: "claude"
        anchorItem: root
        above: BarLayout.bottom
        title: I18n.exe("claude")
        icon: "bot"
        contentWidth: Theme.u * 190
        contentHeight: Theme.u * 205
        PxScroll {
            anchors.fill: parent
            contentHeight: panel.implicitHeight
            Panel {
                id: panel
                width: parent.width
                plugin: root.plugin
            }
        }
    }
}
