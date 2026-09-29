pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Full-screen flourish after a workspace switch (shaders/switch_fx.frag).
// Mapped only while it plays: a permanent overlay would block direct scanout
// of fullscreen games.
PanelWindow {
    id: win

    property int serial: 0
    readonly property var style: WorkspaceAnim.current
    property real progress: 1

    onSerialChanged: {
        if (style.fx === undefined)
            return;
        fx.seed = Math.random();
        progress = 0;
        visible = true;
        anim.restart();
    }

    visible: false
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "angelos-switch-fx"
    WlrLayershell.layer: WlrLayer.Overlay

    NumberAnimation {
        id: anim
        target: win
        property: "progress"
        from: 0
        to: 1
        duration: win.style.ms || 400
        easing.type: Easing.Linear
        onFinished: win.visible = false
    }

    ShaderEffect {
        id: fx
        anchors.fill: parent
        property real progress: win.progress
        property real mode: win.style.fx === undefined ? 0 : win.style.fx
        property real cell: Theme.u * 8
        property real seed: 0
        property size resolution: Qt.size(width, height)
        property color color1: Theme.accent
        property color color2: win.style.fx === 2 ? Theme.mix(Qt.color("#000000"), Theme.desk, 0.6) : Theme.mix(Theme.desk, Theme.accent2, 0.35)
        fragmentShader: Qt.resolvedUrl("../../shaders/switch_fx.frag.qsb")
    }
}
