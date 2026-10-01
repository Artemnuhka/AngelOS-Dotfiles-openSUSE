import QtQuick
import Quickshell
import Quickshell.Io

// The helper drawn from pictures in parts (sprites/<who>/, cut from the
// artist's sheets by the sprite-rig tool): the body with blink and talk
// overlays on top, the wings (and the demon's tail) under it as strips of
// pre-rendered swing frames, played back and forth on the helper's 8 fps
// clock. rig.json holds the layout in art pixels; `px` screen pixels each.
// `variant`: which pictures — "" the chibi ones (sprites/<who>/), "glitch" the
// cracked-halo angel and the sleepless neon demon (sprites/<who>-glitch/).
// `ready` stays false without the pictures: the helper keeps her pixel sprite.
Item {
    id: root

    property string who: "angel"
    property string variant: ""
    property int tick: 0
    property bool blink: false
    property bool talk: false
    // held by the pointer: the wings beat twice as fast
    property bool flutter: false
    property real px: 1
    // false: Settings → Y2K → Looks picked a pixel version, the helper draws that instead
    property bool use: true

    // both figures are read up front: the swap flips between them at once
    readonly property RigFile file: variant === "glitch" ? (who === "demon" ? demonGlitchRig : angelGlitchRig) : (who === "demon" ? demonRig : angelRig)
    readonly property var rig: file.rig
    readonly property bool ready: use && !!rig
    // where the body is inside the rig (the figure without wings and tail)
    readonly property rect body: ready ? Qt.rect(rig.body.x * px, rig.body.y * px, rig.body.w * px, rig.body.h * px) : Qt.rect(0, 0, width, height)

    implicitWidth: ready ? rig.size[0] * px : 0
    implicitHeight: ready ? rig.size[1] * px : 0

    component RigFile: FileView {
        required property string name
        readonly property string dir: Quickshell.shellDir + "/modules/y2k/sprites/" + name + "/"
        property var rig: null
        path: dir + "rig.json"
        printErrors: false
        // read at once: no frame of the pixel sprite before the pictures
        blockLoading: true
        onLoaded: {
            try {
                rig = JSON.parse(text());
            } catch (e) {
                console.warn("SpriteRig:", path, e);
                rig = null;
            }
        }
        onLoadFailed: rig = null
    }
    RigFile {
        id: angelRig
        name: "angel"
    }
    RigFile {
        id: demonRig
        name: "demon"
    }
    RigFile {
        id: angelGlitchRig
        name: "angel-glitch"
    }
    RigFile {
        id: demonGlitchRig
        name: "demon-glitch"
    }
    // the parts of one layer; each carries its own picture, so the old figure's
    // parts never look into the new one's folder while the swap swaps them
    function partsUnder(under) {
        const r = rig, dir = file.dir;
        return !r ? [] : Object.keys(r.parts).filter(k => !!r.parts[k].under === under).map(k => Object.assign({
                "src": "file://" + dir + k + ".png"
            }, r.parts[k]));
    }

    // a strip of swing frames, cut to the current one
    component Part: Item {
        id: part
        required property var modelData
        readonly property var p: modelData
        readonly property int step: Math.floor(root.tick * (root.flutter && p.every === 1 ? 2 : 1) / p.every)
        readonly property int period: Math.max(1, (p.frames - 1) * 2)
        // back and forth: 0 1 2 3 4 3 2 1 …
        readonly property int frame: {
            const i = step % period;
            return i < p.frames ? i : period - i;
        }
        x: p.x * root.px
        y: p.y * root.px
        width: p.w * root.px
        height: p.h * root.px
        clip: true
        Image {
            x: -part.frame * part.width
            width: part.width * part.p.frames
            height: part.height
            source: part.p.src
            smooth: false
            mipmap: false
        }
    }

    Repeater {
        model: root.partsUnder(true)
        Part {}
    }
    Item {
        visible: root.ready
        x: root.body.x
        y: root.body.y
        width: root.body.width
        height: root.body.height
        Image {
            anchors.fill: parent
            source: root.ready ? "file://" + root.file.dir + "body.png" : ""
            smooth: false
            mipmap: false
        }
        Image {
            anchors.fill: parent
            visible: root.blink
            source: root.ready ? "file://" + root.file.dir + "eyes.png" : ""
            smooth: false
            mipmap: false
        }
        Image {
            anchors.fill: parent
            visible: root.talk
            source: root.ready ? "file://" + root.file.dir + "mouth.png" : ""
            smooth: false
            mipmap: false
        }
    }
    Repeater {
        model: root.partsUnder(false)
        Part {}
    }
}
