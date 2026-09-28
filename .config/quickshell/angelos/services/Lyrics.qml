pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.config

// Synced lyrics for the current MPRIS track, fetched from lrclib.net and cached on disk.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var player: {
        const pref = (Config.lyrics.preferPlayer || "").toLowerCase();
        const match = p => pref && ((p.identity || "").toLowerCase().includes(pref) || (p.desktopEntry || "").toLowerCase().includes(pref) || (p.dbusName || "").toLowerCase().includes(pref));
        return players.find(p => p.isPlaying && match(p)) || players.find(p => p.isPlaying) || players.find(match) || players[0] || null;
    }
    readonly property bool playing: !!player && player.isPlaying
    readonly property string title: player ? player.trackTitle || "" : ""
    readonly property string artist: player ? player.trackArtist || "" : ""
    readonly property string artUrl: player ? player.trackArtUrl || "" : ""
    readonly property string album: player ? player.trackAlbum || "" : ""
    readonly property real length: player && player.lengthSupported ? player.length : 0
    readonly property string trackKey: artist + "\u0001" + title

    property string plainText: ""
    property var lines: []          // [{t, text}] sorted
    property string status: "idle"  // idle | loading | ok | plain | instrumental | notfound | error
    property int index: -1
    property real position: 0
    // Plain lyrics have no timing: display a first-line preview in the bar
    // and the complete text on the Lyrics settings page.
    readonly property bool hasLyrics: (status === "ok" || status === "plain") && lines.length > 0
    readonly property string current: index >= 0 && index < lines.length ? lines[index].text : ""
    readonly property string previous: index > 0 && index <= lines.length ? lines[index - 1].text : ""
    readonly property string next: index >= -1 && index + 1 < lines.length ? lines[index + 1].text : ""
    readonly property real lineStart: index >= 0 && index < lines.length ? lines[index].t : 0
    readonly property real lineEnd: index + 1 < lines.length ? lines[index + 1].t : length
    property bool visibleToggle: true

    property var _mem: ({})
    property string _pendingKey: ""

    onTrackKeyChanged: fetchTimer.restart()

    // track metadata often arrives in pieces; wait for it to settle
    Timer {
        id: fetchTimer
        interval: 350
        onTriggered: root.fetch()
    }

    Timer {
        interval: 80
        repeat: true
        running: root.playing && root.hasLyrics
        onTriggered: {
            root.player.positionChanged();
            root.updateIndex();
        }
    }

    Connections {
        target: root.player
        ignoreUnknownSignals: true
        function onPostTrackChanged() {
            root.index = -1;
        }
        function onPlaybackStateChanged() {
            if (root.player) {
                root.player.positionChanged();
                root.updateIndex();
            }
        }
    }

    function updateIndex() {
        if (!player || lines.length === 0)
            return;
        position = player.position + Config.lyrics.offsetMs / 1000;
        let i = index;
        if (i < 0 || i >= lines.length || lines[i].t > position)
            i = -1;
        while (i + 1 < lines.length && lines[i + 1].t <= position)
            i++;
        if (i !== index)
            index = i;
    }

    function cacheFile(key) {
        let h = 0;
        for (let i = 0; i < key.length; i++)
            h = (h * 31 + key.charCodeAt(i)) | 0;
        const safe = key.replace(/[\/\\:*?"<>|\s\u0001.]+/g, "_").slice(0, 60);
        return Config.cacheDir + "/lyrics/" + safe + "_" + (h >>> 0).toString(16) + ".json";
    }

    function parseLrc(text) {
        const out = [];
        for (const raw of (text || "").split("\n")) {
            const stamps = [];
            let rest = raw;
            let m;
            const re = /^\s*\[(\d+):(\d+(?:[.:]\d+)?)\]/;
            while ((m = rest.match(re))) {
                stamps.push(parseInt(m[1]) * 60 + parseFloat(m[2].replace(":", ".")));
                rest = rest.slice(m[0].length);
            }
            for (const t of stamps)
                out.push({
                    "t": t,
                    "text": rest.trim()
                });
        }
        return out.sort((a, b) => a.t - b.t);
    }

    function apply(data) {
        plainText = data && data.plainLyrics ? String(data.plainLyrics) : "";
        if (!data) {
            lines = [];
            status = "notfound";
        } else if (data.instrumental) {
            lines = [];
            status = "instrumental";
        } else if (data.syncedLyrics) {
            lines = parseLrc(data.syncedLyrics);
            status = lines.length ? "ok" : "notfound";
        } else if (data.plainLyrics) {
            lines = [
                {
                    "t": 0,
                    "text": (plainText.split("\n").find(l => l.trim() !== "") || "").trim()
                }
            ];
            status = "plain";
        } else {
            lines = [];
            status = "notfound";
        }
        index = -1;
        if (player)
            updateIndex();
    }

    // bypass caches (memory + disk) for the current track
    function refetch() {
        if (!title)
            return;
        delete _mem[trackKey];
        lines = [];
        index = -1;
        status = "loading";
        _pendingKey = trackKey;
        fetchNet(trackKey);
    }

    function fetch() {
        plainText = "";
        lines = [];
        index = -1;
        if (!title) {
            status = "idle";
            return;
        }
        const key = trackKey;
        _pendingKey = key;
        if (_mem[key] !== undefined) {
            apply(_mem[key]);
            return;
        }
        status = "loading";
        diskReader.key = key;
        diskReader.path = cacheFile(key);
        diskReader.reload();
    }

    FileView {
        id: diskReader
        property string key: ""
        printErrors: false
        onLoaded: {
            if (key !== root._pendingKey)
                return;
            try {
                const data = JSON.parse(text());
                root._mem[key] = data;
                root.apply(data);
            } catch (e) {
                root.fetchNet(key);
            }
        }
        onLoadFailed: if (key === root._pendingKey)
            root.fetchNet(key)
    }

    FileView {
        id: diskWriter
        preload: false
        atomicWrites: true
        printErrors: false
    }

    function store(key, data) {
        _mem[key] = data;
        diskWriter.path = cacheFile(key);
        diskWriter.setText(JSON.stringify(data));
    }

    function query(params) {
        return Object.keys(params).filter(k => params[k] !== "" && params[k] !== undefined).map(k => k + "=" + encodeURIComponent(params[k])).join("&");
    }

    function http(url, cb) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            let body = null;
            try {
                body = xhr.status === 200 ? JSON.parse(xhr.responseText) : null;
            } catch (e) {}
            cb(xhr.status, body);
        };
        xhr.open("GET", url);
        xhr.setRequestHeader("User-Agent", "angelOS-quickshell (https://github.com/MixaDoDs)");
        xhr.send();
    }

    function fetchNet(key) {
        const t = title, a = artist, al = album, d = length;
        const base = "https://lrclib.net/api/";
        http(base + "get?" + query({
            "track_name": t,
            "artist_name": a,
            "album_name": al,
            "duration": d > 0 ? Math.round(d) : ""
        }), (code, body) => {
            if (key !== _pendingKey)
                return;
            if (code === 200 && body && (body.syncedLyrics || body.instrumental)) {
                store(key, body);
                apply(body);
                return;
            }
            // fuzzy fallback: search and prefer synced results with a close duration
            http(base + "search?" + query({
                "track_name": t,
                "artist_name": a
            }), (code2, list) => {
                if (key !== _pendingKey)
                    return;
                if (code2 !== 200 || !Array.isArray(list)) {
                    status = code2 === 0 ? "error" : "notfound";
                    return;
                }
                const scored = list.filter(r => r.syncedLyrics).sort((x, y) => Math.abs((x.duration || 0) - d) - Math.abs((y.duration || 0) - d));
                const best = scored[0] || (body && body.plainLyrics ? body : null) || list[0] || null;
                if (best)
                    store(key, best);
                else
                    root._mem[key] = null; // not found: remember for this session only
                apply(best);
            });
        });
    }
}
