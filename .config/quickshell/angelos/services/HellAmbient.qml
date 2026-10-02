pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Hell's one moving thing: now and then — every few minutes, at random — something slow
// happens on the rim of one window or widget (HellLook.event: an ember glows and dies, rime
// creeps, a drop falls; widgets/HellEdge draws it). Nothing at all while a window covers a
// screen (games, video: the same moment niri-game-mode turns animations off), while
// streaming, locked, or out of hell. In between, no timer ticks.
Singleton {
    id: root

    readonly property bool allowed: Angel.demon && !Shell.locked && !StreamMode.active && !Shell.screens.some(s => Shell.fullscreenOn(s.name))
    readonly property int durationMs: 4200

    function schedule() {
        wait.interval = (150 + Math.random() * 210) * 1000;
        wait.restart();
    }
    // `angelos helper ambient` (dev or owner): one now, to see it
    function now() {
        start();
    }
    function start() {
        HellLook.eventTarget = Math.floor(Math.random() * 6);
        root._t0 = Date.now();
        HellLook.event = 0;
        tick.start();
    }
    property double _t0: 0

    onAllowedChanged: {
        if (allowed)
            schedule();
        else {
            wait.stop();
            tick.stop();
            HellLook.event = 0;
            HellLook.eventTarget = -1;
        }
    }
    Component.onCompleted: if (allowed)
        schedule()

    Timer {
        id: wait
        onTriggered: if (root.allowed)
            root.start()
    }
    // ten steps a second while it lasts: up, hold, down — stepped, like everything pixel
    Timer {
        id: tick
        interval: 100
        repeat: true
        onTriggered: {
            const p = (Date.now() - root._t0) / root.durationMs;
            if (p >= 1) {
                stop();
                HellLook.event = 0;
                HellLook.eventTarget = -1;
                root.schedule();
                return;
            }
            const v = p < 0.35 ? p / 0.35 : p < 0.6 ? 1 : (1 - p) / 0.4;
            HellLook.event = Math.round(v * 8) / 8;
        }
    }
}
