import QtQuick
import Quickshell.Io

// Every angelOS setting with its default value. Config.qml loads the user's
// ~/.config/angelos/settings.json into one copy and keeps a second, untouched
// copy as `Config.defaults` ("Reset this page", undo labels).
JsonAdapter {
    property JsonObject appearance: JsonObject {
        property string customAccent: "#c77dff"
        property string language: "ru"
        property string mode: "dark"        // light | dark | auto
        property int lightFrom: 8           // auto: light theme from this hour
        property int darkFrom: 20           // auto: dark theme from this hour
        property string flavor: "overdose" // bubblegum | overdose | cyberangel
        property real opacity: 0.84         // panel background opacity (blur shows through)
        property bool blur: true
        property int px: 2                  // size of one "art pixel" in screen pixels
        property int fontScale: 1           // 1 or 2 keeps pixel fonts crisp
        property bool shadows: true         // hard pixel drop shadows
        property bool themeApps: true       // render templates for kitty/foot/gtk/niri
        property var disabledTemplates: []
        property string fontTitle: ""       // "" = Pixeloid Sans
        property string fontBody: ""        // "" = CozetteVector
        property string fontMono: ""        // "" = Pixeloid Mono
        property bool autoWallpaperColors: true // flavor "wallpaper": follow wallpaper changes
        property string paletteScreen: ""  // screen whose wallpaper feeds the palette; "" = first
    }

    property JsonObject bar: JsonObject {
        property string style: "taskbar"    // taskbar | top | island
        property var screens: []            // empty = every screen
        property bool compactOnVertical: true
        property bool showWindows: true
        property bool taskLabels: false
        property int taskMinWidth: 40       // task buttons with titles, in art pixels
        property int taskMaxWidth: 90
        property string workspaceStyle: "hearts" // hearts | icons | both
        property int workspaceIcons: 3      // max app icons per workspace
        property bool allWindows: false     // taskbar: every window, not only current workspace
        property bool showMedia: true
        property bool showSeconds: false
        property string startLabel: "angelOS"
        property string startStyle: "classic" // classic (Win98 list) | win11 (centred, pinned grid) | fullscreen (iPhone-like app grid)
        property var startPinned: []        // desktop entry ids pinned in Start
        property string startAlign: "auto" // auto (classic at the button, win11 centred) | left | center | right
        property int startWidth: 100        // Start menu width, % of the default
        property int startRows: 3           // win11: rows of pinned apps
        property string logoStyle: "classic" // classic | angel
        property bool metaTap: true         // a short Meta tap opens Start (Windows-like)
        property int metaTapMs: 400         // longer presses are holds, not taps
        property bool metaTapFullscreen: false // also over fullscreen windows / games
        property var layout: ({})           // {left:[], center:[], right:[]}; empty = defaults
        property var hidden: []             // widget ids removed from the bar
        property string trayTint: "accent"  // off | mono | accent — recolor tray icons to the theme
        property bool tintTasks: false      // same for window buttons
        property string taskRightClick: "menu" // menu (window menu with Close) | close (closes at once) | none
        property bool taskMiddleClose: true // middle click on a window button closes the window
        property bool taskHoverClose: false // × on the hovered window button
    }

    property JsonObject wallpaper: JsonObject {
        property string dir: "~/Pictures"
        property string fallback: ""
        property var outputs: ({})          // "DP-1" -> path
        property var workspaces: ({})       // "DP-1:2" -> path
        property string transition: "mosaic-dither" // mosaic-dither | mosaic | dither | none (only when the picture changes)
        property int duration: 750
        property int maxBlock: 48
    }

    property JsonObject workspaces: JsonObject {
        property string popupMode: "bar"    // bar (flash next to the hearts) | window | off
        property string popupPosition: "bottom-center"
        property bool indicator: false      // heart strip on the right edge
        property int popupMs: 650
        property bool phrases: true
        property string switchFx: "soft"    // soft | slide | bounce | teleport | pixel | heart | glitch | instant
        property string heartAnim: "smart"  // hearts/icons indicator: smart | collide | ender | hop | worm | pixel | beat | sparkle | drop | glitch | slide | off
        property var names: ({})            // "DP-1:1" -> "работа"
    }

    property JsonObject lyrics: JsonObject {
        property bool enabled: true         // current line in the middle of the bar
        property var screens: []            // empty = every bar
        property int offsetMs: 0
        property string artwork: "note"          // note | cover
        property bool typewriter: true
        property string preferPlayer: "spotify"
        property var sources: ["local", "player", "lrclib", "netease", "kugou", "qq", "ovh"] // tried in this order
        property int sourcesVersion: 0      // 2 = the list knows kugou/qq/local/player (older lists get them once)
    }

    property JsonObject setup: JsonObject {
        property bool complete: false
    }

    property JsonObject notifications: JsonObject {
        property bool dnd: false
        property int timeout: 6000
        property string screen: ""          // empty = focused output
        property string position: "top-right"
        property int maxPopups: 4
    }

    property JsonObject osd: JsonObject {
        property bool enabled: true
        property bool layout: true          // show keyboard layout switches
        property string position: "bottom-center"
        property int ms: 900
    }

    property JsonObject desktop: JsonObject {
        property var widgets: []            // [{uid, type, screen, x, y, settings}]; x/y < 0 = from the right/bottom
        property bool initialized: false
        property bool snap: true
        property string titleSuffix: "exe"  // widget titles end in .exe | .sh | .bin
    }

    property JsonObject voxtype: JsonObject {
        property string indicator: "angelos" // angelos | classic (old GTK circle) | off
        property string position: "bottom-center"
    }

    property JsonObject launcher: JsonObject {
        property string terminal: "kitty"
        property var usage: ({})            // desktop id -> launches
    }

    property JsonObject lock: JsonObject {
        property int idleMinutes: 0         // 0 = never lock automatically
        property bool onSleep: true         // lock before suspend/hibernate (logind), so waking up shows the lock
        property bool pixelate: true
        property bool hearts: true          // floating pixel hearts
        property bool reactions: true       // hearts on typing, a broken heart on a mistake, a burst on unlock
        property bool indicators: true      // Caps Lock, layout, battery, time locked, missed notifications
        property bool stream: false         // NGO stream overlay: LIVE badge, viewers, cute chat
        property string streamTitle: ""      // "" = "angel is on a break" 
    }

    property JsonObject idle: JsonObject {
        property int minutes: 0             // start the idle screen after N idle minutes; 0 = by hand only
        property string text: ""            // "" = angelOS ASCII art
        property string effect: "random"    // random | decrypt | rain | beams | wave | typewriter | hearts | glitch
        property string colors: "accent"    // accent | mono | rainbow
        property bool clock: true
        property bool allScreens: true
    }

    property JsonObject sidebar: JsonObject {
        property bool enabled: false        // experimental
        property string screen: ""          // "" = first screen
        property string edge: "right"       // left | right | top | bottom — where the tab sits
        property real offset: 0.5           // tab position along that edge, 0..1
        property var sections: ["toggles", "media", "sound", "system", "ai"]
    }

    property JsonObject capture: JsonObject {
        property string skin: "ropes"       // ropes | window | stream — region selector and recording overlay
        property bool themeColors: false    // NGO skins in the angelOS theme instead of the NGO palette
    }

    property JsonObject plugins: JsonObject {
        property var enabled: ({})          // id -> bool (missing = manifest default)
        property var data: ({})             // id -> plugin settings object
    }

    property JsonObject dotfiles: JsonObject {
        property string repo: "~/AngelOS-Dotfiles"
        property string command: "./install.sh"
        property string env: "DOTFILES_MODE=full SKIP_PACKAGES=1 INSTALL_VOXTYPE=0 DOWNLOAD_VOXTYPE_MODEL=0 ENABLE_SERVICES=0"
        property bool reloadNiri: true
    }

    property JsonObject system: JsonObject {
        property string terminal: "kitty"
        property string fileManager: "nautilus"
        property string monitor: "auto"
        property string monitorProgram: ""
        property bool monitorInTerminal: false
        property bool monitorFloat: true    // the task manager opens as a floating window (niri rule)
        property string monitorSize: "medium" // compact | medium | large | tall | custom
        property int monitorWidth: 1200     // custom size, logical px
        property int monitorHeight: 760
        property string monitorPlace: "center" // center | corner (bottom-right, next to the tray)
        property bool nautilusDefaults: false // angelOS Nautilus extensions + prefs applied once
    }

    property JsonObject cursor: JsonObject {
        property string theme: ""           // "" = leave the system cursor alone
        property int size: 24
        property bool flatpak: true         // also hand the theme to Flatpak apps
    }

    property JsonObject updates: JsonObject {
        property string repo: ""            // "" = found automatically (installer marker, ~/AngelOS-Dotfiles)
        property bool autoCheck: true       // look for updates once a day, never installs by itself
        property string lastCheck: ""
        property int available: 0
    }

    property JsonObject network: JsonObject {
        property bool showWifi: true        // bar/sidebar Wi-Fi indicator when a Wi-Fi adapter exists
        property bool showBluetooth: true
    }

    property JsonObject y2k: JsonObject {
        property bool helper: true          // the pixel angel in a screen corner
        property string helperScreen: ""   // "" = the main screen
        property string helperTips: "rare" // off | rare | often
        property bool helperGreeted: false
        property bool sparkles: true        // sparkle trail over the bare desktop
        property var sparkleScreens: []     // empty = every screen
        property bool sounds: true
        property real soundVolume: 0.55
        property var soundOff: ["click"]    // events kept quiet: startup notify error click shutdown angel
        property bool boot: true            // CD-ROM style loading screen once per login
        property var bootScreens: []        // empty = every screen
        property string soundPack: "y2k"    // y2k (synthesised here) | overdose (NEEDY GIRL OVERDOSE sounds, downloaded on first use)
        property bool cuteSounds: true      // overdose pack: little sounds on cute actions (Start, toggles, screenshots…)
        // angel ↔ demon (services/Angel): who lives in the corner
        property string character: "angel"  // angel | demon
        property double demonSince: 0       // ms; the demon arrived
        property var pleas: []              // ms of the lucky "come back, angel" pleas; 3 within 2 h bring her back
        property double lastPlea: 0         // pleas count once per 10 minutes
        property var pranks: []             // the demon's pranks this round [{id, key, old, new, at, undone}]; each shows off a feature
        property var seenTips: []           // settings pages whose first-visit tip the angel already told
        property double nextPrank: 0        // ms; not before
        property string cracks: "full"      // the demon's broken screen corner: full | weak | off
        property bool heavenFx: true        // sun rays and a choir when the angel comes back
        property string textShake: "light"  // the helper's letters twitch now and then: off | light | strong
        property string hellStyle: "pack"   // the demon's wallpaper: pack (pixel paintings, Hell pack) | drawn
        property bool shake: true           // the angel ↔ demon swap shakes the screen (the demon brings 8-bit rocks)
        property bool hellWallpaper: true   // the demon brings dark wallpaper, the angel gives yours back
        property string hellPicture: ""     // "" = generated pixel hell (scripts/hell-wallpaper.py)
        property var angelSaved: null       // wallpaper + theme mode kept while the demon rules
        property bool jokes: true           // she jokes now and then, not only tips
    }

    property JsonObject stream: JsonObject {
        property bool auto: true            // follow OBS: stream mode while OBS streams (obs-websocket)
        property bool manual: false         // stream mode by hand (button, `angelos stream on`)
        property int port: 4455             // obs-websocket port (OBS → Tools → WebSocket Server Settings)
        property var screens: []            // the streamed screens; empty = every screen
        property bool hideAngel: true       // the angel leaves the streamed screens (or hides)
        property bool mute: true            // angelOS sounds stay quiet
        property bool dnd: true             // Do not disturb while live
        property bool effects: true         // no sparkles, loading screen or angel/demon effects on the streamed screens
        property bool dndSet: false         // stream mode switched DND on (switched off again when the stream ends)
    }

    property JsonObject settingsUi: JsonObject {
        property bool expert: false         // false: home tiles, main settings only; true: every page in a sidebar
        property var usage: ({})            // page id -> visits; "Everyday" on the home page follows it
    }

    property JsonObject developer: JsonObject {
        property bool enabled: false
        property string provider: "claude-cli" // claude-cli | codex-cli (browser login) | openai | anthropic (API key)
        property string openaiModel: "gpt-5.4"
        property string anthropicModel: "claude-opus-5-5"
        property string claudeCliModel: "sonnet" // "" = the CLI default; aliases: haiku / sonnet / opus / fable
        property string codexCliModel: ""
        property var efforts: ({})          // provider -> low | medium | high | xhigh | max | ultra ("" = model default)
        property int autoRepair: 1          // automatic repair rounds after failed checks (0–2)
        property int maxOutputTokens: 32000
    }
}
