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
        above: BarLayout.bottom
        title: I18n.exe(Angel.demon ? I18n.t("цербер", "cerberus") : I18n.t("котик", "cat"))
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
                readonly property int pace: Cpu.percent < (root.plugin ? root.plugin.get("walk", 15) : 15) ? 0 : Cpu.percent < (root.plugin ? root.plugin.get("run", 60) : 60) ? 1 : 2
                text: Angel.demon ? [I18n.t("дремлет… zzz ×3", "Dozing… zzz ×3"), I18n.t("рыщет по процессам", "Prowling the processes"), I18n.t("ГОНИТСЯ ЗА ДУШАМИ!!", "CHASING SOULS!!")][pace] : [I18n.t("спит… zzz", "Sleeping… zzz"), I18n.t("гуляет ♡", "Walking ♡"), I18n.t("БЕЖИТ!!", "RUNNING!!")][pace]
            }
        }
    }
}
