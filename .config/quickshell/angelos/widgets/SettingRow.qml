import QtQuick
import qs.config

// "label ........ control" row with an optional hint below the label.
// With `preview` set to a scene (widgets/previews/<scene>.qml), controls call
// show(value, caption) when an option is clicked and a looping preview.exe
// opens under the row; its × folds it away.
Item {
    id: root

    property string label: ""
    property string hint: ""
    readonly property string settingsSkin: Theme.settingsSkinFor(root.parent)
    readonly property bool streamLayout: settingsSkin === "stream"
    property int labelWidth: streamLayout ? width - Theme.u * 10 : Math.min(Theme.u * 120, width * 0.45)
    default property alias control: slot.data
    property string preview: ""
    property string previewVariant: ""
    property string previewCaption: ""
    property bool previewOpen: false
    readonly property int rowHeight: streamLayout ? labels.implicitHeight + slot.childrenRect.height + Theme.u * 12 : Math.max(labels.implicitHeight, slot.childrenRect.height) + Theme.u * (settingsSkin === "windose" ? 8 : 2)

    function show(value, caption) {
        if (!preview)
            return;
        previewVariant = String(value);
        previewCaption = caption || "";
        previewOpen = true;
        if (gif.item)
            gif.item.restart();
    }

    width: parent ? parent.width : implicitWidth
    implicitHeight: rowHeight + (gif.item ? gif.item.implicitHeight + Theme.u * 3 : 0)

    Rectangle {
        visible: root.settingsSkin !== "classic"
        width: parent.width
        height: root.rowHeight
        radius: root.streamLayout ? Theme.u * 3 : 0
        color: root.streamLayout ? Theme.mix(Theme.streamPanel, Theme.streamLive, 0.055) : Theme.windoseSticker
        border.width: Math.max(1, Theme.u / 2)
        border.color: root.streamLayout ? Theme.mix(Theme.streamLive, Theme.streamPanel, 0.55) : Theme.mix(Theme.windoseInk, Theme.windosePaper, 0.55)
    }
    Rectangle {
        visible: root.settingsSkin !== "classic"
        width: root.streamLayout ? Theme.u * 2 : Theme.u * 3
        height: root.rowHeight - Theme.u * 2
        x: Theme.u
        y: Theme.u
        radius: root.streamLayout ? Theme.u : 0
        color: root.streamLayout ? Theme.streamLive : Theme.windoseRose
    }

    Column {
        id: labels
        x: root.settingsSkin === "classic" ? 0 : Theme.u * 6
        width: root.labelWidth
        y: root.streamLayout ? Theme.u * 4 : (root.rowHeight - implicitHeight) / 2
        PxText {
            width: parent.width
            text: root.label
            wrapMode: Text.Wrap
            font.bold: root.settingsSkin !== "classic"
        }
        PxText {
            visible: root.hint !== ""
            width: parent.width
            text: root.hint
            kind: "tiny"
            dim: true
            wrapMode: Text.Wrap
        }
    }
    Item {
        id: slot
        readonly property bool fixedWidth: true // PxToggle wraps its label to fit
        x: root.streamLayout ? Theme.u * 6 : root.labelWidth + Theme.u * (root.settingsSkin === "classic" ? 6 : 12)
        width: root.width - x - (root.settingsSkin === "classic" ? 0 : Theme.u * 5)
        y: root.streamLayout ? labels.y + labels.implicitHeight + Theme.u * 3 : (root.rowHeight - height) / 2
        height: childrenRect.height
    }
    Loader {
        id: gif
        active: root.preview !== "" && root.previewOpen
        y: root.rowHeight + Theme.u
        x: Math.min(root.labelWidth, Theme.u * 20)
        width: Math.min(root.width - x, Theme.u * 230)
        sourceComponent: PxPreview {
            width: gif.width
            height: implicitHeight
            scene: root.preview
            variant: root.previewVariant
            caption: root.previewCaption
            onCloseClicked: root.previewOpen = false
        }
    }
}
