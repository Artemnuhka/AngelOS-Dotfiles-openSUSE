import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets
import "."

// Desktop presence ("claude.exe"): breathing mascot, state, limits. The host draws the frame.
Item {
    id: root

    property var plugin
    property string screenName
    property var widget
    readonly property string mode: plugin ? plugin.get("orb", "active") : "active"   // always | active | off
    // the host hides the frame when this is false (still movable in edit mode)
    readonly property bool wantVisible: mode === "always" || (mode === "active" && (Pulse.state !== "none" || !!Pulse.presence))

    implicitWidth: Theme.u * 116
    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: Theme.u * 3
        Breath {
            anchors.horizontalCenter: parent.horizontalCenter
            plugin: root.plugin
            pixel: Theme.u * 4
            scale: 0.96 + 0.04 * glow * (root.plugin ? root.plugin.get("swell", 1.0) : 1)
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
            text: I18n.t("сессий: ", "sessions: ") + Pulse.list.length
            kind: "tiny"
            dim: true
        }
    }
}
