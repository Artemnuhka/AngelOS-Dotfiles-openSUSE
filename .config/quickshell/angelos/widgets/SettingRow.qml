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
    property int labelWidth: Math.min(Theme.u * 120, width * 0.45)
    default property alias control: slot.data
    property string preview: ""
    property string previewVariant: ""
    property string previewCaption: ""
    property bool previewOpen: false
    readonly property int rowHeight: Math.max(labels.implicitHeight, slot.childrenRect.height) + Theme.u * 2

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

    Column {
        id: labels
        width: root.labelWidth
        y: (root.rowHeight - implicitHeight) / 2
        PxText {
            width: parent.width
            text: root.label
            wrapMode: Text.Wrap
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
        anchors.left: labels.right
        anchors.leftMargin: Theme.u * 6
        anchors.right: parent.right
        y: (root.rowHeight - height) / 2
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
