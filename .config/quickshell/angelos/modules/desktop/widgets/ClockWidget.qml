import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Big pixel clock + date. Stands still while nobody can see the desk.
Item {
    id: root

    property string screenName
    property var widget
    readonly property bool passive: true     // nothing to click: no input copy needed
    readonly property bool seconds: widget && widget.settings ? !!widget.settings.seconds : false

    implicitWidth: col.implicitWidth + Theme.u * 8
    implicitHeight: col.implicitHeight

    SystemClock {
        id: clock
        enabled: !Shell.hiddenScreen(root.screenName)
        precision: root.seconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    Column {
        id: col
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.u * 2
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, root.seconds ? "HH:mm:ss" : "HH:mm")
            font.family: Theme.fontTitle
            font.pixelSize: 54 * Theme.fs
            color: Theme.dark ? Theme.text : Theme.edge
            style: Text.Outline
            styleColor: Qt.alpha(Theme.accent, 0.6)
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.u * 3
            PxIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "heart"
            }
            PxText {
                text: Qt.locale(I18n.english ? "en_US" : "ru_RU").toString(clock.date, "dddd, d MMMM")
                kind: "title"
                dim: true
            }
        }
    }
}
