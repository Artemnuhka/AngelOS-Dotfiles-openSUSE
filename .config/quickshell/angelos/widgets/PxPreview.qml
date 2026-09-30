import QtQuick
import qs.config
import qs.widgets.previews

// "preview.exe": a looping, gif-like animation of what a setting does, drawn
// live in the current theme colours by a scene from widgets/previews/ (listed below).
// SettingRow opens it under the row when an option is clicked.
PxWindow {
    id: root

    property string scene: ""
    property string variant: ""
    property string caption: ""
    property int duration: 3600             // one pass of the scene
    property int hold: 900                  // the last frame stays a moment, like a gif
    property int fps: 12
    property int frame: 0
    property int loops: 0                   // passes played (scenes may vary per pass)
    readonly property int frames: Math.max(1, Math.round(duration / 1000 * fps))
    readonly property real t: Math.min(1, frame / frames)
    property int sceneHeight: Theme.u * 78

    function restart() {
        frame = 0;
        loops = 0;
    }
    onVariantChanged: restart()

    title: "preview.exe" + (caption ? " · " + caption : "")
    icon: "play"
    compact: true
    translucent: false
    closable: true
    implicitHeight: chrome * 2 + titleHeight + bodyPadding * 2 + sceneHeight

    Timer {
        interval: Math.round(1000 / root.fps)
        running: root.visible && root.scene !== ""
        repeat: true
        onTriggered: {
            if (root.frame >= root.frames + Math.round(root.hold / 1000 * root.fps)) {
                root.frame = 0;
                root.loops++;
            } else {
                root.frame++;
            }
        }
    }

    // scenes as components: Quickshell only registers types it can see statically
    readonly property var scenes: ({
            "TaskClose": taskClose,
            "CloseFx": closeFx,
            "WallpaperFx": wallpaperFx,
            "StartMenu": startMenu,
            "BarStyle": barStyle
        })
    Component {
        id: taskClose
        TaskClose {}
    }
    Component {
        id: closeFx
        CloseFx {}
    }
    Component {
        id: wallpaperFx
        WallpaperFx {}
    }
    Component {
        id: startMenu
        StartMenu {}
    }
    Component {
        id: barStyle
        BarStyle {}
    }

    Loader {
        id: stage
        anchors.fill: parent
        clip: true
        sourceComponent: root.scenes[root.scene] || null
        onLoaded: {
            item.t = Qt.binding(() => root.t);
            item.variant = Qt.binding(() => root.variant);
            if (item.loops !== undefined)
                item.loops = Qt.binding(() => root.loops);
        }
    }
}
