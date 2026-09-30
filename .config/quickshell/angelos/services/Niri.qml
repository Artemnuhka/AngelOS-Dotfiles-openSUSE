pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// niri IPC: event stream for state + a request socket for actions.
Singleton {
    id: root

    readonly property string socketPath: Quickshell.env("NIRI_SOCKET")
    readonly property bool available: socketPath !== ""

    property var workspaces: []       // sorted by output, idx
    property var windows: []
    property int focusedWindowId: -1
    property var keyboardLayouts: []
    property int currentLayout: 0
    property bool overviewOpen: false
    property bool ready: false
    readonly property string focusedOutput: {
        const ws = workspaces.find(w => w.is_focused);
        return ws ? ws.output : "";
    }
    readonly property var focusedWindow: windows.find(w => w.id === focusedWindowId) || null
    readonly property string layoutName: keyboardLayouts[currentLayout] || ""
    readonly property string layoutShort: shortLayout(layoutName)

    // emitted only after the initial state arrived (never on startup)
    signal workspaceActivated(var ws, bool focused)
    signal layoutSwitched(string name)
    signal configLoaded(bool failed)
    signal windowClosed(int id)

    function shortLayout(name) {
        if (!name)
            return "";
        const map = {
            "English (US)": "EN",
            "Russian": "RU",
            "Ukrainian": "UA",
            "German": "DE",
            "French": "FR",
            "Japanese": "JP",
            "Belarusian": "BY",
            "Kazakh": "KZ"
        };
        if (map[name])
            return map[name];
        const m = name.match(/\(([A-Z]{2})\)/);
        return m ? m[1] : name.slice(0, 2).toUpperCase();
    }

    function workspacesOn(output) {
        return workspaces.filter(w => w.output === output);
    }
    function activeWorkspace(output) {
        return workspaces.find(w => w.output === output && w.is_active) || null;
    }
    function windowsOn(wsId) {
        return windows.filter(w => w.workspace_id === wsId);
    }
    function workspaceById(id) {
        return workspaces.find(w => w.id === id) || null;
    }
    function sortedWindows(list) {
        return list.slice().sort((a, b) => {
            const wa = workspaceById(a.workspace_id), wb = workspaceById(b.workspace_id);
            const oa = wa ? wa.output + ":" + ("00" + wa.idx).slice(-3) : "~";
            const ob = wb ? wb.output + ":" + ("00" + wb.idx).slice(-3) : "~";
            if (oa !== ob)
                return oa < ob ? -1 : 1;
            const pa = a.layout && a.layout.pos_in_scrolling_layout ? a.layout.pos_in_scrolling_layout : [999, 999];
            const pb = b.layout && b.layout.pos_in_scrolling_layout ? b.layout.pos_in_scrolling_layout : [999, 999];
            return pa[0] - pb[0] || pa[1] - pb[1] || a.id - b.id;
        });
    }

    // ---- actions ----
    function action(name, args) {
        const body = {};
        body[name] = args || {};
        request({
            "Action": body
        });
    }
    function focusWorkspace(id) {
        action("FocusWorkspace", {
            "reference": {
                "Id": id
            }
        });
    }
    function focusWindow(id) {
        action("FocusWindow", {
            "id": id
        });
    }
    function closeWindow(id) {
        action("CloseWindow", {
            "id": id
        });
    }
    function fullscreenWindow(id) {
        action("FullscreenWindow", {
            "id": id
        });
    }
    function maximizeWindow(id) {
        action("MaximizeWindowToEdges", {
            "id": id
        });
    }
    function toggleFloating(id) {
        action("ToggleWindowFloating", {
            "id": id
        });
    }
    function moveWindowToWorkspace(id, wsIdx) {
        action("MoveWindowToWorkspace", {
            "window_id": id,
            "reference": {
                "Index": wsIdx
            },
            "focus": false
        });
    }
    function moveWindowToMonitor(id, output) {
        action("MoveWindowToMonitor", {
            "id": id,
            "output": output
        });
    }
    function switchLayout(next) {
        action("SwitchLayout", {
            "layout": next === false ? "Prev" : "Next"
        });
    }
    function quit() {
        action("Quit", {
            "skip_confirmation": true
        });
    }
    function powerOffMonitors() {
        action("PowerOffMonitors", {});
    }
    function toggleOverview() {
        action("ToggleOverview", {});
    }

    // one request per connection (niri closes the socket after replying)
    property var _queue: []
    property var _current: null
    function request(obj, cb) {
        _queue.push({
            "body": JSON.stringify(obj),
            "cb": cb
        });
        _pump();
    }
    function _pump() {
        if (_current || _queue.length === 0 || !available)
            return;
        _current = _queue.shift();
        req.connected = true;
    }

    Socket {
        id: req
        path: root.socketPath
        onConnectedChanged: {
            if (connected && root._current) {
                write(root._current.body + "\n");
                flush();
            } else if (!connected) {
                root._current = null;
                Qt.callLater(root._pump);
            }
        }
        onError: {
            root._current = null;
            connected = false;
        }
        parser: SplitParser {
            onRead: line => {
                const cur = root._current;
                try {
                    const reply = JSON.parse(line);
                    if (reply.Err)
                        console.warn("niri:", reply.Err);
                    if (cur && cur.cb)
                        cur.cb(reply.Ok !== undefined ? reply.Ok : null, reply.Err || null);
                } catch (e) {
                    console.warn("niri reply parse:", e);
                }
                req.connected = false;
            }
        }
    }

    // ---- event stream ----
    Socket {
        id: events
        path: root.socketPath
        connected: root.available
        onConnectedChanged: {
            if (connected) {
                write('"EventStream"\n');
                flush();
            } else {
                reconnect.start();
            }
        }
        parser: SplitParser {
            onRead: line => root._handle(line)
        }
    }

    Timer {
        id: reconnect
        interval: 1000
        onTriggered: events.connected = true
    }

    function _setWorkspaces(list) {
        workspaces = list.slice().sort((a, b) => a.output === b.output ? a.idx - b.idx : (a.output < b.output ? -1 : 1));
    }

    function _handle(line) {
        let ev;
        try {
            ev = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (ev.Ok !== undefined)
            return;
        const kind = Object.keys(ev)[0];
        const d = ev[kind];
        switch (kind) {
        case "WorkspacesChanged":
            _setWorkspaces(d.workspaces);
            if (!ready)
                readyTimer.restart();
            break;
        case "WorkspaceActivated":
            {
                const target = workspaces.find(w => w.id === d.id);
                if (!target)
                    break;
                const switched = !target.is_active; // focus moving to another monitor is not a switch
                _setWorkspaces(workspaces.map(w => {
                    const c = Object.assign({}, w);
                    if (w.output === target.output)
                        c.is_active = w.id === d.id;
                    if (d.focused)
                        c.is_focused = w.id === d.id;
                    return c;
                }));
                if (ready && switched)
                    workspaceActivated(workspaces.find(w => w.id === d.id), d.focused);
                break;
            }
        case "WorkspaceActiveWindowChanged":
            _setWorkspaces(workspaces.map(w => w.id === d.workspace_id ? Object.assign({}, w, {
                    "active_window_id": d.active_window_id
                }) : w));
            break;
        case "WorkspaceUrgencyChanged":
            _setWorkspaces(workspaces.map(w => w.id === d.id ? Object.assign({}, w, {
                    "is_urgent": d.urgent
                }) : w));
            break;
        case "WindowsChanged":
            windows = d.windows;
            {
                const f = d.windows.find(w => w.is_focused);
                focusedWindowId = f ? f.id : -1;
            }
            break;
        case "WindowOpenedOrChanged":
            {
                const list = windows.filter(w => w.id !== d.window.id);
                list.push(d.window);
                if (d.window.is_focused) {
                    focusedWindowId = d.window.id;
                    for (let i = 0; i < list.length; i++)
                        if (list[i].id !== d.window.id && list[i].is_focused)
                            list[i] = Object.assign({}, list[i], {
                                "is_focused": false
                            });
                }
                windows = list;
                break;
            }
        case "WindowClosed":
            windows = windows.filter(w => w.id !== d.id);
            if (ready)
                windowClosed(d.id);
            if (focusedWindowId === d.id)
                focusedWindowId = -1;
            break;
        case "WindowFocusChanged":
            focusedWindowId = d.id === null ? -1 : d.id;
            windows = windows.map(w => w.is_focused === (w.id === d.id) ? w : Object.assign({}, w, {
                    "is_focused": w.id === d.id
                }));
            break;
        case "WindowUrgencyChanged":
            windows = windows.map(w => w.id === d.id ? Object.assign({}, w, {
                    "is_urgent": d.urgent
                }) : w);
            break;
        case "WindowLayoutsChanged":
            {
                const map = {};
                for (const [id, layout] of d.changes)
                    map[id] = layout;
                windows = windows.map(w => map[w.id] ? Object.assign({}, w, {
                        "layout": map[w.id]
                    }) : w);
                break;
            }
        case "KeyboardLayoutsChanged":
            keyboardLayouts = d.keyboard_layouts.names;
            currentLayout = d.keyboard_layouts.current_idx;
            break;
        case "KeyboardLayoutSwitched":
            currentLayout = d.idx;
            if (ready)
                layoutSwitched(layoutName);
            break;
        case "OverviewOpenedOrClosed":
            overviewOpen = d.is_open;
            break;
        case "ConfigLoaded":
            configLoaded(!!d.failed);
            break;
        }
    }

    // initial burst of events settles before we start animating
    Timer {
        id: readyTimer
        interval: 400
        onTriggered: root.ready = true
    }
}
