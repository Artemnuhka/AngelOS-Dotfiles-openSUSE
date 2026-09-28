import QtQuick
import qs.config
import qs.services
import qs.widgets
import qs.modules.bar

PxButton {
    id: root

    property bool above: true
    property bool showPercent: true

    compact: true
    icon: Audio.muted || Audio.volume <= 0.001 ? "speakerMute" : "speaker"
    text: showPercent ? Math.round(Audio.volume * 100) + "%" : ""
    checked: mixer.visible
    onClicked: mixer.toggle()
    onRightClicked: Audio.toggleMute()

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: w => Audio.step(w.angleDelta.y > 0 ? 0.02 : -0.02)
    }

    MixerPanel {
        id: mixer
        anchorItem: root
        above: root.above
    }
}
