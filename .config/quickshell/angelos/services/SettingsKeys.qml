pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Which settings each settings page shows (scripts/page-keys.py reads the
// pages' QML): "Reset this page" puts exactly those back to their defaults,
// and "Undo" names its step after the row the setting sits in.
Singleton {
    id: root

    property var pages: ({})                 // page id -> ["section.key", …]
    property var labels: ({})                // "section.key" -> {ru, en, page}
    property bool loaded: false

    function load() {
        if (!loaded && !proc.running)
            proc.running = true;
    }
    function keysOf(page) {
        return pages[page] || [];
    }
    // what differs from the default on a page
    function changedOn(page) {
        return keysOf(page).filter(p => {
            const [s, k] = p.split(".");
            return Config[s] && JSON.stringify(Config[s][k]) !== JSON.stringify(Config.defaultOf(p));
        });
    }
    // settings changed outside a SettingRow (the wallpaper grid, dragging widgets…)
    readonly property var extraLabels: ({
            "wallpaper.fallback": ["Обои", "Wallpaper"],
            "wallpaper.outputs": ["Обои", "Wallpaper"],
            "wallpaper.workspaces": ["Обои", "Wallpaper"],
            "desktop.widgets": ["Виджеты на столе", "Desktop widgets"],
            "bar.layout": ["Раскладка панели", "Bar layout"],
            "bar.hidden": ["Раскладка панели", "Bar layout"],
            "bar.startPinned": ["Закреплённое в «Пуске»", "Pinned in Start"],
            "workspaces.names": ["Имена столов", "Workspace names"],
            "workspaces.switchFx": ["Анимация переключения", "Switch animation"],
            "notifications.dnd": ["Не беспокоить", "Do not disturb"],
            "appearance.fontTitle": ["Шрифты", "Fonts"],
            "appearance.fontBody": ["Шрифты", "Fonts"],
            "appearance.fontMono": ["Шрифты", "Fonts"],
            "settingsUi.skin": ["Вид настроек", "Settings look"]
        })
    function labelOf(path) {
        const e = extraLabels[path];
        if (e)
            return I18n.t(e[0], e[1]);
        const l = labels[path];
        return l ? I18n.t(l.ru, l.en) : path;
    }
    // "Undo: Pixel size" / "Undo: 3 changes"
    function stepLabel(step) {
        if (!step || !step.changes.length)
            return "";
        const names = [];
        for (const c of step.changes) {
            const n = labelOf(c.path);
            if (!names.includes(n))
                names.push(n);
        }
        return names.length === 1 ? "«" + names[0] + "»" : names.length + I18n.t(" настроек", " settings");
    }

    Process {
        id: proc
        command: ["python3", Quickshell.shellDir + "/scripts/page-keys.py", Quickshell.shellDir + "/modules/settings/pages"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.pages = d.pages || {};
                    root.labels = d.labels || {};
                    root.loaded = true;
                } catch (e) {}
            }
        }
    }
}
