import QtQuick
import qs.config
import qs.widgets

// Pointer for previews; `click` shows which button was just pressed.
Item {
    id: root

    property string click: ""                // "" | left | right | middle
    width: 1
    height: 1
    z: 100

    Rectangle {
        visible: root.click !== ""
        anchors.centerIn: parent
        width: Theme.u * 9
        height: width
        radius: width / 2
        color: "transparent"
        border.width: Math.max(1, Theme.u / 2)
        border.color: root.click === "right" ? Theme.accent2 : root.click === "middle" ? Theme.accent3 : Theme.accent
    }
    PxText {
        visible: root.click !== ""
        x: Theme.u * 7
        y: -Theme.u * 9
        text: root.click === "right" ? I18n.t("ПКМ", "RMB") : root.click === "middle" ? I18n.t("колёсико", "wheel") : I18n.t("клик", "click")
        kind: "tiny"
        color: Theme.text
        style: Text.Outline
        styleColor: Theme.face
    }
    PxIcon {
        name: "cursor"
        pixel: Math.max(1, Math.round(Theme.u / 2))
        ink: Theme.edge
        fill: "#ffffff"
    }
}
