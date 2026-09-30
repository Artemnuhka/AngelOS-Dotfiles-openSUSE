pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Workspace switch transitions.
//   soft, dash         — niri's own workspace-switch animation (bezier curves)
//   dissolve/heart/ender — angelOS: the old screen is captured, niri switches
//                        instantly underneath, and the frozen frame is taken away
//                        by shaders/ws_transition.frag (modules/workspace/SwitchFx).
// For the captured styles the workspace keys (Mod+1…9, Mod+wheel, Mod+O) go
// through `angelos ws …` → the control socket here; scripts/workspace-anim.py
// rewrites those binds and back, and niri falls back to itself if the shell is
// not running.
Singleton {
    id: root

    readonly property var styles: [
        {
            "id": "soft",
            "niri": "soft",
            "label": I18n.t("Мягкий", "Soft"),
            "hint": I18n.t("плавно разгоняется и мягко тормозит, без отскока", "eases in and settles softly, no overshoot")
        },
        {
            "id": "dash",
            "niri": "dash",
            "label": I18n.t("Рывок", "Dash"),
            "hint": I18n.t("медленный старт, рывок и аккуратная остановка", "a slow start, a dash and a tidy stop")
        },
        {
            "id": "dissolve",
            "niri": "instant",
            "fx": 0,
            "ms": 480,
            "label": I18n.t("Пиксели", "Pixels"),
            "hint": I18n.t("старый стол рассыпается пиксельными блоками", "the old desk crumbles into pixel blocks")
        },
        {
            "id": "heart",
            "niri": "instant",
            "fx": 1,
            "ms": 620,
            "label": I18n.t("Сердечко", "Heart"),
            "hint": I18n.t("новый стол открывается сквозь растущее сердце", "the new desk opens through a growing heart")
        },
        {
            "id": "ender",
            "niri": "instant",
            "fx": 2,
            "ms": 720,
            "label": I18n.t("Телепорт", "Teleport"),
            "hint": I18n.t("экран распадается на фиолетовые частицы эндермена", "the screen breaks into purple enderman particles")
        },
        {
            "id": "instant",
            "niri": "instant",
            "label": I18n.t("Мгновенно", "Instant"),
            "hint": I18n.t("без анимации", "no animation")
        }
    ]
    // styles of earlier versions
    readonly property var legacy: ({
            "slide": "dash",
            "bounce": "soft",
            "teleport": "ender",
            "pixel": "dissolve",
            "glitch": "dissolve"
        })
    readonly property var current: styles.find(s => s.id === (legacy[Config.workspaces.switchFx] || Config.workspaces.switchFx)) || styles[0]
    readonly property bool captured: current.fx !== undefined
    property string niriPreset: ""       // what cfg/animation.kdl has now
    property bool routed: false          // workspace keys go through `angelos ws`
    property string log: ""
    readonly property bool busy: writer.running
    // SwitchFx of that screen captures, then calls niriAct(target)
    signal captureRequested(string screen, string target)

    function pick(id) {
        const s = styles.find(x => x.id === id);
        if (!s)
            return;
        Config.workspaces.switchFx = id;
        const route = s.fx !== undefined;
        if (s.niri === niriPreset && route === routed)
            return;
        if (Shell.dev) {
            log = I18n.t("В dev-режиме конфиг niri не изменяется", "Dev mode does not modify niri");
            return;
        }
        writer.command = ["python3", Quickshell.shellDir + "/scripts/workspace-anim.py", s.niri, route ? "--route" : "--native"];
        writer.running = true;
    }
    function refresh() {
        if (!reader.running)
            reader.running = true;
    }
    // after an update the installer may bring back default binds: write the chosen style again
    function reapply() {
        if (Shell.dev || writer.running)
            return;
        writer.command = ["python3", Quickshell.shellDir + "/scripts/workspace-anim.py", current.niri, captured ? "--route" : "--native"];
        writer.running = true;
    }

    // ---- switching ----
    // target: a workspace number, "up", "down" or "prev"
    function go(target) {
        target = String(target);
        if (!/^([0-9]{1,2}|up|down|prev)$/.test(target))
            return;
        const out = Niri.focusedOutput;
        const screen = Shell.screenByName(out);
        const list = Niri.workspacesOn(out).filter(w => w.name !== "privacy" || w.is_active);
        const active = list.find(w => w.is_active);
        const idx = active ? active.idx : -1;
        // nothing would change: no transition
        const same = /^[0-9]+$/.test(target) ? parseInt(target) === idx : target === "up" ? idx <= (list[0] ? list[0].idx : 1) : target === "down" ? idx >= (list.length ? list[list.length - 1].idx : 1) : false;
        // leaving a fullscreen game or video: switch plainly, no grab of the game
        if (!captured || !screen || same || Idle.active || Shell.locked || MetaTap.coversOutput(Niri.focusedWindow)) {
            niriAct(target);
            return;
        }
        captureRequested(out, target);
    }
    // plays the current transition over a screen without switching (settings preview)
    function preview(screen) {
        if (captured)
            captureRequested(screen || Niri.focusedOutput, "");
    }
    function niriAct(target) {
        if (!target)
            return;
        if (/^[0-9]+$/.test(target))
            Niri.action("FocusWorkspace", {
                "reference": {
                    "Index": parseInt(target)
                }
            });
        else
            Niri.action(({
                    "up": "FocusWorkspaceUp",
                    "down": "FocusWorkspaceDown",
                    "prev": "FocusWorkspacePrevious"
                })[target], {});
    }

    // `angelos ws …` from the niri keybinds lands here (a few ms instead of `qs ipc`)
    readonly property string runtimeDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/angelos"
    readonly property string socketPath: runtimeDir + (Shell.dev ? "/ctl-dev.sock" : "/ctl.sock")
    property bool socketReady: false
    Process {
        running: true
        command: ["sh", "-c", 'mkdir -p "$1" && chmod 700 "$1" && rm -f "$2"', "sh", root.runtimeDir, root.socketPath]
        onExited: code => root.socketReady = code === 0
    }
    SocketServer {
        active: root.socketReady
        path: root.socketPath
        handler: Socket {
            id: client
            parser: SplitParser {
                onRead: line => {
                    const m = line.trim().match(/^ws ([0-9]{1,2}|up|down|prev)$/);
                    client.write(m ? "ok\n" : "err\n");
                    client.flush();
                    if (m)
                        root.go(m[1]);
                }
            }
        }
    }

    Process {
        id: reader
        running: true
        command: ["python3", Quickshell.shellDir + "/scripts/workspace-anim.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text);
                    root.niriPreset = r.preset || "";
                    root.routed = !!r.routed;
                    // one-time move from the old style names
                    if (root.legacy[Config.workspaces.switchFx])
                        Qt.callLater(() => root.pick(root.legacy[Config.workspaces.switchFx]));
                } catch (e) {}
            }
        }
    }
    Process {
        id: writer
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text);
                    root.log = r.error ? I18n.t("niri: ", "niri: ") + r.error : "";
                } catch (e) {
                    root.log = text.trim();
                }
            }
        }
        onExited: root.refresh()
    }
}
