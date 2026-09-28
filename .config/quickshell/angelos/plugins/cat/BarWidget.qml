import QtQuick
import qs.config
import qs.widgets
import qs.modules.bar
import "."

Item {
    id: root

    property var plugin
    property string screenName
    property var barWindow
    readonly property bool showPercent: plugin ? plugin.get("showPercent", false) : false

    Component.onCompleted: if (plugin)
        Cpu.intervalMs = plugin.get("poll", 2) * 1000
    implicitWidth: row.implicitWidth + Theme.u * 4
    implicitHeight: Theme.u * 13

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.u * 2
        CatSprite {
            anchors.verticalCenter: parent.verticalCenter
            plugin: root.plugin
            pixel: Math.max(1, Math.round(Theme.u * (root.plugin ? root.plugin.get("size", 1) : 1)))
        }
        PxText {
            visible: root.showPercent
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(Cpu.percent) + "%"
            kind: "tiny"
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.toggle()
    }

    BarPopup {
        id: popup
        panelId: "cat"
        anchorItem: root
        above: Config.bar.style === "taskbar"
        title: I18n.t("котик.exe", "cat.exe")
        icon: "heart"
        contentWidth: Theme.u * 120
        contentHeight: Theme.u * 70

        Column {
            anchors.centerIn: parent
            spacing: Theme.u * 4
            CatSprite {
                anchors.horizontalCenter: parent.horizontalCenter
                plugin: root.plugin
                pixel: Theme.u * 4
            }
            PxText {
                anchors.horizontalCenter: parent.horizontalCenter
                kind: "title"
                text: "CPU " + Math.round(Cpu.percent) + "%"
            }
            PxText {
                anchors.horizontalCenter: parent.horizontalCenter
                dim: true
                text: Cpu.percent < (root.plugin ? root.plugin.get("walk", 15) : 15) ? I18n.t("спит… zzz", "Sleeping… zzz") : Cpu.percent < (root.plugin ? root.plugin.get("run", 60) : 60) ? I18n.t("гуляет ♡", "Walking ♡") : I18n.t("БЕЖИТ!!", "RUNNING!!")
            }
        }
    }
}
