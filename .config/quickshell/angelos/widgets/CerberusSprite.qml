import QtQuick
import qs.config
import "Cerberus.js" as Frames

// A puppy Cerberus in hell's colours (widgets/Cerberus.js): `frame` steps the run
// (five frames), `asleep` lies him down with zzz, `blink` hides the zzz for a beat.
// The cat plugin is one in hell; the Wheel of Hell lets a big one run across the screen.
PxIcon {
    property int frame: 0
    property bool asleep: false
    property bool blink: false

    bitmap: asleep ? Frames.cerberusSleep.map((r, i) => blink && i < 4 ? r.replace(/y/g, ".") : r) : Frames.cerberus(frame)
    ink: Theme.hellEdge
    body: "#341619"
    fill: "#ff6a8b"
    fill3: Theme.hellFlame
    light: Theme.hellText
    bad: "#ff2a3d"
    palette: ({
            "g": "#542228"
        })
}
