pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// Hearts: filled = active, lavender = has windows, hollow = empty.
Item {
    id: root

    required property string screenName
    readonly property var list: Niri.workspacesOn(screenName).filter(w => w.name !== "privacy")

    // the badge only takes room while it is shown: the slot opens, then closes again
    readonly property real badgeWidth: Math.min(Theme.u * 64, badgeMetrics.advanceWidth("✧ " + flashText) + Theme.u * 10)
    property real slot: 0
    implicitWidth: row.implicitWidth + slot
    implicitHeight: row.implicitHeight
    property int bounceToken: 0
    property int bounceWorkspace: -1
    FontMetrics {
        id: badgeMetrics
        font: badgeText.font
    }

    Row {
        id: row
        spacing: Theme.u * 2

        Repeater {
            model: root.list
            Item {
                id: cell
                required property var modelData
                readonly property bool active: modelData.is_active
                readonly property var wins: Niri.sortedWindows(Niri.windowsOn(modelData.id))
                readonly property bool occupied: wins.length > 0
                readonly property string style: Config.bar.workspaceStyle
                readonly property bool showIcons: style !== "hearts" && occupied
                readonly property bool showHeart: style !== "icons" || !occupied
                readonly property var icons: wins.slice(0, Math.max(1, Config.bar.workspaceIcons))
                width: (showHeart ? heart.width : 0) + (showIcons ? iconRow.width + (showHeart ? Theme.u * 2 : 0) : 0) + Theme.u * 4
                height: Math.max(heart.height, Theme.u * 9) + Theme.u * 4

                // active workspace gets a soft plate when icons are shown
                Rectangle {
                    visible: cell.showIcons
                    anchors.fill: parent
                    anchors.topMargin: Theme.u
                    anchors.bottomMargin: Theme.u
                    color: cell.active ? Qt.alpha(Theme.accent, 0.28) : mouse.containsMouse ? Qt.alpha(Theme.accent, 0.12) : "transparent"
                    border.width: cell.active ? Math.max(1, Theme.u / 2) : 0
                    border.color: Theme.accent
                }
                Row {
                    id: iconRow
                    visible: cell.showIcons
                    anchors.verticalCenter: parent.verticalCenter
                    x: (cell.showHeart ? heart.x + heart.width + Theme.u * 2 : Theme.u * 2)
                    spacing: Theme.u
                    Repeater {
                        model: cell.showIcons ? cell.icons : []
                        AppIcon {
                            required property var modelData
                            appId: modelData.app_id || ""
                            size: Theme.u * 8
                            opacity: cell.active ? 1 : 0.7
                            tint: Config.bar.tintTasks && !cell.active ? Config.bar.trayTint : "off"
                        }
                    }
                    PxText {
                        visible: cell.wins.length > cell.icons.length
                        anchors.verticalCenter: parent.verticalCenter
                        text: "+" + (cell.wins.length - cell.icons.length)
                        kind: "tiny"
                        dim: true
                    }
                }

                PxIcon {
                    id: heart
                    visible: cell.showHeart
                    x: Theme.u * 2
                    anchors.verticalCenter: parent.verticalCenter
                    name: "heart"
                    pixel: Theme.u
                    hollow: !cell.active && !cell.occupied
                    fill: cell.modelData.is_urgent ? Theme.danger : cell.active ? Theme.accent : Theme.accent4
                    opacity: cell.active || mouse.containsMouse ? 1 : 0.75
                    property real bounceScale: 1
                    scale: (cell.active ? 1.0 : 0.8) * bounceScale
                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.fast
                            easing.type: Easing.OutBack
                        }
                    }
                    SequentialAnimation {
                        id: bounce
                        NumberAnimation {
                            target: heart
                            property: "anchors.verticalCenterOffset"
                            from: 0
                            to: -Theme.u * 3
                            duration: 110
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: heart
                            property: "anchors.verticalCenterOffset"
                            to: 0
                            duration: 180
                            easing.type: Easing.OutBounce
                        }
                        NumberAnimation {
                            target: heart
                            property: "bounceScale"
                            to: 1.24
                            duration: 110
                            easing.type: Easing.OutBack
                        }
                        NumberAnimation {
                            target: heart
                            property: "bounceScale"
                            to: 0.88
                            duration: 100
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            target: heart
                            property: "bounceScale"
                            to: 1
                            duration: 160
                            easing.type: Easing.OutBack
                        }
                        onStopped: heart.bounceScale = 1
                    }
                    Connections {
                        target: root
                        function onBounceTokenChanged() {
                            if (cell.modelData.id === root.bounceWorkspace)
                                bounce.restart();
                        }
                    }
                    SequentialAnimation on opacity {
                        running: cell.modelData.is_urgent
                        loops: Animation.Infinite
                        PropertyAction {
                            value: 1
                        }
                        PauseAnimation {
                            duration: 300
                        }
                        PropertyAction {
                            value: 0.3
                        }
                        PauseAnimation {
                            duration: 300
                        }
                    }
                }
                PxText {
                    visible: !!cell.modelData.name
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: heart.bottom
                    text: cell.modelData.name || ""
                    kind: "tiny"
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Niri.focusWorkspace(cell.modelData.id)
                }
            }
        }
    }

    // "bar" popup mode: the workspace name pops out next to the hearts, on top of the bar
    property string flashText: ""
    Connections {
        target: Niri
        function onWorkspaceActivated(ws, focused) {
            if (ws.output !== root.screenName || ws.name === "privacy")
                return;
            root.bounceWorkspace = ws.id;
            root.bounceToken++;
            if (Config.workspaces.popupMode !== "bar")
                return;
            const names = Config.workspaces.names || {};
            root.flashText = names[ws.output + ":" + ws.idx] || ws.name || String(ws.idx);
            flash.restart();
        }
    }
    PxBox {
        id: badge
        z: 10
        visible: opacity > 0
        opacity: 0
        x: row.width + Theme.u * 3
        anchors.verticalCenter: parent.verticalCenter
        width: root.badgeWidth
        height: Theme.u * 11
        color: Theme.accent
        PxText {
            id: badgeText
            anchors.centerIn: parent
            width: parent.width - Theme.u * 6
            text: "✧ " + root.flashText
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            color: Theme.selectText
            font.bold: true
        }
    }
    SequentialAnimation {
        id: flash
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "slot"
                to: root.badgeWidth + Theme.u * 6
                duration: 120
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: badge
                property: "opacity"
                from: 0
                to: 1
                duration: 120
            }
        }
        PauseAnimation {
            duration: Math.max(250, Config.workspaces.popupMs)
        }
        ParallelAnimation {
            NumberAnimation {
                target: badge
                property: "opacity"
                to: 0
                duration: 140
            }
            NumberAnimation {
                target: root
                property: "slot"
                to: 0
                duration: 180
                easing.type: Easing.InCubic
            }
        }
    }

    MouseArea {
        // wheel anywhere on the row switches workspaces
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: w => Niri.action(w.angleDelta.y > 0 ? "FocusWorkspaceUp" : "FocusWorkspaceDown", {})
    }
}
