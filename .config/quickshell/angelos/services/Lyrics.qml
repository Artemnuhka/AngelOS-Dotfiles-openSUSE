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

    // Wakes up right before the next line is due instead of polling at a fixed
    // 80 ms; the 250 ms ceiling still picks up seeks quickly.
    Timer {
        interval: 80
        repeat: true
        running: root.playing && root.status === "ok" && root.lines.length > 0
        onTriggered: {
            root.player.positionChanged();
            root.updateIndex();
            const next = root.index + 1 < root.lines.length ? root.lines[root.index + 1].t : -1;
            interval = next > root.position ? Math.max(30, Math.min(250, Math.round((next - root.position) * 1000))) : 250;
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

    property string source: ""          // lrclib | NetEase | lyrics.ovh
    function apply(data) {
        source = data && data.source ? data.source : "";
        plainText = data && data.plainLyrics ? String(data.plainLyrics) : "";
        if (!data) {
            lines = [];
            status = _offline ? "error" : "notfound";
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
            status = _offline ? "error" : "notfound";
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

    // ---- what to search for ----
    readonly property bool fromBrowser: !!player && /firefox|chrom|brave|vivaldi|helium|zen|edge|opera|librewolf|browser|yandex/i.test((player.identity || "") + " " + (player.desktopEntry || ""))
    readonly property var cleaned: clean(title, artist)
    readonly property var sources: Config.lyrics.sources && Config.lyrics.sources.length ? Config.lyrics.sources : ["lrclib", "netease", "ovh"]

    // "Artist - Song (Official Video) [4K]" from a browser or YouTube → {artist, title}
    function clean(t, a) {
        t = String(t || "");
        a = String(a || "");
        const noise = /\s*[\(\[【]\s*(?:official\s*)?(?:music\s*)?(?:video|audio|lyrics?(?:\s*video)?|visuali[sz]er|mv|m\/v|hd|hq|4k|live|clip(?:\s*officiel)?|videoclip|премьера[^\)\]】]*|клип|текст(?:\s*песни)?|official)\s*[\)\]】]/gi;
        t = t.replace(noise, "").replace(/\s*[|｜].*$/, "").replace(/\s+(?:4k|hd|hq|mv|m\/v)\s*$/i, "").trim();
        a = a.replace(/\s*-\s*Topic$/i, "").replace(/VEVO$/i, "").replace(/\s+(?:official|официальный)$/i, "").trim();
        const m = t.match(/^(.+?)\s+[-–—]\s+(.+)$/);
        if (m) {
            const left = m[1].trim(), right = m[2].trim();
            if (/\b(?:remaster(?:ed)?|remix|version|edit|mix|live|mono|stereo|acoustic|instrumental|sped up|slowed)\b/i.test(right) && a && !fromBrowser)
                t = left;          // "Song - Remastered 2011"
            else if (!a || fromBrowser || left.toLowerCase().includes(a.toLowerCase()) || a.toLowerCase().includes(left.toLowerCase())) {
                a = left;          // "Artist - Song" (channel name as the artist)
                t = right;
            }
        }
        t = t.replace(/\s*[\(\[](?:feat|ft)\.?\s[^\)\]]*[\)\]]/gi, "").replace(/\s+(?:feat|ft)\.\s.*$/i, "").trim();
        return {
            "title": t || String(title || ""),
            "artist": a
        };
    }
    function similar(x, y) {
        const n = s => String(s || "").toLowerCase().replace(/[\s.,'"’`!?¿¡()\[\]{}\-–—:;&/\\*+~_«»]+/g, "");
        const a = n(x), b = n(y);
        return !!a && !!b && (a === b || a.includes(b) || b.includes(a));
    }

    // NetEase LRC starts with credit lines ("作词 : …"); drop them
    function stripCredits(lrc) {
        return String(lrc || "").split("\n").filter(l => !/^\s*\[\d+:\d+(?:[.:]\d+)?\]\s*[^\[\]]{1,24}\s[:：]\s/.test(l) || !/作|曲|词|编|制作|混音|录音|Producer|Lyricist|Composer/i.test(l)).join("\n");
    }

    // ---- source chain: lrclib exact → lrclib search → lrclib free text → NetEase → lyrics.ovh ----
    function fetchNet(key) {
        const c = cleaned, d = length;
        const steps = [];
        let plain = null;       // best unsynced text met on the way
        const finish = data => {
            if (key !== _pendingKey)
                return;
            if (data) {
                store(key, data);
                apply(data);
            } else if (plain) {
                store(key, plain);
                apply(plain);
            } else {
                root._mem[key] = null;   // not found: remember for this session only
                apply(null);
            }
        };
        const next = () => {
            if (key !== _pendingKey)
                return;
            const step = steps.shift();
            if (step)
                step();
            else
                finish(null);
        };
        const pickLrclib = list => {
            if (!Array.isArray(list))
                return null;
            const synced = list.filter(r => r.syncedLyrics && (!d || !r.duration || Math.abs(r.duration - d) < 12)).sort((x, y) => Math.abs((x.duration || 0) - d) - Math.abs((y.duration || 0) - d));
            if (!plain)
                plain = list.find(r => r.plainLyrics) || null;
            return synced[0] || null;
        };
        const base = "https://lrclib.net/api/";
        if (sources.includes("lrclib")) {
            steps.push(() => http(base + "get?" + query({
                    "track_name": c.title,
                    "artist_name": c.artist,
                    "album_name": fromBrowser ? "" : album,
                    "duration": d > 0 ? Math.round(d) : ""
                }), (code, body) => {
                if (code === 200 && body && (body.syncedLyrics || body.instrumental))
                    return finish(Object.assign({
                        "source": "lrclib"
                    }, body));
                if (code === 0)
                    root._offline = true;
                if (body && body.plainLyrics && !plain)
                    plain = Object.assign({
                        "source": "lrclib"
                    }, body);
                next();
            }));
            steps.push(() => http(base + "search?" + query({
                    "track_name": c.title,
                    "artist_name": c.artist
                }), (code, list) => {
                const best = pickLrclib(list);
                best ? finish(Object.assign({
                    "source": "lrclib"
                }, best)) : next();
            }));
            steps.push(() => http(base + "search?" + query({
                    "q": (c.artist + " " + c.title).trim()
                }), (code, list) => {
                const best = pickLrclib(Array.isArray(list) ? list.filter(r => similar(r.trackName, c.title)) : list);
                best ? finish(Object.assign({
                    "source": "lrclib"
                }, best)) : next();
            }));
        }
        if (sources.includes("netease"))
            steps.push(() => http("https://music.163.com/api/cloudsearch/pc?" + query({
                    "s": (c.title + " " + c.artist).trim(),
                    "type": 1,
                    "limit": 8
                }), (code, body) => {
                const songs = body && body.result && body.result.songs ? body.result.songs : [];
                const match = songs.filter(x => similar(x.name, c.title) && (!d || !x.dt || Math.abs(x.dt / 1000 - d) < 8)).sort((x, y) => (similar((y.ar || []).map(a => a.name).join(" "), c.artist) ? 1 : 0) - (similar((x.ar || []).map(a => a.name).join(" "), c.artist) ? 1 : 0))[0];
                if (!match)
                    return next();
                http("https://music.163.com/api/song/lyric?id=" + match.id + "&lv=1", (code2, lyr) => {
                    const lrc = lyr && lyr.lrc ? root.stripCredits(lyr.lrc.lyric) : "";
                    if (/\[\d+:\d+/.test(lrc))
                        finish({
                            "source": "NetEase",
                            "syncedLyrics": lrc,
                            "trackName": match.name,
                            "duration": (match.dt || 0) / 1000
                        });
                    else
                        next();
                });
            }));
        if (sources.includes("ovh"))
            steps.push(() => {
                if (plain || !c.artist)
                    return next();
                http("https://api.lyrics.ovh/v1/" + encodeURIComponent(c.artist) + "/" + encodeURIComponent(c.title), (code, body) => {
                    if (body && body.lyrics && body.lyrics.trim())
                        plain = {
                            "source": "lyrics.ovh",
                            "plainLyrics": body.lyrics.trim()
                        };
                    next();
                });
            });
        _offline = false;
        next();
    }
    property bool _offline: false

    // ---- manual search from Settings → Lyrics ----
    property var results: []
    property bool searching: false
    function search(text) {
        text = String(text || "").trim();
        if (!text)
            return;
        searching = true;
        results = [];
        let pending = 2;
        const out = [];
        const done = () => {
            if (--pending === 0) {
                searching = false;
                results = out;
            }
        };
        http("https://lrclib.net/api/search?" + query({
            "q": text
        }), (code, list) => {
            for (const r of (Array.isArray(list) ? list : []).slice(0, 12))
                out.push({
                    "source": "lrclib",
                    "title": r.trackName,
                    "artist": r.artistName,
                    "duration": r.duration || 0,
                    "synced": !!r.syncedLyrics,
                    "data": r
                });
            done();
        });
        http("https://music.163.com/api/cloudsearch/pc?" + query({
            "s": text,
            "type": 1,
            "limit": 8
        }), (code, body) => {
            for (const x of (body && body.result && body.result.songs ? body.result.songs : []))
                out.push({
                    "source": "NetEase",
                    "title": x.name,
                    "artist": (x.ar || []).map(a => a.name).join(", "),
                    "duration": (x.dt || 0) / 1000,
                    "synced": true,
                    "id": x.id
                });
            done();
        });
    }
    // use a search result for the current track (remembered in the cache)
    function pick(r) {
        const key = trackKey;
        if (!title || !r)
            return;
        if (r.data) {
            const data = Object.assign({
                "source": "lrclib"
            }, r.data);
            store(key, data);
            apply(data);
            return;
        }
        http("https://music.163.com/api/song/lyric?id=" + r.id + "&lv=1", (code, lyr) => {
            const lrc = lyr && lyr.lrc ? root.stripCredits(lyr.lrc.lyric) : "";
            if (!lrc || key !== trackKey)
                return;
            const data = /\[\d+:\d+/.test(lrc) ? {
                "source": "NetEase",
                "syncedLyrics": lrc
            } : {
                "source": "NetEase",
                "plainLyrics": lrc
            };
            store(key, data);
            apply(data);
        });
    }
}
