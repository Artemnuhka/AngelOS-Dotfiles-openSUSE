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
                // the owner's binding (currentValue: Config.x, onActivated: Config.x = v)
                // updates it; assigning here first would break that binding and leave a
                // stale pick when the value later changes elsewhere (issue #15)
                const picked = modelData.value;
                root.activated(picked);
                if (root.currentValue !== picked)
                    root.currentValue = picked;
            }
        }
    }
}
