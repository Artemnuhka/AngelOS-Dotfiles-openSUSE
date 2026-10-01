import QtQuick
import qs.config
import qs.services
import qs.widgets

// Simple settings view, the first screen: everyday actions and eight big tiles.
// Everything else lives under «Ещё» or behind the «Эксперт» button.
PxPage {
    id: page

    heading: I18n.t("Что настроить?", "What would you like to change?")
    subtitle: I18n.t("Нажми на плитку или напиши в поиске сверху своими словами — «сделать крупнее», «обои», «звук». Сложное спрятано под «Дополнительно» и кнопкой «Эксперт».", "Pick a tile or type in the search above in your own words — “bigger”, “wallpaper”, “sound”. Advanced things hide under “Advanced” and the Expert button.")

    readonly property var tiles: [
        {
            "id": "wallpaper",
            "icon": "image",
            "label": I18n.t("Обои", "Wallpaper"),
            "hint": I18n.t("картинка на рабочем столе", "the desktop picture")
        },
        {
            "id": "appearance",
            "icon": "palette",
            "label": I18n.t("Цвета и тема", "Colours and theme"),
            "hint": I18n.t("светлая или тёмная, любимый цвет", "light or dark, your colour")
        },
        {
            "id": "bar",
            "icon": "window",
            "label": I18n.t("Панель", "Taskbar"),
            "hint": I18n.t("«Пуск», кнопки окон, часы", "Start, window buttons, clock")
        },
        {
            "id": "sound",
            "icon": "speaker",
            "label": I18n.t("Звук", "Sound"),
            "hint": I18n.t("громкость и микрофон", "volume and microphone")
        },
        {
            "id": "monitor",
            "icon": "monitor",
            "label": I18n.t("Экран", "Display"),
            "hint": I18n.t("разрешение, частота, мониторы", "resolution, refresh, monitors")
        },
        {
            "id": "keyboard",
            "icon": "keyboard",
            "label": I18n.t("Клавиатура и мышь", "Keyboard and mouse"),
            "hint": I18n.t("языки, скорость мыши", "languages, mouse speed")
        },
        {
            "id": "windows",
            "icon": "layers",
            "label": I18n.t("Окна", "Windows"),
            "hint": I18n.t("как закрываются и открываются", "how they open and close")
        },
        {
            "id": "more",
            "icon": "grid",
            "label": I18n.t("Ещё", "More"),
            "hint": I18n.t("все остальные разделы", "every other section")
        }
    ]

    readonly property var fallbackFrequent: [
        {
            "id": "sound",
            "icon": "speaker",
            "label": I18n.t("Громкость", "Volume")
        },
        {
            "id": "shortcuts",
            "icon": "keyboard",
            "label": I18n.t("Горячие клавиши", "Shortcuts")
        },
        {
            "id": "widgets",
            "icon": "layers",
            "label": I18n.t("Виджеты на столе", "Desktop widgets")
        }
    ]
    // four most visited pages (not wallpaper: it has its own button); the
    // defaults fill up while there is no history yet
    readonly property var frequent: {
        const usage = Config.settingsUi.usage || {};
        const all = Shell.settingsView ? Shell.settingsView.allPages : [];
        const top = Object.keys(usage).filter(id => id !== "wallpaper" && usage[id] >= 2 && all.some(p => p.id === id)).sort((a, b) => usage[b] - usage[a]).slice(0, 4).map(id => {
            const p = all.find(x => x.id === id);
            return {
                "id": id,
                "icon": p.icon,
                "label": p.label
            };
        });
        for (const f of fallbackFrequent)
            if (top.length < 3 && !top.some(t => t.id === f.id))
                top.push(f);
        return top;
    }

    // the chosen logo (Bar → Logo) greets you here too
    AngelLogo {
        pixel: Theme.u
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Частое", "Everyday")
        icon: "star"
        Flow {
            width: parent.width
            spacing: Theme.u * 3
            PxButton {
                icon: "image"
                text: I18n.t("Сменить обои", "Change wallpaper")
                onClicked: Shell.settingsPage = "wallpaper"
            }
            PxButton {
                icon: Theme.dark ? "sun" : "moon"
                text: Theme.dark ? I18n.t("Светлая тема", "Light theme") : I18n.t("Тёмная тема", "Dark theme")
                onClicked: Config.appearance.mode = Theme.dark ? "light" : "dark"
            }
            PxButton {
                icon: "plus"
                enabled: Config.appearance.px < 4
                text: I18n.t("Крупнее", "Bigger")
                onClicked: Config.appearance.px = Math.min(4, Config.appearance.px + 1)
            }
            PxButton {
                icon: "minus"
                enabled: Config.appearance.px > 1
                text: I18n.t("Мельче", "Smaller")
                onClicked: Config.appearance.px = Math.max(1, Config.appearance.px - 1)
            }
            // the pages you open most (Config.settingsUi.usage); until there is a
            // history: sound, shortcuts, widgets
            Repeater {
                model: page.frequent
                PxButton {
                    required property var modelData
                    icon: modelData.icon
                    text: modelData.label
                    onClicked: Shell.settingsPage = modelData.id
                }
            }
        }
    }

    Grid {
        id: grid
        width: parent.width
        spacing: Theme.u * 5
        columns: Math.max(2, Math.floor((width + spacing) / (Theme.u * 92 + spacing)))
        readonly property real tileW: (width - (columns - 1) * spacing) / columns
        Repeater {
            model: page.tiles
            PxTile {
                required property var modelData
                width: grid.tileW
                icon: modelData.icon
                text: modelData.label
                hint: modelData.hint
                onClicked: Shell.settingsPage = modelData.id
            }
        }
    }
}
