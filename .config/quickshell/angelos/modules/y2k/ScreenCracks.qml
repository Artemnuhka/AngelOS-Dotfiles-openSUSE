pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// The demon's broken glass on one screen (services/Cracks: where, what, how far). It lives in
// the wallpaper's surface (modules/background/Background), the one niri keeps in the backdrop:
// under the windows, never sliding with a workspace switch, and taking no input — Start and
// the desk under it stay clickable. The nearer the pointer (Pointer, reported by the desktop),
// the clearer the glass gets.
Item {
    id: root

    property string screenName: ""
    readonly property bool shown: Cracks.wanted && Cracks.screenName === screenName
    readonly property var scr: Shell.screenByName(screenName)
    readonly property var sq: shown ? Cracks.rect(scr) : ({
            "x": 0,
            "y": 0,
            "side": 0
        })

    Loader {
        active: root.shown
        x: root.sq.x
        y: root.sq.y
        width: root.sq.side
        height: root.sq.side

        sourceComponent: Item {
            id: glass
            // 1 far away … 0 on the impact, stepped in eight like everything pixel; the
            // glass keeps a faint 10 % even then
            readonly property real away: {
                if (Pointer.screen !== root.screenName)
                    return 1;
                const side = root.sq.side;
                const ix = root.sq.x + side * Cracks.impact.x, iy = root.sq.y + side * Cracks.impact.y;
                const d = Math.hypot(Pointer.x - ix, Pointer.y - iy);
                const near = side * 0.2, far = side * 1.3;
                const k = Math.max(0, Math.min(1, (d - near) / (far - near)));
                return Math.round(k * k * (3 - 2 * k) * 8) / 8;
            }
            property real veil: 0.1 + 0.9 * away
            Behavior on veil {
                NumberAnimation {
                    duration: Motion.ms(110)
                }
            }

            BreakageArt {
                anchors.fill: parent
                kind: Cracks.kind
                grow: Cracks.grow
                fall: Cracks.fall
                seed: Cracks.seed
                weak: Cracks.weak
                impact: Cracks.impact
                clock: Cracks.clock
                veil: glass.veil
            }
        }
    }
}
