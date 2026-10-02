import QtQuick
import qs.config
import "Cerberus.js" as Frames

// A puppy Cerberus in the circle's colours (widgets/Cerberus.js): `frame` steps the run
// (five frames), `asleep` lies him down with zzz, `blink` hides the zzz for a beat.
// The cat plugin is one in hell; the Wheel of Hell lets a big one run across the screen.
// Dark fur, the heads a shade lighter, only the eyes and the tail's ember in the accent.
PxIcon {
    property int frame: 0
    property bool asleep: false
    property bool blink: false

    bitmap: asleep ? Frames.cerberusSleep.map((r, i) => blink && i < 4 ? r.replace(/y/g, ".") : r) : Frames.cerberus(frame)
    ink: Theme.hellEdge
    body: Theme.hellFaceAlt
    fill: Theme.hellBlood
    fill3: Theme.hellAccent
    light: Theme.hellTextDim
    bad: Theme.hellAccent
    palette: ({
            "g": Theme.hex(Theme.hellRim)
        })
}
