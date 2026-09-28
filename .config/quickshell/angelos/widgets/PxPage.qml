import QtQuick
import qs.config
import qs.widgets

// Scrollable settings page: a column of PxGroups.
PxScroll {
    id: root

    property string heading: ""
    property string subtitle: ""
    default property alias items: col.data
    readonly property int innerWidth: col.width

    contentHeight: col.implicitHeight + Theme.u * 10

    Column {
        id: col
        x: Theme.u * 4
        y: Theme.u * 4
        width: parent.width - Theme.u * 8
        spacing: Theme.u * 8

        Column {
            visible: root.heading !== ""
            width: parent.width
            spacing: Theme.u
            PxText {
                text: root.heading
                kind: "big"
                color: Theme.dark ? Theme.accent : Theme.edge
            }
            PxText {
                visible: root.subtitle !== ""
                width: parent.width
                text: root.subtitle
                dim: true
                wrapMode: Text.Wrap
            }
        }
    }
}
