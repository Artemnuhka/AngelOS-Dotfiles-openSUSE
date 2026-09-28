pragma ComponentBehavior: Bound

import QtQuick
import qs.config

// Pick a screen position on a tiny pixel monitor (3×3 spots).
Column {
    id: root

    property string value: "bottom-center"
    property var allowed: names.map(n => n.id)
    signal picked(string value)

    readonly property var names: [
        {
            "id": "top-left",
            "label": I18n.t("сверху слева", "top left")
        },
        {
            "id": "top-center",
            "label": I18n.t("сверху посередине", "top center")
        },
        {
            "id": "top-right",
            "label": I18n.t("сверху справа", "top right")
        },
        {
            "id": "left",
            "label": I18n.t("слева", "left")
        },
        {
            "id": "center",
            "label": I18n.t("центр", "center")
        },
        {
            "id": "right",
            "label": I18n.t("справа", "right")
        },
        {
            "id": "bottom-left",
            "label": I18n.t("слева снизу", "bottom left")
        },
        {
            "id": "bottom-center",
            "label": I18n.t("снизу посередине", "bottom center")
        },
        {
            "id": "bottom-right",
            "label": I18n.t("справа снизу", "bottom right")
        }
    ]

    spacing: Theme.u * 2

    // the monitor
    Item {
        width: Theme.u * 96
        height: Theme.u * 64

        PxBox {
            id: screen
            width: parent.width
            height: Theme.u * 56
            sunken: true
            color: Theme.dark ? Theme.sunken : Theme.faceAlt

            Grid {
                anchors.fill: parent
                anchors.margins: Theme.u * 2
                columns: 3
                Repeater {
                    model: root.names
                    Item {
                        id: cell
                        required property var modelData
                        required property int index
                        readonly property bool on: root.value === modelData.id
                        readonly property bool ok: root.allowed.includes(modelData.id)
                        width: parent.width / 3
                        height: parent.height / 3

                        // the "toast" block, hugging the edge it belongs to
                        Rectangle {
                            width: Theme.u * 14
                            height: Theme.u * 6
                            x: cell.index % 3 === 0 ? Theme.u : cell.index % 3 === 2 ? parent.width - width - Theme.u : (parent.width - width) / 2
                            y: cell.index < 3 ? Theme.u : cell.index >= 6 ? parent.height - height - Theme.u : (parent.height - height) / 2
                            color: cell.on ? Theme.accent : m.containsMouse && cell.ok ? Theme.mix(Theme.face, Theme.accent, 0.5) : "transparent"
                            border.width: Math.max(1, Theme.u / 2)
                            border.color: cell.ok ? (cell.on ? Theme.edge : Theme.textDim) : "transparent"
                        }
                        MouseArea {
                            id: m
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: cell.ok
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.value = cell.modelData.id;
                                root.picked(cell.modelData.id);
                            }
                        }
                    }
                }
            }
        }
        // stand
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: screen.height
            width: Theme.u * 10
            height: Theme.u * 4
            color: Theme.lo
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: screen.height + Theme.u * 4
            width: Theme.u * 26
            height: Theme.u * 3
            color: Theme.lo
        }
    }

    PxText {
        text: (root.names.find(n => n.id === root.value) || {
                "label": root.value
            }).label
        dim: true
    }
}
