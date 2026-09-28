import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Popup window anchored to a bar item, framed as a small NGO window.
PopupWindow {
    id: root

    required property Item anchorItem
    property string title: ""
    property string panelId: title
    readonly property string outputName: anchorItem && anchorItem.QsWindow.window && anchorItem.QsWindow.window.screen ? anchorItem.QsWindow.window.screen.name : ""
    Component.onCompleted: PopupManager.registerPopup(root)
    Component.onDestruction: PopupManager.unregisterPopup(root)
    property string icon: "heart"
    property bool above: false
    property int contentWidth: Theme.u * 140
    property int contentHeight: Theme.u * 80
    default property alias content: win.content

    function toggle() {
        PopupManager.toggle(root);
    }

    anchor.item: anchorItem
    anchor.rect.x: 0
    anchor.rect.y: above ? -Theme.u * 2 : anchorItem.height + Theme.u * 2
    anchor.rect.width: anchorItem.width
    anchor.rect.height: 1
    anchor.edges: (above ? Edges.Top : Edges.Bottom) | Edges.Right
    anchor.gravity: (above ? Edges.Top : Edges.Bottom) | Edges.Left
    anchor.adjustment: PopupAdjustment.Slide | PopupAdjustment.Flip
    grabFocus: true
    color: "transparent"
    implicitWidth: contentWidth + Theme.u * 3
    implicitHeight: win.titleHeight + contentHeight + Theme.pad * 2 + Theme.u * 8
    visible: false
    onVisibleChanged: {
        if (visible && PopupManager.active !== root) {
            if (PopupManager.active)
                PopupManager.close(PopupManager.active);
            PopupManager.active = root;
        }
        if (!visible && PopupManager.active === root)
            PopupManager.active = null;
    }

    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: win
    }

    PxWindow {
        id: win
        width: root.contentWidth
        height: root.implicitHeight - Theme.u * 3
        title: root.title
        icon: root.icon
        compact: true
        onCloseClicked: PopupManager.close(root)
        focus: true
        Keys.onEscapePressed: PopupManager.close(root)
    }
}
