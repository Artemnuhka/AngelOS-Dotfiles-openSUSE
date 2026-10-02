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

    readonly property string mode: plugin ? plugin.get("barLimit", "auto") : "auto"   // auto | five | week | today | off
    readonly property string label: {
        if (mode === "off" || CodexState.status !== "ok")
            return "";
        if (mode === "today" || (mode === "auto" && !CodexState.hasLimits))
            return CodexState.tokens(CodexState.today.total_tokens);
        if (mode === "week")
            return CodexState.weekLeft >= 0 ? CodexState.weekLeft + "%" : "—";
        return CodexState.fiveLeft >= 0 ? CodexState.fiveLeft + "%" : (CodexState.weekLeft >= 0 ? CodexState.weekLeft + "%" : "—");
    }
    visible: !plugin || plugin.get("barAlways", true) || CodexState.state !== "none"
    implicitWidth: visible ? row.implicitWidth + Theme.u * 4 : 0
    implicitHeight: Theme.u * 13

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.u * 2
        Mascot {
            anchors.verticalCenter: parent.verticalCenter
        }
        PxText {
            visible: root.label !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: CodexState.hasLimits && root.mode !== "today" ? CodexState.colorFor(root.mode === "week" ? CodexState.weekLeft : CodexState.fiveLeft, Theme) : Theme.text
            font.bold: true
        }
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: m => {
            panel.tab = m.button === Qt.RightButton ? "sessions" : m.button === Qt.MiddleButton ? "ask" : "limits";
            if (!popup.visible)
                CodexState.refresh();
            popup.toggle();
        }
    }

    BarPopup {
        id: popup
        panelId: "codex"
        anchorItem: root
        above: BarLayout.bottom
        title: "codex.exe"
        icon: "terminal"
        contentWidth: Theme.u * 190
        contentHeight: Theme.u * 190
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
