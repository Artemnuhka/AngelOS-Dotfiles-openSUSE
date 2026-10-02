import QtQuick
import Quickshell.Io

// The player's save: ~/.config/angelos/save.json, next to settings.json and apart from it
// (services/Story loads it). Settings are how the desktop is set up; the save is what the
// player did and where the story is. It survives shell restarts and project updates —
// the installer and updates never touch it; `angelos game reset` (or Settings → System,
// developer mode) starts it over.
JsonAdapter {
    property int version: 1
    property double createdAt: 0

    // who rules the corner and what came with her (was settings.json → y2k.*)
    property JsonObject player: JsonObject {
        property string character: "angel"  // angel | demon
        property double demonSince: 0       // ms; she fell
        property double lastPlea: 0         // ms; the last try to get out of hell (one per 10 minutes)
        property double wheelAt: 0          // the Wheel of Hell's last spin (one per 20 minutes)
        property double cursedUntil: 0      // the wheel's cursed cursor: another hell cursor until then
        property string cursedWas: ""       // the hell cursor it replaced
        property var pranks: []             // the demon's pranks this fall [{id, key, old, new, at, undone}]
        property double nextPrank: 0        // ms; not before
        property int returns: 0             // times the angel came back from hell; 3 open the portal
        property var angelSaved: null       // the theme mode kept while the demon rules ({mode}; older saves: heaven's wallpaper too)
        property var hellWall: null         // hell's wallpaper {circle, picked, fallback, outputs, workspaces}: the circle's painting or the player's pick in it (C2)
    }

    // the story's variables: the sins the player's choices weigh (limbo lust gluttony greed
    // wrath heresy violence fraud treachery — one per circle) and whatever flags the scenes set
    property var vars: ({})

    // hell
    property JsonObject hell: JsonObject {
        property string circle: ""          // the circle the player is in ("" = not in hell)
        property var path: []               // the circles of this fall, in the order seen
        property var fallCircles: []        // circles a fall began in: each once, then all over again
        property int falls: 0
        property int attempts: 0            // tries to get out from this circle
        property int silences: 0            // trials answered with silence, this fall
        property bool limbo: false          // the limbo outcome: neither here nor there
        property double limboSince: 0
        property bool pact: false           // signed: something of hers stays in heaven
        property bool amnesty: false        // fell under the old rules (before the circles): let out at the next start
        property var outcomes: []           // [{kind: stars|pact|limbo|amnesty, circle, at}]
    }

    // every choice the player made: [{scene, node, choice, tone, at}] (the last 400)
    property var choices: []
    // the novel's progress (was ~/.local/state/angelos/novel.json) and the running scene
    property var novel: null
}
