import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Left / center / right sections from BarLayout. `inline` packs everything in one row (island).
Item {
    id: root

    required property string screenName
    required property var barWindow
    required property string style        // taskbar | top | island
    property bool compact: false
    property bool inline: false
    property int itemHeight: Theme.u * 15
    readonly property bool above: style === "taskbar"
    readonly property var layout: BarLayout.effective
    readonly property bool lyricsShown: BarLayout.has("lyrics") && Config.lyrics.enabled && Lyrics.visibleToggle && Lyrics.hasLyrics && (!Config.lyrics.screens.length || Config.lyrics.screens.includes(screenName))
    readonly property int gap: Theme.u * 4

    Component.onCompleted: Shell.barViews[screenName] = root
    Component.onDestruction: {
        if (Shell.barViews[screenName] === root)
            delete Shell.barViews[screenName];
    }
    function diagnostics() {
        return {
            width: width,
            lyricsShown: lyricsShown,
            leftWidth: left.width,
            leftImplicit: left.implicitWidth,
            rightX: right.x,
            rightWidth: right.width,
            centerX: center.x,
            centerWidth: center.width,
            centerImplicit: center.implicitWidth,
            leftNeed: center.leftNeed,
            lyricsMax: center.lyricsMax
        };
    }
    implicitWidth: inline ? inlineRow.implicitWidth : 0
    implicitHeight: itemHeight

    // Behind the widgets: right-clicks on task buttons keep their own action.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: mouse => panelMenu.openAt(mouse.x, mouse.y)
    }
    PanelMenu {
        id: panelMenu
        anchorItem: root
        above: root.above
    }
    // Over the widgets: any press on the bar closes the open popup first (the
    // grab of an xdg popup does not end on clicks inside the same client), then
    // lets the press through to whatever is underneath.
    MouseArea {
        anchors.fill: parent
        z: 100
        acceptedButtons: Qt.AllButtons
        onPressed: mouse => {
            PopupManager.barPressed();
            mouse.accepted = false;
        }
    }

    // ---- inline (island) ----
    Row {
        id: inlineRow
        visible: root.inline
        anchors.centerIn: parent
        spacing: Theme.u * 5
        BarSection {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.layout.left.length > 0
            ids: root.inline ? root.layout.left : []
            bar: root
            lyricsMax: root.compact ? Theme.u * 110 : Theme.u * 200
        }
        BarSection {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.layout.center.length > 0
            ids: root.inline ? root.layout.center : []
            bar: root
            lyricsMax: root.compact ? Theme.u * 110 : Theme.u * 200
        }
        BarSection {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.layout.right.length > 0
            ids: root.inline ? root.layout.right : []
            bar: root
            lyricsMax: root.compact ? Theme.u * 110 : Theme.u * 200
            density: Config.bar.rightDensity || "normal"
        }
    }

    // ---- full width (taskbar / top) ----
    Item {
        anchors.fill: parent
        visible: !root.inline

        readonly property bool tasksLeft: root.layout.left.includes("tasks")
        readonly property real mid: width / 2
        // Settings → Bar → Start → "Taskbar": like Windows 11, Start with the window buttons in
        // the middle (they slide there and back); the lyrics then take the room on the left
        readonly property bool centered: Config.bar.taskbarAlign === "center"

        // sunken Win98 notification area behind the right side of the taskbar
        PxBox {
            visible: root.style === "taskbar" && right.implicitWidth > 0
            x: right.x - Theme.u * 4
            width: right.width + Theme.u * 6
            height: root.itemHeight
            anchors.verticalCenter: parent.verticalCenter
            sunken: true
            outline: false
            color: Qt.alpha(Theme.sunken, 0.35)
        }

        BarSection {
            id: right
            anchors.right: parent.right
            anchors.rightMargin: Theme.u * 2
            anchors.verticalCenter: parent.verticalCenter
            ids: root.inline ? [] : root.layout.right
            bar: root
            lyricsMax: Theme.u * 150
            density: Config.bar.rightDensity || "normal"
        }

        BarSection {
            id: center
            anchors.verticalCenter: parent.verticalCenter
            x: parent.centered ? Theme.u * 2 : Math.round(Math.max(leftNeed, Math.min(parent.mid - width / 2, right.x - root.gap - width)))
            ids: root.inline ? [] : root.layout.center
            bar: root
            // widest centred run that still leaves room for the left side (+ a few task buttons) and the right side
            readonly property real leftNeed: Theme.u * 2 + left.implicitWidth + (parent.tasksLeft ? (root.compact ? Theme.u * 4 : Theme.u * 44) : 0) + root.gap
            // the lyrics box takes the song's longest line, up to all the room between the sides
            // (centred taskbar: the room left of the centred group)
            lyricsMax: parent.centered ? Math.max(0, left.x - root.gap - Theme.u * 2 - (root.layout.center.length > 1 ? Theme.u * 60 : 0)) : Math.max(0, Math.min(parent.width * 0.6, right.x - root.gap - leftNeed - (root.layout.center.length > 1 ? Theme.u * 60 : 0)))
        }

        BarSection {
            id: left
            anchors.verticalCenter: parent.verticalCenter
            // left: from the edge to the lyrics; centred: as wide as it needs, in the middle
            readonly property real room: right.x - root.gap - Theme.u * 2
            readonly property real centeredX: Math.round(Math.max(Theme.u * 2, Math.min((parent.width - width) / 2, right.x - root.gap - width)))
            x: parent.centered ? centeredX : Theme.u * 2
            width: parent.centered ? Math.min(implicitWidth, room) : Math.max(implicitWidth, (center.implicitWidth > 0 && center.visible ? center.x : right.x - Theme.u * 6) - root.gap - x)
            ids: root.inline ? [] : root.layout.left
            bar: root
            fillTasks: !parent.centered
            centered: parent.centered
            lyricsMax: Theme.u * 150
            // the Windows 11 slide when the alignment changes or a window button comes and goes
            Behavior on x {
                NumberAnimation {
                    duration: 320
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
