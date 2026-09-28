import QtQuick
import qs.config

// Row of toggle buttons; model: [{label, value, icon}]
Row {
    id: root

    property var model: []
    property var currentValue
    signal activated(var value)

    spacing: Theme.u * 2

    Repeater {
        model: root.model
        PxButton {
            required property var modelData
            text: modelData.label || ""
            icon: modelData.icon || ""
            checked: root.currentValue === modelData.value
            onClicked: {
                root.currentValue = modelData.value;
                root.activated(modelData.value);
            }
        }
    }
}
