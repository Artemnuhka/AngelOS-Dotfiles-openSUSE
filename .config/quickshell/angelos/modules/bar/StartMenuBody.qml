pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// Win98-like Start menu contents: arrow keys move, Enter runs, typing searches.
PxBox {
    id: root

    signal closeRequested
    property int current: -1

    readonly property var entries: [
        {
            "text": I18n.t("Программы…", "Applications…"),
            "icon": "search",
            "hint": "Mod+Space",
            "act": () => Shell.launcherOpen = true
        },
        {
            "text": I18n.t("Терминал", "Terminal"),
            "icon": "terminal",
            "act": () => Shell.terminal()
        },
        {
            "text": I18n.t("Файлы", "Files"),
            "icon": "folder",
            "act": () => Shell.exec([Config.system.fileManager || "xdg-open", Config.home])
        },
        {
            "separator": true
        },
        {
            "text": I18n.t("Обои", "Wallpaper"),
            "icon": "image",
            "act": () => Shell.openSettings("wallpaper")
        },
        {
            "text": I18n.t("Настройки", "Settings"),
            "icon": "gear",
            "act": () => Shell.openSettings()
        },
        {
            "text": I18n.t("Плагины", "Plugins"),
            "icon": "plug",
            "act": () => Shell.openSettings("plugins")
        },
        {
            "text": I18n.t("Мастер плагинов…", "Plugin Studio…"),
            "icon": "sparkle",
            "show": Config.developer.enabled,
            "act": () => Shell.openSettings("studio")
        },
        {
            "text": "Dotfiles",
            "icon": "package",
            "show": Owner.enabled,
            "act": () => Shell.openSettings("dotfiles")
        },
        {
            "text": I18n.t("Обновление готово ♡", "Update available ♡"),
            "icon": "download",
            "show": Updates.available,
            "act": () => Shell.openSettings("updates")
        },
        {
            "text": I18n.t("Мини-игра osu!", "osu! mini game"),
            "icon": "heart",
            "show": Plugins.enabledPlugins.some(p => p.id === "osu-mini"),
            "act": () => Shell.gameOpen = true
        },
        {
            "text": Theme.dark ? I18n.t("Светлая тема", "Light theme") : I18n.t("Тёмная тема", "Dark theme"),
            "icon": Theme.dark ? "sun" : "moon",
            "act": () => Config.appearance.mode = Theme.dark ? "light" : "dark"
        },
        {
            "separator": true
        },
        {
            "text": I18n.t("Заблокировать", "Lock"),
            "icon": "lock",
            "hint": "Mod+Alt+L",
            "act": () => Shell.lock()
        },
        {
            "text": I18n.t("Заставка", "Idle screen"),
            "icon": "moon",
            "act": () => Idle.start()
        },
        {
            "text": I18n.t("Выключение…", "Power…"),
            "icon": "power",
            "act": () => Shell.sessionOpen = true
        }
    ].filter(e => e.show === undefined || e.show)
    readonly property var actionable: entries.map((e, i) => e.separator ? -1 : i).filter(i => i >= 0)

    function run(index) {
        const e = entries[index];
        if (!e || e.separator)
            return;
        closeRequested();
        // after the overlay released the keyboard, so launcher/dialogs get focus
        Qt.callLater(e.act);
    }
    function move(step) {
        const list = actionable;
        if (!list.length)
            return;
        const at = list.indexOf(current);
        current = at < 0 ? (step > 0 ? list[0] : list[list.length - 1]) : list[(at + step + list.length) % list.length];
    }
    function key(e) {
        if (e.key === Qt.Key_Escape || e.key === Qt.Key_Super_L || e.key === Qt.Key_Super_R)
            closeRequested();
        else if (e.key === Qt.Key_Down || (e.key === Qt.Key_Tab && !(e.modifiers & Qt.ShiftModifier)))
            move(1);
        else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab)
            move(-1);
        else if (e.key === Qt.Key_Home)
            current = actionable[0];
        else if (e.key === Qt.Key_End)
            current = actionable[actionable.length - 1];
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space)
            run(current >= 0 ? current : actionable[0]);
        else if (e.text && e.text.trim() !== "" && !(e.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            // Windows-style: start typing to search
            Shell.launcherPrefill = e.text;
            closeRequested();
            Qt.callLater(() => Shell.launcherOpen = true);
        } else
            return;
        e.accepted = true;
    }

    width: Math.round(Theme.u * 160 * Math.max(0.7, Math.min(1.8, (Config.bar.startWidth || 100) / 100)))
    height: brand.height + Theme.u * 4 + col.implicitHeight + footer.height + inset * 2
    color: Qt.alpha(Theme.menuSurface, Theme.panelAlpha)
    edgeColor: Theme.menuBorder
    flat: true
    shadow: Config.appearance.shadows

    Rectangle {
        id: brand
        width: parent.width
        height: Theme.u * 27
        color: Theme.menuHeader
        AngelLogo {
            anchors.centerIn: parent
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: Theme.u
            color: Theme.menuBorder
        }
    }

    Column {
        id: col
        y: brand.height + Theme.u * 2
        width: parent.width
        Repeater {
            model: root.entries
            PxMenuItem {
                required property var modelData
                required property int index
                separator: !!modelData.separator
                text: modelData.text || ""
                icon: modelData.icon || ""
                hint: modelData.hint || ""
                highlighted: root.current === index
                onHoveredChanged: if (hovered)
                    root.current = index
                onTriggered: root.run(index)
            }
        }
    }

    PxText {
        id: footer
        anchors.bottom: parent.bottom
        width: parent.width
        height: implicitHeight + Theme.u * 4
        horizontalAlignment: Text.AlignHCenter
        kind: "tiny"
        dim: true
        text: I18n.t("печатай — поиск ♡", "type to search ♡")
    }
}
