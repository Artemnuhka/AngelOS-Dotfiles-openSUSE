import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets
import "."

// Desktop presence: a small breathing "claude.exe" window in the bottom-left corner.
Item {
    id: root

    property var plugin
    property string screenName
    readonly property string mode: plugin ? plugin.get("orb", "active") : "active"   // always | active | off
    readonly property string onScreen: plugin ? plugin.get("orbScreen", "") : ""
    readonly property bool here: !onScreen || onScreen === screenName

    PxWindow {
        id: win
        visible: root.here && (root.mode === "always" || (root.mode === "active" && (Pulse.state !== "none" || !!Pulse.presence)))
        x: Theme.u * 20
        y: root.height - height - Theme.u * 40
        width: Theme.u * 120
        height: titleHeight + col.implicitHeight + Theme.pad * 2 + Theme.u * 8
        title: "claude.exe"
        icon: "bot"
        compact: true
        closable: false

        Column {
            id: col
            width: parent.width
            spacing: Theme.u * 3
            Breath {
                anchors.horizontalCenter: parent.horizontalCenter
                plugin: root.plugin
                pixel: Theme.u * 4
                scale: 0.94 + 0.06 * glow * (root.plugin ? root.plugin.get("swell", 1.0) : 1)
            }
            PxText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Pulse.word
                kind: "title"
                color: Pulse.colorFor(Pulse.state, Theme)
            }
            PxText {
                visible: !!Pulse.presence
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: Pulse.presence ? Pulse.presence.message : ""
                dim: true
            }
            Limits {
                width: parent.width
                compact: true
            }
            PxText {
                visible: Pulse.list.length > 1
                anchors.horizontalCenter: parent.horizontalCenter
                text: I18n.t("сессий: ", "Sessions: ") + Pulse.list.length
                kind: "tiny"
                dim: true
            }
        }
    }
}
