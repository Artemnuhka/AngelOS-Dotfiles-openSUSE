pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Clipboard history (Mod+V): type to filter, Enter copies, Delete removes.
PanelWindow {
    id: win

    screen: Shell.focusedScreen
    visible: Shell.clipboardOpen
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: Qt.alpha(Theme.shadow, 0.25)
    WlrLayershell.namespace: "angelos-clipboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? (Shell.dev ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive) : WlrKeyboardFocus.None

    property string query: ""
    property int current: 0
    readonly property var results: Clipboard.history.filter(h => !query || h.toLowerCase().includes(query.toLowerCase()))

    function pick(text) {
        Clipboard.copy(text);
        Shell.clipboardOpen = false;
    }

    onVisibleChanged: if (visible) {
        query = "";
        current = 0;
        field.text = "";
        field.focusField();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: Shell.clipboardOpen = false
    }

    BackgroundEffect.blurRegion: Config.appearance.blur ? blurRegion : null
    Region {
        id: blurRegion
        item: dialog
    }

    PxWindow {
        id: dialog
        anchors.centerIn: parent
        width: Theme.u * 230
        height: Theme.u * 250
        title: I18n.t("буфер_обмена.txt", "clipboard.txt")
        icon: "package"
        onCloseClicked: Shell.clipboardOpen = false

        MouseArea {
            anchors.fill: parent
        }

        PxField {
            id: field
            width: parent.width - clearBtn.width - Theme.u * 3
            icon: "search"
            placeholder: I18n.t("поиск…", "Searching…")
            onEdited: {
                win.query = text;
                win.current = 0;
            }
            onAccepted: if (win.results.length)
                win.pick(win.results[win.current])
            onKeyPressed: e => {
                if (e.key === Qt.Key_Escape) {
                    Shell.clipboardOpen = false;
                    e.accepted = true;
                } else if (e.key === Qt.Key_Down) {
                    win.current = Math.min(win.results.length - 1, win.current + 1);
                    list.positionViewAtIndex(win.current, ListView.Contain);
                    e.accepted = true;
                } else if (e.key === Qt.Key_Up) {
                    win.current = Math.max(0, win.current - 1);
                    list.positionViewAtIndex(win.current, ListView.Contain);
                    e.accepted = true;
                } else if (e.key === Qt.Key_Delete && win.results.length) {
                    Clipboard.remove(win.results[win.current]);
                    e.accepted = true;
                }
            }
        }
        PxButton {
            id: clearBtn
            anchors.right: parent.right
            height: field.height
            icon: "trash"
            onClicked: Clipboard.clear()
        }

        PxBox {
            y: field.height + Theme.u * 5
            width: parent.width
            height: parent.height - y
            sunken: true
            color: Qt.alpha(Theme.sunken, 0.75)

            PxText {
                visible: win.results.length === 0
                anchors.centerIn: parent
                text: I18n.t("пусто… скопируй что-нибудь ♡", "Nothing here… copy something ♡")
                dim: true
            }

            ListView {
                id: list
                anchors.fill: parent
                anchors.margins: Theme.u * 2
                clip: true
                model: win.results
                boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    id: item
                    required property string modelData
                    required property int index
                    readonly property bool sel: index === win.current
                    width: list.width
                    height: txt.implicitHeight + Theme.u * 6
                    color: sel ? Theme.select : m.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.12) : "transparent"
                    PxText {
                        id: txt
                        x: Theme.u * 4
                        width: parent.width - Theme.u * 8
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        text: item.modelData.replace(/\s+/g, " ").slice(0, 300)
                        maximumLineCount: 2
                        wrapMode: Text.WrapAnywhere
                        elide: Text.ElideRight
                        color: item.sel ? Theme.selectText : Theme.text
                    }
                    MouseArea {
                        id: m
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.pick(item.modelData)
                    }
                }
            }
        }
    }
}
