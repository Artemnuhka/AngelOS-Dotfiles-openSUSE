pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services

// Two stacked images blended by the pixel transition shader.
Item {
    id: root

    required property string screenName
    readonly property var activeWs: Niri.activeWorkspace(screenName)
    readonly property string target: Wallpapers.resolve(screenName, activeWs ? activeWs.idx : 1)
    property string shown: ""
    property real progress: 1
    readonly property int styleIndex: {
        const styles = {
            "mosaic-dither": 0,
            "mosaic": 1,
            "dither": 2
        };
        const value = styles[Config.wallpaper.transition];
        return value === undefined ? -1 : value;
    }

    function url(p) {
        return p ? (p.startsWith("/") ? "file://" + p : p) : "";
    }

    // pixel transition only when the picture itself is changed (settings / IPC);
    // switching workspaces swaps instantly, even with per-workspace wallpapers
    readonly property string configKey: JSON.stringify([Config.wallpaper.fallback, Config.wallpaper.outputs, Config.wallpaper.workspaces])
    property bool configChanged: false
    onConfigKeyChanged: configChanged = true

    function go(path) {
        const animate = configChanged && styleIndex >= 0 && Niri.ready && shown !== "";
        configChanged = false;
        anim.stop();
        if (!animate) {
            shown = path;
            fromImg.source = url(path);
            toImg.source = url(path);
            progress = 1;
            return;
        }
        fromImg.source = url(shown);
        shown = path;
        toImg.source = url(path);
        progress = 0;
        if (toImg.status === Image.Ready)
            anim.start();
        else
            waitingForLoad = true;
    }
    property bool waitingForLoad: false

    onTargetChanged: if (target !== shown)
        Qt.callLater(() => go(target))
    Component.onCompleted: {
        shown = target;
        fromImg.source = url(target);
        toImg.source = url(target);
        configChanged = false;
    }

    NumberAnimation {
        id: anim
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: Config.wallpaper.duration
        easing.type: Easing.Linear
    }

    Image {
        id: fromImg
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.width, root.height)
        asynchronous: true
        cache: true
        smooth: true
        visible: false
    }
    Image {
        id: toImg
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.width, root.height)
        asynchronous: true
        cache: true
        smooth: true
        visible: false
        onStatusChanged: if (status === Image.Ready && root.waitingForLoad) {
            root.waitingForLoad = false;
            anim.start();
        }
    }

    ShaderEffectSource {
        id: fromSrc
        sourceItem: fromImg
        hideSource: true
        live: true
        visible: false
    }
    ShaderEffectSource {
        id: toSrc
        sourceItem: toImg
        hideSource: true
        live: true
        visible: false
    }

    ShaderEffect {
        anchors.fill: parent
        property var fromTex: fromSrc
        property var toTex: toSrc
        property real progress: root.progress
        property real maxBlock: Config.wallpaper.maxBlock
        property real style: Math.max(0, root.styleIndex)
        property size resolution: Qt.size(width, height)
        fragmentShader: Qt.resolvedUrl("../../shaders/pixel_transition.frag.qsb")
    }
}
