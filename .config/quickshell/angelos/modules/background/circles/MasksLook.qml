pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// The look of RadialMenu in the circle of fraud: masks on a string, hung in an oval round
// the pointer — bone and dark faces by turns, each tilted its own way, two slits for eyes
// above the entry it hides; the one you're on straightens and leans out. Opening, they swing
// in on the string.
Item {
    id: look

    required property var menu
    readonly property real k: menu.k
    readonly property int n: Math.max(1, menu.slots.length)
    readonly property real maskW: Math.round(Theme.u * 20 * k)
    readonly property real maskH: Math.round(Theme.u * 25 * k)
    readonly property real labelRoom: menu.labels ? Theme.sizeTiny + Theme.u * 3 : 0
    // an oval half as wide again as it is tall, room for every mask and its name round it
    readonly property real ry: Math.max(Theme.u * 56 * k, n * (maskW + (menu.labels ? Theme.u * 26 : Theme.u * 10) * k) / (2 * Math.PI * 1.25))
    readonly property real rx: ry * 1.5
    readonly property real reach: rx + maskW / 2 + Theme.u * 10
    readonly property Item blurItem: null
    function angleOf(i) {
        return -Math.PI / 2 + i * 2 * Math.PI / n;
    }
    function pointOf(i, grow) {
        const a = angleOf(i), s = (0.6 + 0.4 * menu.reveal) * (grow || 1);
        return Qt.point(menu.cx + Math.cos(a) * rx * s, menu.cy + Math.sin(a) * ry * s);
    }
    function nav(e) {
        return menu.walk(e);
    }
    anchors.fill: parent

    // the string they hang on
    Canvas {
        x: look.menu.cx - look.rx - Theme.u * 4
        y: look.menu.cy - look.ry - Theme.u * 4
        width: (look.rx + Theme.u * 4) * 2
        height: (look.ry + Theme.u * 4) * 2
        scale: 0.6 + 0.4 * look.menu.reveal
        opacity: look.menu.reveal
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const u = Theme.u, cx = width / 2, cy = height / 2;
            ctx.fillStyle = Theme.hellRim.toString();
            for (let t = 0; t < 2 * Math.PI; t += 0.012) {
                const x = cx + Math.cos(t) * look.rx, y = cy + Math.sin(t) * look.ry;
                ctx.fillRect(Math.round(x / u) * u, Math.round(y / u) * u, u, u);
            }
        }
    }

    CircleHub {
        menu: look.menu
        size: Math.round(look.maskW * 1.1)
        color: Theme.hellFace
        nameGap: Theme.u * 2
    }

    Repeater {
        model: look.menu.slots
        CircleEntry {
            id: mask
            menu: look.menu
            readonly property point at: look.pointOf(index, hot ? 1.08 : 1)
            readonly property bool bone: index % 2 === 0
            readonly property color face: bone ? Theme.hellText : Theme.mix(Theme.hellFaceAlt, Theme.hellTextDim, 0.25)
            readonly property color type: bone ? Theme.hellBody : Theme.hellText
            width: look.maskW
            height: look.maskH + look.labelRoom
            x: at.x - width / 2
            y: at.y - look.maskH / 2
            opacity: Math.min(1, look.menu.reveal * 1.4)
            Behavior on x {
                NumberAnimation {
                    duration: Motion.ms(90)
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: Motion.ms(90)
                }
            }
            Item {
                id: shape
                width: look.maskW
                height: look.maskH
                rotation: mask.hot ? 0 : (mask.index % 3 - 1) * 8 + (1 - look.menu.reveal) * 30
                Behavior on rotation {
                    NumberAnimation {
                        duration: Motion.ms(120)
                    }
                }
                // the face: broad brow, narrow chin
                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: width * 0.3
                    topRightRadius: width * 0.3
                    bottomLeftRadius: width / 2
                    bottomRightRadius: width / 2
                    color: mask.face
                    border.width: Math.max(1, Theme.u / 2)
                    border.color: mask.hot ? Theme.hellAccent : Theme.hellRim
                }
                // the eye slits, slanted — sad on the dark ones
                Repeater {
                    model: 2
                    Rectangle {
                        required property int index
                        width: look.maskW * 0.26
                        height: Math.max(2, Theme.u * 1.5)
                        radius: height / 2
                        x: index ? shape.width * 0.62 : shape.width * 0.38 - width
                        y: shape.height * 0.28
                        rotation: (index ? -1 : 1) * (mask.bone ? -12 : 12)
                        color: Theme.hellBody
                    }
                }
                CircleIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.45
                    hot: mask.hot
                    name: mask.icon
                    pixel: Math.max(1, Math.round(Theme.u * look.k * 0.75))
                    ink: mask.type
                    light: mask.face
                    body: Theme.mix(mask.face, mask.type, 0.2)
                    fill: mask.hot ? Theme.hellBlood : Theme.mix(mask.type, mask.face, 0.35)
                }
            }
            CircleLabel {
                visible: look.menu.labels
                hot: mask.hot
                anchors.horizontalCenter: shape.horizontalCenter
                y: look.maskH + Theme.u * 2
                text: mask.label
            }
        }
    }

    CircleFly {
        menu: look.menu
        reach: look.reach
        at: look.menu.flyIndex >= 0 ? look.pointOf(look.menu.flyIndex, 1.15) : Qt.point(look.menu.cx, look.menu.cy)
    }
}
