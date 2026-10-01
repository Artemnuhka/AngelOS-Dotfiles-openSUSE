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

    // stands still under a fullscreen game or the lock screen
    SystemClock {
        id: clock
        enabled: !Shell.hiddenScreen(root.screenName)
        precision: Config.bar.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    Column {
        id: col
        anchors.centerIn: parent
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: I18n.time(clock.date, Config.bar.showSeconds)
            kind: root.showDate ? "body" : "title"
        }
        PxText {
            visible: root.showDate
            anchors.horizontalCenter: parent.horizontalCenter
            text: I18n.locale.toString(clock.date, I18n.english ? "ddd, MMM d" : "ddd d MMM")
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
