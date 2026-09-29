pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Workspace switch style = niri's workspace-switch spring + an optional angelOS
// flourish over the screen. Flourish styles switch instantly in niri (the cut is
// hidden under the effect); slide/bounce are pure niri springs.
Singleton {
    id: root

    readonly property var styles: [
        {
            "id": "soft",
            "niri": "soft",
            "label": I18n.t("Мягкий", "Soft"),
            "hint": I18n.t("пружинка angelOS по умолчанию", "angelOS default spring")
        },
        {
            "id": "slide",
            "niri": "slide",
            "label": I18n.t("Слайд", "Slide"),
            "hint": I18n.t("ровный проезд без отскока", "a clean slide, no overshoot")
        },
        {
            "id": "bounce",
            "niri": "bounce",
            "label": I18n.t("Подпрыг", "Bounce"),
            "hint": I18n.t("проскакивает и пружинит обратно", "overshoots and springs back")
        },
        {
            "id": "teleport",
            "niri": "instant",
            "fx": 3,
            "ms": 650,
            "label": I18n.t("Телепорт", "Teleport"),
            "hint": I18n.t("мгновенно, фиолетовые частицы эндермена", "instant, purple enderman particles")
        },
        {
            "id": "pixel",
            "niri": "instant",
            "fx": 0,
            "ms": 420,
            "label": I18n.t("Пиксели", "Pixels"),
            "hint": I18n.t("экран собирается из пикселей по дизеру", "the screen assembles from dithered pixels")
        },
        {
            "id": "heart",
            "niri": "instant",
            "fx": 2,
            "ms": 520,
            "label": I18n.t("Сердечко", "Heart iris"),
            "hint": I18n.t("мультяшная диафрагма в форме сердца", "a cartoon iris shaped like a heart")
        },
        {
            "id": "glitch",
            "niri": "instant",
            "fx": 1,
            "ms": 320,
            "label": I18n.t("Глитч", "Glitch"),
            "hint": I18n.t("NGO-помехи: полосы, сдвиги, сканлайны", "NGO interference: bars, shifts, scanlines")
        },
        {
            "id": "instant",
            "niri": "instant",
            "label": I18n.t("Мгновенно", "Instant"),
            "hint": I18n.t("без анимации", "no animation")
        }
    ]
    readonly property var current: styles.find(s => s.id === Config.workspaces.switchFx) || styles[0]
    property string niriPreset: ""       // what cfg/animation.kdl has now
    property string log: ""
    readonly property bool busy: writer.running

    function pick(id) {
        const s = styles.find(x => x.id === id);
        if (!s)
            return;
        Config.workspaces.switchFx = id;
        if (s.niri === niriPreset)
            return;
        if (Shell.dev) {
            log = I18n.t("В dev-режиме конфиг niri не изменяется", "Dev mode does not modify niri");
            return;
        }
        writer.command = ["python3", Quickshell.shellDir + "/scripts/workspace-anim.py", s.niri];
        writer.running = true;
    }
    function refresh() {
        if (!reader.running)
            reader.running = true;
    }

    Process {
        id: reader
        running: true
        command: ["python3", Quickshell.shellDir + "/scripts/workspace-anim.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.niriPreset = JSON.parse(text).preset || "";
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
