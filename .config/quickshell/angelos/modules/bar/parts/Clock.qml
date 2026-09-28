import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets
import qs.modules.bar

Item {
    id: root

    required property string screenName
    property bool above: true
    property bool showDate: true

    implicitWidth: col.implicitWidth + Theme.u * 8
    implicitHeight: col.implicitHeight

    SystemClock {
        id: clock
        precision: Config.bar.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    Column {
        id: col
        anchors.centerIn: parent
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, Config.bar.showSeconds ? "HH:mm:ss" : "HH:mm")
            kind: root.showDate ? "body" : "title"
        }
        PxText {
            visible: root.showDate
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.locale("ru_RU").toString(clock.date, "ddd d MMM")
            kind: "tiny"
            dim: true
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: panel.toggle()
    }

    CalendarPanel {
        id: panel
        anchorItem: root
        above: root.above
    }
}
