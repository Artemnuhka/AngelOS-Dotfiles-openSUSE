import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Big pixel clock + date. Stands still while nobody can see the desk.
// In hell (Theme.realm): Roman numerals in blackletter over a pentagram, and
// between three and four in the night the date gives way to "hora diaboli".
Item {
    id: root

    property string screenName
    property var widget
    readonly property bool passive: true     // nothing to click: no input copy needed
    readonly property bool seconds: widget && widget.settings ? !!widget.settings.seconds : false

    implicitWidth: (Theme.hell ? hellCol.implicitWidth : col.implicitWidth) + Theme.u * 8
    implicitHeight: Theme.hell ? hellCol.implicitHeight : col.implicitHeight

    SystemClock {
        id: clock
        enabled: !Shell.hiddenScreen(root.screenName)
        precision: root.seconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    Column {
        id: col
        visible: !Theme.hell
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.u * 2
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: I18n.time(clock.date, root.seconds)
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

    Column {
        id: hellCol
        visible: Theme.hell
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.u
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Theme.roman(clock.hours) + " : " + Theme.roman(clock.minutes) + (root.seconds ? " : " + Theme.roman(clock.seconds) : "")
            font.family: Theme.fontHell
            font.pixelSize: Theme.hellPx(2 * Theme.fs)
            color: Theme.hellFlame
            style: Text.Outline
            styleColor: Theme.hellBlood
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.u * 3
            PxIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "pentagram"
                ink: Theme.hellGold
                fill: Theme.hellBlood
            }
            PxText {
                readonly property bool witching: clock.hours === 3
                // "d MMMM" keeps the month's genitive in Russian; the day becomes Roman
                text: witching ? "hora diaboli" : Qt.locale(I18n.english ? "en_US" : "ru_RU").toString(clock.date, "dddd, d MMMM").replace(/\d+/, Theme.roman(clock.date.getDate()))
                kind: "title"
                font.family: Theme.latin(text) ? Theme.fontHell : Theme.fontTitle
                font.pixelSize: Theme.latin(text) ? Theme.hellPx(Theme.fs) : Theme.sizeTitle
                color: witching ? Theme.hellEmber : Theme.hellTextDim
            }
            PxIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "pentagram"
                ink: Theme.hellGold
                fill: Theme.hellBlood
            }
        }
    }
}
