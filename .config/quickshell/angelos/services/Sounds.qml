pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// angelOS sounds, Settings → Y2K → Sounds. Two packs:
//   y2k       synthesised by scripts/y2k-sounds.py into ~/.local/share/angelos/sounds/y2k
//   overdose  NEEDY GIRL OVERDOSE (Windose) sounds, fetched on first use by
//             scripts/sound-pack.py into …/sounds/overdose
// Events: startup notify error click shutdown angel wallpaper, the "cute" ones
// (open toggle screenshot volume windowClose — Config.y2k.cuteSounds), the
// demon's voice, and the effects crack/choir/rocks/shatter (always synthesised;
// rocks: the demon's 8-bit rockfall, shatter: the screen breaking when the
// angel and the demon swap). Quiet in stream mode (StreamMode.quiet).
Singleton {
    id: root

    readonly property var events: ["startup", "notify", "error", "click", "shutdown", "angel", "wallpaper", "open", "toggle", "screenshot", "volume", "windowClose", "demon", "crack", "choir", "rocks", "shatter", "voice"]
    // the helper's Undertale "pips", one per letter (AngelHelper plays them as
    // SoundEffect, so they stay .wav); "voice" above is their switch and preview
    readonly property var extra: ["voiceAngel", "voiceDemon"]
    readonly property var cute: ["open", "toggle", "screenshot", "volume", "windowClose"]
    readonly property var effects: ["crack", "choir", "rocks", "shatter", "voice"]
    readonly property string base: Config.home + "/.local/share/angelos/sounds"
    readonly property string dir: base + "/y2k"
    readonly property string pack: Config.y2k.soundPack === "overdose" ? "overdose" : "y2k"
    property bool ready: false               // the synthesised pack is complete
    property bool overdoseReady: false
    property string overdoseError: ""
    readonly property bool downloading: fetch.running
    property var pending: []
    property var lastAt: ({})

    function enabled(name) {
        if (!Config.y2k.sounds || (Config.y2k.soundOff || []).includes(name))
            return false;
        return !cute.includes(name) || Config.y2k.cuteSounds;
    }
    // play even when switched off (the settings page "listen" buttons)
    function preview(name) {
        _play(name, true);
    }
    function play(name) {
        if (enabled(name) && !StreamMode.quiet)
            _play(name, false);
    }
    function _play(name, force) {
        if (!events.includes(name))
            return;
        // a burst of the same event (volume wheel, many toggles) plays once
        const now = Date.now();
        if (!force && now - (lastAt[name] || 0) < (name === "volume" ? 140 : 90))
            return;
        lastAt[name] = now;
        if (!ready) {
            pending = pending.concat([name]);
            make.running = true;
            return;
        }
        const overdose = pack === "overdose" && !effects.includes(name);
        if (overdose && !overdoseReady && !fetch.running) {
            fetch.running = true;
            return;
        }
        const first = overdose ? base + "/overdose" : dir;
        Quickshell.execDetached(["sh", "-c", 'f="$1/$3.ogg"; [ -f "$f" ] || f="$2/$3.ogg"; [ -f "$f" ] || f="$2/$3.wav"; exec pw-play --volume "$4" "$f"', "sh", first, dir, name, String(Math.max(0, Math.min(1, Config.y2k.soundVolume)))]);
    }

    // the pack must be there before something plays it without _play() (the pips)
    function ensure() {
        if (!ready && !make.running)
            make.running = true;
    }

    // ---- the shell's own moments ----
    readonly property double startedAt: Date.now()
    function settled() {
        return Config.ready && Date.now() - startedAt > 5000;
    }
    // (Start opens silently)
    Connections {
        target: Shell
        function onLauncherOpenChanged() {
            if (Shell.launcherOpen)
                root.play("open");
        }
        function onSettingsOpenChanged() {
            if (Shell.settingsOpen)
                root.play("open");
        }
    }
    Connections {
        target: Niri
        function onWindowClosed(id) {
            root.play("windowClose");
        }
    }
    Connections {
        target: Audio
        function onVolumeChanged() {
            if (root.settled())
                root.play("volume");
        }
    }
    // every wallpaper change, not only the first (the angel only comments now and then)
    property double wallpaperQuietUntil: 0
    function quietWallpaper(ms) {
        wallpaperQuietUntil = Date.now() + ms;
    }
    readonly property string wallpaperKey: JSON.stringify([Config.wallpaper.fallback, Config.wallpaper.outputs, Config.wallpaper.workspaces])
    onWallpaperKeyChanged: if (settled() && Date.now() > wallpaperQuietUntil)
        wallpaperDebounce.restart()
    Timer {
        id: wallpaperDebounce
        interval: 200
        onTriggered: root.play("wallpaper")
    }

    // synthesise once if the pack is missing (or older than the event list)
    Process {
        id: check
        running: true
        command: ["sh", "-c", 'd="$1"; shift; for n in "$@"; do [ -f "$d/$n.ogg" ] || [ -f "$d/$n.wav" ] || exit 1; done', "sh", root.dir].concat(root.events).concat(root.extra)
        onExited: code => {
            if (code === 0)
                root.ready = true;
        }
    }
    Process {
        id: make
        command: ["python3", Quickshell.shellDir + "/scripts/y2k-sounds.py", root.dir]
        onExited: code => {
            if (code !== 0)
                return;
            root.ready = true;
            const p = root.pending;
            root.pending = [];
            for (const n of p.slice(-1))
                root._play(n, true);
        }
    }

    // the Windose pack: present already, or downloaded when picked
    Process {
        id: checkOverdose
        running: root.pack === "overdose"
        command: ["sh", "-c", '[ -f "$1/notify.ogg" ] && [ -f "$1/startup.ogg" ]', "sh", root.base + "/overdose"]
        onExited: code => {
            root.overdoseReady = code === 0;
            if (code !== 0 && root.pack === "overdose" && !fetch.running)
                fetch.running = true;
        }
    }
    Process {
        id: fetch
        command: ["python3", Quickshell.shellDir + "/scripts/sound-pack.py", "overdose", root.base + "/overdose"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text);
                    root.overdoseError = Object.keys(r.failed || {}).length ? I18n.t("не скачались: ", "failed: ") + Object.keys(r.failed).join(", ") : "";
                } catch (e) {
                    root.overdoseError = I18n.t("нет сети или GitHub недоступен", "no network or GitHub is down");
                }
            }
        }
        onExited: code => {
            root.overdoseReady = code === 0;
            if (code === 0)
                root.play("angel");
        }
    }
}
