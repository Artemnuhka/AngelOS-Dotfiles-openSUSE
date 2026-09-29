import QtQuick
import qs.config
import qs.services
import qs.widgets

PxPage {
    heading: I18n.t("Внешний вид", "Appearance")
    subtitle: I18n.t("Основная тема angelOS и дополнительные светлые и тёмные палитры.", "The original angelOS theme and additional light and dark palettes.")
    Component.onCompleted: BlurConfig.refresh()

    SettingRow {
        label: I18n.t("Язык", "Language")
        PxCombo {
            model: [
                {
                    label: "Русский",
                    value: "ru"
                },
                {
                    label: "English",
                    value: "en"
                }
            ]
            currentValue: Config.appearance.language
            onActivated: v => Config.appearance.language = v
        }
    }
    Row {
        visible: !Shell.setupOpen
        spacing: Theme.u * 4
        PxButton {
            text: I18n.t("Мастер настройки", "Setup wizard")
            icon: "sparkle"
            onClicked: Shell.setupOpen = true
        }
        PxButton {
            text: I18n.t("Подсказки по интерфейсу", "Interface tips")
            icon: "info"
            onClicked: {
                Shell.settingsOpen = false;
                Tour.start();
            }
        }
    }
    PxGroup {
        title: I18n.t("Тема", "Theme")
        icon: "palette"
        width: parent.width

        SettingRow {
            label: I18n.t("Режим", "Mode")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Светлая", "Light"),
                        "value": "light",
                        "icon": "sun"
                    },
                    {
                        "label": I18n.t("Тёмная", "Dark"),
                        "value": "dark",
                        "icon": "moon"
                    },
                    {
                        "label": I18n.t("Авто", "Auto"),
                        "value": "auto",
                        "icon": "sparkle"
                    }
                ]
                currentValue: Config.appearance.mode
                onActivated: v => Config.appearance.mode = v
            }
        }
        SettingRow {
            visible: Config.appearance.mode === "auto"
            label: I18n.t("Светлая с … до …", "Light theme from … to …")
            hint: I18n.t("часы, по локальному времени", "hours in local time")
            Row {
                spacing: Theme.u * 4
                PxSpin {
                    from: 0
                    to: 23
                    value: Config.appearance.lightFrom
                    suffix: ":00"
                    onMoved: v => Config.appearance.lightFrom = v
                }
                PxSpin {
                    from: 0
                    to: 23
                    value: Config.appearance.darkFrom
                    suffix: ":00"
                    onMoved: v => Config.appearance.darkFrom = v
                }
            }
        }
        SettingRow {
            label: I18n.t("Цветовая схема", "Color scheme")
            PxCombo {
                model: Object.keys(Theme.flavors).map(k => ({
                            "label": Theme.flavors[k].name,
                            "value": k
                        }))
                currentValue: Config.appearance.flavor
                onActivated: v => Config.appearance.flavor = v
            }
        }
        Row {
            spacing: Theme.u * 4
            PxButton {
                text: I18n.t("Создать из обоев", "Generate from wallpaper")
                icon: "image"
                enabled: !PaletteGenerator.busy
                onClicked: PaletteGenerator.generate()
            }
            PxField {
                width: Theme.u * 75
                visible: Config.appearance.flavor === "wallpaper"
                text: Config.appearance.customAccent
                placeholder: "#c77dff"
                onEdited: if (/^#[0-9a-f]{6}$/i.test(text))
                    Config.appearance.customAccent = text
            }
        }
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            text: PaletteGenerator.error
            visible: text !== ""
            color: Theme.danger
        }
        // palette preview
        Row {
            spacing: Theme.u * 2
            Repeater {
                model: [Theme.accent, Theme.accent2, Theme.accent3, Theme.accent4, Theme.title1, Theme.title2, Theme.face, Theme.faceAlt, Theme.text, Theme.danger, Theme.ok]
                PxBox {
                    required property color modelData
                    width: Theme.u * 14
                    height: Theme.u * 14
                    color: modelData
                }
            }
        }
    }

    PxGroup {
        title: I18n.t("Стекло и пиксели", "Glass and pixels")
        icon: "sparkle"
        width: parent.width

        SettingRow {
            label: I18n.t("Блюр под панелями", "Blur behind panels")
            hint: I18n.t("ext-background-effect, рисует niri", "ext-background-effect, rendered by niri")
            PxToggle {
                checked: Config.appearance.blur
                onToggled: c => Config.appearance.blur = c
            }
        }
        SettingRow {
            label: I18n.t("Непрозрачность панелей", "Panel opacity")
            PxSlider {
                width: parent.width
                from: 0.4
                to: 1
                stepSize: 0.02
                value: Config.appearance.opacity
                valueScale: 100
                suffix: "%"
                onMoved: v => Config.appearance.opacity = v
            }
        }
        SettingRow {
            label: I18n.t("Сила блюра", "Blur strength")
            hint: I18n.t("Общая настройка niri; изменения сохраняются с бэкапом", "Global niri setting; changes are backed up")
            enabled: Config.appearance.blur && BlurConfig.supported && !BlurConfig.busy
            PxSlider {
                width: parent.width
                from: 0.5
                to: 10
                stepSize: 0.5
                decimals: 1
                value: BlurConfig.offset
                onReleased: v => BlurConfig.save({offset: v})
            }
        }
        SettingRow {
            label: I18n.t("Проходы размытия", "Blur passes")
            hint: I18n.t("Больше проходов — мягче размытие и выше нагрузка", "More passes soften the blur and use more GPU time")
            enabled: Config.appearance.blur && BlurConfig.supported && !BlurConfig.busy
            PxSpin {
                from: 1
                to: 6
                value: BlurConfig.passes
                onMoved: v => BlurConfig.save({passes: v})
            }
        }
        SettingRow {
            label: I18n.t("Зернистость стекла", "Glass grain")
            enabled: Config.appearance.blur && BlurConfig.supported && !BlurConfig.busy
            PxSlider {
                width: parent.width
                from: 0
                to: 0.1
                stepSize: 0.002
                valueScale: 100
                decimals: 1
                suffix: "%"
                value: BlurConfig.noise
                onReleased: v => BlurConfig.save({noise: v})
            }
        }
        PxText {
            width: parent.width
            visible: text !== ""
            wrapMode: Text.Wrap
            dim: true
            text: BlurConfig.log
        }
        SettingRow {
            label: I18n.t("Размер пикселя", "Pixel size")
            hint: I18n.t("1 арт-пиксель = N экранных", "1 art pixel = N screen pixels")
            PxSpin {
                from: 1
                to: 4
                value: Config.appearance.px
                suffix: " px"
                onMoved: v => Config.appearance.px = v
            }
        }
        SettingRow {
            label: I18n.t("Масштаб шрифтов", "Font scale")
            hint: I18n.t("×1 или ×2, чтобы глифы оставались чёткими", "Use 1× or 2× to keep glyphs crisp")
            PxSegmented {
                model: [
                    {
                        "label": "×1",
                        "value": 1
                    },
                    {
                        "label": "×2",
                        "value": 2
                    }
                ]
                currentValue: Config.appearance.fontScale
                onActivated: v => Config.appearance.fontScale = v
            }
        }
        SettingRow {
            label: I18n.t("Жёсткие пиксельные тени", "Pixel shadows")
            PxToggle {
                checked: Config.appearance.shadows
                onToggled: c => Config.appearance.shadows = c
            }
        }
    }

    PxGroup {
        title: I18n.t("Тема для приложений", "Application theme")
        icon: "terminal"
        width: parent.width

        SettingRow {
            label: I18n.t("Красить приложения", "Theme applications")
            hint: I18n.t("шаблоны → kitty, foot, alacritty, GTK, niri. Свои шаблоны: ~/.config/angelos/templates/*.json", "Templates for kitty, foot, alacritty, GTK and niri. Custom templates: ~/.config/angelos/templates/*.json")
            PxToggle {
                checked: Config.appearance.themeApps
                onToggled: c => Config.appearance.themeApps = c
            }
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 6
            visible: Config.appearance.themeApps
            Repeater {
                model: ThemeExport.entries
                PxCheck {
                    required property var modelData
                    text: modelData.name || modelData.id
                    checked: !(Config.appearance.disabledTemplates || []).includes(modelData.id)
                    onToggled: c => {
                        const list = (Config.appearance.disabledTemplates || []).filter(i => i !== modelData.id);
                        if (!c)
                            list.push(modelData.id);
                        Config.appearance.disabledTemplates = list;
                    }
                }
            }
        }
        Row {
            spacing: Theme.u * 4
            PxButton {
                text: I18n.t("Применить сейчас", "Apply now")
                icon: "refresh"
                onClicked: ThemeExport.apply()
            }
            PxText {
                anchors.verticalCenter: parent.verticalCenter
                text: Shell.dev ? I18n.t("(dev-режим: шаблоны не пишутся)", "(dev mode: templates are not written)") : ThemeExport.lastLog.split("\n").filter(l => l).length + I18n.t(" файлов обновлено", " files updated")
                dim: true
            }
        }
    }
}
