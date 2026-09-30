import QtQuick
import qs.config
import qs.widgets

// Undertale-style speech for the corner helper: every letter on its own, laid
// out once for the whole line (the bubble doesn't grow while she types), shown
// up to `shown`, and trembling — a new random nudge every frame, stepped like
// everything pixel. The demon trembles harder (AngelHelper sets `shake`).
Flow {
    id: root

    property string text: ""
    property int shown: text.length
    property real shake: Math.max(1, Theme.u / 2)   // px each way
    property int tick: 0

    Timer {
        interval: 70
        repeat: true
        running: root.visible && root.shake > 0 && root.text !== ""
        onTriggered: root.tick++
    }
    // words with their trailing spaces, so the line wraps between words only
    readonly property var words: {
        const out = [];
        const re = /\S+\s*|\s+/g;
        let m;
        while ((m = re.exec(text)) !== null)
            out.push({
                "w": m[0],
                "at": m.index
            });
        return out;
    }
    function nudge(at, salt) {
        const v = Math.sin((at + 1) * 12.9898 + (tick + salt) * 78.233) * 43758.5453;
        return (v - Math.floor(v)) * 2 - 1;
    }

    Repeater {
        model: root.words
        Row {
            id: word
            required property var modelData
            Repeater {
                model: word.modelData.w.length
                PxText {
                    id: letter
                    required property int index
                    readonly property int at: word.modelData.at + index
                    text: word.modelData.w.charAt(index)
                    opacity: at < root.shown ? 1 : 0
                    transform: Translate {
                        x: Math.round(root.nudge(letter.at, 0) * root.shake)
                        y: Math.round(root.nudge(letter.at, 17) * root.shake)
                    }
                }
            }
        }
    }
}
