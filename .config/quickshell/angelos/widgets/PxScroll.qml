import QtQuick
import qs.config

// Flickable with a chunky pixel scrollbar.
Item {
    id: root

    property alias flick: flick
    property alias contentHeight: flick.contentHeight
    property alias contentY: flick.contentY
    property bool barVisible: flick.contentHeight > flick.height + 1
    default property alias content: flick.flickableData

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.rightMargin: root.barVisible ? bar.width + Theme.u * 3 : 0
        clip: true
        contentWidth: width
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 4000
        maximumFlickVelocity: 3000
    }

    PxBox {
        id: bar
        visible: root.barVisible
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Theme.u * 8
        sunken: true
        color: Theme.sunken

        PxBox {
            id: handle
            x: 0
            width: parent.width - bar.inset * 2
            height: Math.max(Theme.u * 12, (parent.height - bar.inset * 2) * flick.visibleArea.heightRatio)
            y: (parent.height - bar.inset * 2 - height) * (flick.contentY / Math.max(1, flick.contentHeight - flick.height))
            color: handleMouse.pressed ? Theme.accent : Theme.faceAlt

            MouseArea {
                id: handleMouse
                anchors.fill: parent
                property real startY
                property real startContent
                onPressed: m => {
                    startY = mapToItem(bar, 0, m.y).y;
                    startContent = flick.contentY;
                }
                onPositionChanged: m => {
                    if (!pressed)
                        return;
                    const dy = mapToItem(bar, 0, m.y).y - startY;
                    const range = bar.height - handle.height;
                    const maxY = flick.contentHeight - flick.height;
                    flick.contentY = Math.max(0, Math.min(maxY, startContent + dy / Math.max(1, range) * maxY));
                }
            }
        }
    }
}
