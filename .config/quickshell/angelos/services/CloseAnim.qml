pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// niri's window-close animation: its own fade + shrink, off, or an angelOS shader
// (shaders/close/*.glsl) — written into cfg/animation.kdl by scripts/close-anim.py.
Singleton {
    id: root

    readonly property var styles: [
        {
            "id": "default",
            "label": I18n.t("Обычная", "Default"),
            "hint": I18n.t("как у niri: окно тает и чуть уменьшается", "niri's own: the window fades and shrinks a little")
        },
        {
            "id": "pixel",
            "label": I18n.t("Пиксели", "Pixels"),
            "hint": I18n.t("рассыпается на пиксельные блоки, они гаснут по одному", "crumbles into pixel blocks that blink out one by one")
        },
        {
            "id": "heart",
            "label": I18n.t("Сердечко", "Heart"),
            "hint": I18n.t("окно сжимается внутри розового сердца", "the window shrinks away inside a pink heart")
        },
        {
            "id": "crt",
            "label": I18n.t("Старый телевизор", "Old TV"),
            "hint": I18n.t("схлопывается в яркую полосу, потом в точку", "collapses into a bright line, then a dot")
        },
        {
            "id": "glitch",
            "label": I18n.t("Глитч", "Glitch"),
            "hint": I18n.t("полосы разъезжаются, цвета расслаиваются", "slices jump sideways, colours split")
        },
        {
            "id": "fall",
            "label": I18n.t("Падение", "Fall"),
            "hint": I18n.t("окно падает вниз с лёгким наклоном", "the window drops with a slight tilt")
        },
        {
            "id": "minimize",
            "label": I18n.t("В панель", "Into the bar"),
            "hint": I18n.t("складывается вниз, к панели задач", "folds down towards the taskbar")
        },
        {
            "id": "off",
            "label": I18n.t("Без анимации", "Off"),
            "hint": I18n.t("окно исчезает сразу", "the window disappears at once")
        }
    ]
    property string current: ""          // what cfg/animation.kdl has ("custom" = hand-written shader)
    property string log: ""
    readonly property bool busy: writer.running

    function pick(id) {
        if (!styles.some(s => s.id === id) || id === current)
            return;
        if (Shell.dev) {
            log = I18n.t("В dev-режиме конфиг niri не изменяется", "Dev mode does not modify niri");
            return;
        }
        writer.command = ["python3", Quickshell.shellDir + "/scripts/close-anim.py", id];
        writer.running = true;
    }
    // a throwaway window that closes itself, to see the animation
    function preview() {
        Shell.exec(Shell.terminalArgv(["sh", "-c", "printf '\\n  ♡ angelOS: " + I18n.t("закрываюсь…", "closing…") + "\\n'; sleep 1.2"], "angelos.closepreview"));
    }

    Process {
        id: reader
        running: true
        command: ["python3", Quickshell.shellDir + "/scripts/close-anim.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.current = JSON.parse(text).preset || "";
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
                    root.log = r.error ? r.error : r.ok || "";
                } catch (e) {
                    root.log = text.trim();
                }
            }
        }
        onExited: reader.running = true
    }
}
