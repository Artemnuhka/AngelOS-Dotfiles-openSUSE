pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "../novel/NovelCore.js" as Core

// The novel: chapters the angel (or the demon) plays out on the desktop, written in the
// dialogue editor (`angelos novel edit`, novel/editor) into ~/AngelOs-Nov/story/*.json.
// The rules — node types, templates, conditions — are novel/NovelCore.js, shared with the
// editor's play-test. Shown by modules/novel (the dialogue box next to her, the crumpled
// paper on the desk, the unfolded note) and AngelHelper ("?" over her head).
//
// Two threads run a chapter: the main line (state.main) and a side thread for the pool's
// questions (state.side), each a node it is at and what it waits for: "" (run now), click
// (the user clicks her: the "?"), resume (the computer woke from sleep), at:<ms> (a time),
// show (she can't be shown right now: locked, streaming, fullscreen, hidden, the wrong
// one rules — tried again every few seconds), note (a paper waits to be read), line (the
// box is up, waiting for the user). After a "free" node the side thread now and then
// takes an unasked question from the pool (each once) and she drops notes (pools.drops).
// Progress lives in ~/.local/state/angelos/novel.json; `angelos novel reset` starts over.
Singleton {
    id: root

    readonly property string dir: Config.expand(Config.novel.dir || "~/AngelOs-Nov")
    readonly property bool enabled: Config.novel.enabled
    property var stories: ({})               // "chapter1" → story
    property var sprites: ({})               // "angel" → {"happy": "/…/sprites/angel/happy.png"}
    // the picture for a sprite name, "" when there is no such file (the box goes without it)
    function spriteFile(who, name) {
        const m = sprites[who] || {};
        return m[name || "neutral"] || "";
    }
    property bool loaded: false
    property var state: freshState()
    property bool stateLoaded: false

    // ---- what modules/novel shows ----
    // the box: {who, sprite, text, choices: [{text, tone}], thread} or null
    property var line: null
    // a crumpled paper on the desk: {from: desk|angel, title, text, thread} or null; noteOpen: unfolded
    property var paper: null
    property bool noteOpen: false
    readonly property bool wantsClick: enabled && canShow && (waitsFor("main") === "click" || waitsFor("side") === "click") && !line
    signal dropped                            // she let a note fall (the paper falls from her)

    function freshState() {
        return {
            "chapter": "",
            "vars": {},
            "seen": [],
            "asked": [],
            "done": {},
            "begun": {},
            "free": false,
            "nextQ": 0,
            "nextDrop": 0,
            "main": {
                "node": "",
                "wait": ""
            },
            "side": {
                "node": "",
                "wait": ""
            },
            "log": []
        };
    }
    function story() {
        return stories[state.chapter] || null;
    }
    function waitsFor(thread) {
        const t = state[thread];
        return t && t.node ? String(t.wait || "") : "";
    }

    // ---- may she show something now? ----
    readonly property bool canShow: {
        const st = stories[state.chapter];
        const who = st ? st.with || "angel" : "angel";
        return Angel.present && !Angel.transition && !Shell.locked && !Idle.active && !StreamMode.active && !Shell.hiddenScreen(Angel.screenName) && !Shell.fullscreenOn(Angel.screenName) && (who === "any" || (who === "demon") === Angel.demon);
    }

    // ---- text ----
    function ctx() {
        const w = Niri.focusedWindow;
        return {
            "vars": state.vars,
            "name": Config.novel.name || StartApps.userName,
            "app": w ? (Niri.titleOf(w) || w.app_id || "").replace(/ [—–-] .*$/, "") : "",
            "song": Lyrics.title || "",
            "now": new Date()
        };
    }
    function txt(s) {
        return Core.render(s, ctx());
    }

    // ---- the chapter ----
    function startChapter(id) {
        const st = stories[id];
        if (!st)
            return "no chapter " + id;
        const s = freshState();
        s.chapter = id;
        s.done = state.done || {};
        s.begun = Object.assign({}, state.begun || {});
        s.begun[id] = true;
        s.vars = Object.assign({}, st.vars || {}, {
            "setupGender": Config.novel.gender || "",
            "gender": (state.vars || {}).gender || ""
        });
        line = null;
        paper = null;
        noteOpen = false;
        state = s;
        go("main", st.start);
        return "ok";
    }
    // enter a node: it runs now or waits for its moment
    function go(thread, id) {
        const st = story();
        const s = Object.assign({}, state);
        const n = st && id ? st.nodes[id] : null;
        if (!n) {
            s[thread] = {
                "node": "",
                "wait": ""
            };
            state = s;
            save();
            return;
        }
        const when = n.when || "now";
        let wait = "";
        if (when === "click")
            wait = "click";
        else if (when === "resume")
            wait = "resume";
        else if (/^minutes:\d+$/.test(when))
            wait = "at:" + (Date.now() + parseInt(when.slice(8)) * 60000);
        s[thread] = {
            "node": id,
            "wait": wait
        };
        state = s;
        save();
        if (!wait)
            run(thread);
    }
    function setWait(thread, wait) {
        const s = Object.assign({}, state);
        s[thread] = Object.assign({}, s[thread], {
            "wait": wait
        });
        state = s;
        save();
    }
    function remember(id) {
        if (state.seen.indexOf(id) < 0) {
            const s = Object.assign({}, state);
            s.seen = s.seen.concat([id]);
            state = s;
        }
    }
    function setVars(set) {
        if (!set)
            return;
        const s = Object.assign({}, state);
        s.vars = Core.applySet(s.vars, set);
        state = s;
    }
    // run the node a thread is at (its moment has come)
    function run(thread) {
        const st = story();
        const id = state[thread].node;
        const n = st && id ? st.nodes[id] : null;
        if (!n)
            return go(thread, "");
        if (!canShow && ["say", "choice", "note"].indexOf(n.type) >= 0) {
            setWait(thread, "show");
            return;
        }
        remember(id);
        switch (n.type) {
        case "event":
            return go(thread, n.next);
        case "say":
            setWait(thread, "line");
            Angel.hush();
            line = {
                "who": n.who || "angel",
                "sprite": n.sprite || "neutral",
                "text": txt(n.text),
                "choices": [],
                "thread": thread
            };
            return;
        case "choice":
            setWait(thread, "line");
            Angel.hush();
            line = {
                "who": n.who || "angel",
                "sprite": n.sprite || "neutral",
                "text": txt(n.text),
                "choices": (n.choices || []).map(c => ({
                            "text": txt(c.text),
                            "tone": c.tone || "neutral"
                        })),
                "thread": thread
            };
            return;
        case "note":
            setWait(thread, "note");
            paper = {
                "from": n.from || "desk",
                "title": txt(n.title || ""),
                "text": txt(n.text || ""),
                "thread": thread
            };
            if (paper.from === "angel")
                dropped();
            return;
        case "set":
            setVars(n.set);
            return go(thread, n.next);
        case "if":
            {
                let ok = false;
                try {
                    ok = Core.evalCond(n.cond, state.vars, state.seen);
                } catch (e) {
                    console.warn("novel: if", id, e.message);
                }
                return go(thread, ok ? n.then : n["else"]);
            }
        case "random":
            {
                const list = (Array.isArray(n.next) ? n.next : [n.next]).filter(x => !!x);
                return go(thread, list[Math.floor(Math.random() * list.length)] || "");
            }
        case "free":
            {
                const s = Object.assign({}, state);
                s.free = true;
                s.nextQ = Date.now() + rangeMs((st.ambient || {}).questions, 25, 70);
                s.nextDrop = Date.now() + rangeMs((st.ambient || {}).drops, 30, 90);
                state = s;
                return go(thread, n.next);
            }
        case "end":
            {
                const s = Object.assign({}, state);
                s.done = Object.assign({}, s.done);
                s.done[s.chapter] = true;
                state = s;
                go(thread, "");
                // the next chapter starts the way its own event says
                if (n.chapter && stories[n.chapter])
                    pendingChapter = n.chapter;
                return;
            }
        }
        go(thread, n.next);
    }
    property string pendingChapter: ""
    function rangeMs(r, a, b) {
        const lo = Math.max(1, (r && r[0]) || a), hi = Math.max(lo, (r && r[1]) || b);
        return (lo + Math.random() * (hi - lo)) * 60000;
    }

    // ---- the user ----
    // the box was clicked / Enter: the line goes on (a question waits for its answer)
    function advance() {
        if (!line || line.choices.length)
            return;
        const thread = line.thread;
        line = null;
        if (_after !== null) {
            const to = _after;
            _after = null;
            return go(thread, to);
        }
        const n = story() ? story().nodes[state[thread].node] : null;
        go(thread, n ? n.next : "");
    }
    property var _after: null                 // where a reply line leads
    function choose(i) {
        if (!line || i < 0 || i >= line.choices.length)
            return;
        const thread = line.thread;
        const n = story() ? story().nodes[state[thread].node] : null;
        const c = n && n.choices ? n.choices[i] : null;
        if (!c)
            return;
        log(state[thread].node, i);
        setVars(c.set);
        if (c.reply && c.reply.text) {
            _after = c.next || "";
            line = {
                "who": c.reply.who || n.who || "angel",
                "sprite": c.reply.sprite || "neutral",
                "text": txt(c.reply.text),
                "choices": [],
                "thread": thread
            };
            return;
        }
        line = null;
        go(thread, c.next || "");
    }
    function log(node, choice) {
        const s = Object.assign({}, state);
        s.log = (s.log || []).concat([{
                    "at": Date.now(),
                    "node": node,
                    "choice": choice
                }]).slice(-200);
        state = s;
    }
    // a click on her: true when the story took it (AngelHelper then opens no menu)
    function click() {
        if (!enabled || !canShow || line)
            return false;
        for (const th of ["main", "side"])
            if (waitsFor(th) === "click") {
                run(th);
                return true;
            }
        return false;
    }
    // the paper was unfolded and folded again
    function noteRead() {
        const p = paper;
        noteOpen = false;
        paper = null;
        if (p && p.thread) {
            const n = story() ? story().nodes[state[p.thread].node] : null;
            go(p.thread, n ? n.next : "");
        }
    }
    // the computer woke up: chapters that begin after sleep, nodes that wait for it
    function resumed() {
        if (!enabled)
            return;
        reload();
        resumeSoon.restart();
    }
    Timer {
        id: resumeSoon
        interval: 4000
        onTriggered: {
            for (const th of ["main", "side"])
                if (root.waitsFor(th) === "resume")
                    root.run(th);
            if (!root.state.main.node && !root.line)
                root.maybeStart("resume");
        }
    }
    // a chapter not begun yet whose event fits starts (one at a time); `end` can name the
    // next one (pendingChapter), which then starts on its own event
    function triggerOf(id) {
        const st = stories[id];
        const n = st && st.nodes ? st.nodes[st.start] : null;
        return n && n.type === "event" ? n.trigger || "manual" : "manual";
    }
    function maybeStart(trigger) {
        if (state.main.node || line)
            return false;
        const begun = state.begun || {};
        let want = "";
        if (pendingChapter && stories[pendingChapter])
            want = triggerOf(pendingChapter) === trigger ? pendingChapter : "";
        else
            want = Object.keys(stories).sort().find(id => !begun[id] && triggerOf(id) === trigger) || "";
        if (!want)
            return false;
        pendingChapter = "";
        startChapter(want);
        return true;
    }

    // ---- the clock: timed nodes, retries, the pool ----
    Timer {
        interval: 5000
        running: root.enabled && root.loaded && root.stateLoaded
        repeat: true
        onTriggered: root.tick()
    }
    property double _lastTick: Date.now()
    function tick() {
        const now = Date.now();
        // a jump of the wall clock: the machine slept (also told by Lock via Shell.resumed)
        if (now - _lastTick > 90000)
            resumed();
        _lastTick = now;
        if (!story())
            return;
        for (const th of ["main", "side"]) {
            const w = waitsFor(th);
            if (w.startsWith("at:") && now >= parseInt(w.slice(3)))
                run(th);
            else if (w === "show" && canShow && !line && !paper)
                run(th);
        }
        if (!state.free || !canShow || line || paper)
            return;
        const st = story();
        // a question from the pool, each once; the "?" waits for a click
        if (!state.side.node && now >= state.nextQ && waitsFor("main") !== "click") {
            const left = ((st.pools || {}).questions || []).filter(q => state.asked.indexOf(q) < 0 && st.nodes[q]);
            const s = Object.assign({}, state);
            s.nextQ = now + rangeMs((st.ambient || {}).questions, 25, 70);
            if (left.length) {
                const q = left[Math.floor(Math.random() * left.length)];
                s.asked = s.asked.concat([q]);
                state = s;
                go("side", q);
                if (waitsFor("side") === "click")
                    Angel.say(I18n.t("Эй… можно спросить? Нажми на меня ♡", "Hey… can I ask you something? Click me ♡"), null, 7000);
            } else {
                state = s;
            }
            save();
            return;
        }
        // a note falls from her
        if (now >= state.nextDrop) {
            const drops = ((st.pools || {}).drops || []);
            const s = Object.assign({}, state);
            s.nextDrop = now + rangeMs((st.ambient || {}).drops, 30, 90);
            state = s;
            save();
            if (drops.length) {
                const d = drops[Math.floor(Math.random() * drops.length)];
                paper = {
                    "from": "angel",
                    "title": "",
                    "text": txt(d.text),
                    "thread": ""
                };
                dropped();
            }
        }
    }

    // ---- files: the chapters, and the progress ----
    function reload() {
        loader.running = false;
        loader.running = true;
    }
    Process {
        id: loader
        // the chapters and the sprite files in one go: {stories: {id: story}, sprites: {who: {name: path}}}
        command: ["python3", "-c", "import json,sys,pathlib\nb=pathlib.Path(sys.argv[1])\nd=b/'story'\nout={}\nfor f in sorted(d.glob('*.json')) if d.is_dir() else []:\n    try: out[f.stem]=json.loads(f.read_text())\n    except Exception as e: print('novel: '+f.name+': '+str(e),file=sys.stderr)\nsp={}\nfor w in sorted((b/'sprites').iterdir()) if (b/'sprites').is_dir() else []:\n    if w.is_dir():\n        m={}\n        for f in sorted(w.iterdir()):\n            if f.suffix.lower() in ('.png','.webp','.gif','.jpg','.jpeg'): m.setdefault(f.stem,str(f))\n        sp[w.name]=m\nprint(json.dumps({'stories':out,'sprites':sp}))", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text || "{}");
                    root.stories = d.stories || {};
                    root.sprites = d.sprites || {};
                } catch (e) {
                    root.stories = {};
                }
                const first = !root.loaded;
                root.loaded = true;
                if (first)
                    root.started();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text)
                console.warn(text.trim())
        }
    }
    // the shell started: a chapter waiting for "start", or one cut off mid-line goes on
    function started() {
        if (!enabled || !stateLoaded)
            return;
        for (const th of ["main", "side"]) {
            const w = waitsFor(th);
            // the box or a paper was up when the shell went down: show it again
            if (w === "line" || w === "note" || w === "show")
                setWait(th, "show");
        }
        if (!state.main.node)
            maybeStart("start");
    }
    readonly property string stateFile: Config.home + "/.local/state/angelos/novel.json"
    FileView {
        id: stateView
        path: root.stateFile
        atomicWrites: true
        printErrors: false
        onLoaded: {
            try {
                root.state = Object.assign(root.freshState(), JSON.parse(text()));
            } catch (e) {}
            root.stateLoaded = true;
            if (root.loaded)
                root.started();
        }
        onLoadFailed: {
            root.stateLoaded = true;
            if (root.loaded)
                root.started();
        }
    }
    function save() {
        saveSoon.restart();
    }
    Timer {
        id: saveSoon
        interval: 400
        onTriggered: stateView.setText(JSON.stringify(root.state, null, 1))
    }
    Component.onCompleted: if (enabled)
        reload()
    onEnabledChanged: if (enabled)
        reload()
    // new chapters and sprites written meanwhile (the editor saves into the folder)
    Timer {
        interval: 180000
        running: root.enabled && root.loaded
        repeat: true
        onTriggered: root.reload()
    }
    // settings arrive after the singleton: the folder may change from the default
    onDirChanged: if (enabled)
        reload()
    // the wizard (or Settings) set the gender: the chapter knows what was said there
    Connections {
        target: Config.novel
        function onGenderChanged() {
            const s = Object.assign({}, root.state);
            s.vars = Object.assign({}, s.vars, {
                "setupGender": Config.novel.gender || ""
            });
            root.state = s;
            root.save();
        }
    }
    Connections {
        target: Shell
        function onResumed() {
            root.resumed();
        }
    }

    // ---- for Settings and IPC ----
    function reset() {
        line = null;
        paper = null;
        noteOpen = false;
        state = freshState();
        save();
        return "ok";
    }
    function status() {
        return JSON.stringify({
            "enabled": enabled,
            "dir": dir,
            "chapters": Object.keys(stories),
            "chapter": state.chapter,
            "main": state.main,
            "side": state.side,
            "free": state.free,
            "vars": state.vars,
            "nextQ": state.nextQ ? Math.round((state.nextQ - Date.now()) / 60000) + " min" : "",
            "nextDrop": state.nextDrop ? Math.round((state.nextDrop - Date.now()) / 60000) + " min" : "",
            "canShow": canShow,
            "line": !!line,
            "paper": !!paper
        });
    }
    // dev and the owner: the next question / note right now
    function forceQuestion() {
        const s = Object.assign({}, state);
        s.nextQ = 0;
        s.free = true;
        state = s;
        tick();
    }
    function forceDrop() {
        const s = Object.assign({}, state);
        s.nextDrop = 0;
        s.free = true;
        state = s;
        tick();
    }
    function edit() {
        Quickshell.execDetached(["python3", Quickshell.shellDir + "/novel/editor/nov-editor.py", "--dir", dir]);
    }
}
