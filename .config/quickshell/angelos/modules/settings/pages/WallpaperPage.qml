pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

PxPage {
    id: page

    heading: I18n.t("Обои", "Wallpaper")
    subtitle: I18n.t("Клик — поставить. Можно на все экраны, на монитор или на отдельный воркспейс.", "Click to apply to all displays, one monitor, or one workspace.")

    property string target: "all"   // all | output | workspace
    property string folder: ""
    property int pageNo: 0
    readonly property int perPage: 24
    readonly property var folders: {
        const set = {};
        for (const p of Wallpapers.images)
            set[p.slice(0, p.lastIndexOf("/"))] = true;
        return Object.keys(set).sort();
    }
    readonly property var filtered: folder ? Wallpapers.images.filter(p => p.slice(0, p.lastIndexOf("/")) === folder) : Wallpapers.images
    readonly property int pages: Math.max(1, Math.ceil(filtered.length / perPage))
    onFolderChanged: pageNo = 0
    property string output: Shell.focusedScreen ? Shell.focusedScreen.name : ""
    property int wsIdx: {
        const w = Niri.activeWorkspace(output);
        return w ? w.idx : 1;
    }

    function pick(path) {
        if (target === "all")
            Wallpapers.setEverywhere(path);
        else if (target === "output")
            Wallpapers.setForOutput(output, path);
        else
            Wallpapers.setForWorkspace(output, wsIdx, path);
    }

    PxGroup {
        title: I18n.t("Куда", "Destination")
        icon: "monitor"
        width: parent.width

        SettingRow {
            label: I18n.t("Применять", "Apply")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Везде", "Everywhere"),
                        "value": "all"
                    },
                    {
                        "label": I18n.t("Монитор", "Monitor"),
                        "value": "output"
                    },
                    {
                        "label": I18n.t("Воркспейс", "Workspace"),
                        "value": "workspace"
                    }
                ]
                currentValue: page.target
                onActivated: v => page.target = v
            }
        }
        SettingRow {
            visible: page.target !== "all"
            label: I18n.t("Монитор", "Monitor")
            PxCombo {
                width: Theme.u * 100
                model: Quickshell.screens.map(s => s.name)
                currentValue: page.output
                onActivated: v => page.output = v
            }
        }
        SettingRow {
            visible: page.target === "workspace"
            label: I18n.t("Воркспейс", "Workspace")
            PxCombo {
                width: Theme.u * 100
                model: Niri.workspacesOn(page.output).map(w => ({
                            "label": (w.name || "#" + w.idx) + (w.is_active ? "  ♡" : ""),
                            "value": w.idx
                        }))
                currentValue: page.wsIdx
                onActivated: v => page.wsIdx = v
            }
        }
        SettingRow {
            label: I18n.t("Папка", "Folder")
            Row {
                spacing: Theme.u * 3
                PxField {
                    id: dirField
                    width: Theme.u * 130
                    text: Config.wallpaper.dir
                    onAccepted: Config.wallpaper.dir = text
                }
                PxButton {
                    compact: true
                    icon: "refresh"
                    onClicked: {
                        Config.wallpaper.dir = dirField.text;
                        Wallpapers.scan();
                    }
                }
                PxButton {
                    compact: true
                    icon: "sparkle"
                    text: I18n.t("случайные", "random")
                    onClicked: Wallpapers.random(page.target === "all" ? "" : page.output)
                }
            }
        }
    }

    PxGroup {
        title: I18n.t("Переход", "Transition")
        icon: "sparkle"
        width: parent.width
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            text: I18n.t("Играет только когда меняешь картинку. При переключении воркспейсов обои меняются мгновенно.", "Runs when the image changes. Workspace wallpapers otherwise switch instantly.")
            dim: true
        }
        SettingRow {
            label: I18n.t("Эффект", "Effect")
            PxSegmented {
                model: [
                    {
                        "label": I18n.t("Мозаика+дизер", "Mosaic + dither"),
                        "value": "mosaic-dither"
                    },
                    {
                        "label": I18n.t("Мозаика", "Mosaic"),
                        "value": "mosaic"
                    },
                    {
                        "label": I18n.t("Дизер", "Dither"),
                        "value": "dither"
                    },
                    {
                        "label": I18n.t("Нет", "None"),
                        "value": "none"
                    }
                ]
                currentValue: Config.wallpaper.transition
                onActivated: v => Config.wallpaper.transition = v
            }
        }
        SettingRow {
            label: I18n.t("Длительность", "Duration")
            PxSlider {
                width: parent.width
                from: 200
                to: 2000
                stepSize: 50
                value: Config.wallpaper.duration
                suffix: I18n.t(" мс", " ms")
                onMoved: v => Config.wallpaper.duration = v
            }
        }
        SettingRow {
            label: I18n.t("Крупность мозаики", "Mosaic size")
            PxSlider {
                width: parent.width
                from: 8
                to: 128
                stepSize: 8
                value: Config.wallpaper.maxBlock
                suffix: " px"
                onMoved: v => Config.wallpaper.maxBlock = v
            }
        }
    }

    PxGroup {
        title: I18n.t("Картинки (", "Images (") + page.filtered.length + ")"
        icon: "image"
        width: parent.width

        Row {
            spacing: Theme.u * 3
            PxCombo {
                width: Theme.u * 120
                model: [
                    {
                        "label": I18n.t("все папки", "All folders"),
                        "value": ""
                    }
                ].concat(page.folders.map(f => ({
                            "label": f.replace(Config.home, "~"),
                            "value": f
                        })))
                currentValue: page.folder
                onActivated: v => page.folder = v
            }
            PxButton {
                compact: true
                icon: "arrowLeft"
                enabled: page.pageNo > 0
                onClicked: page.pageNo--
            }
            PxText {
                anchors.verticalCenter: parent.verticalCenter
                text: (page.pageNo + 1) + " / " + page.pages
            }
            PxButton {
                compact: true
                icon: "arrowRight"
                enabled: page.pageNo + 1 < page.pages
                onClicked: page.pageNo++
            }
        }

        Grid {
            id: grid
            width: parent.width
            columns: Math.max(2, Math.floor(width / (Theme.u * 72)))
            spacing: Theme.u * 3
            readonly property int cell: Math.floor((width - (columns - 1) * spacing) / columns)

            Repeater {
                model: page.filtered.slice(page.pageNo * page.perPage, (page.pageNo + 1) * page.perPage)
                Item {
                    id: thumb
                    required property string modelData
                    readonly property string currentHere: page.target === "all" ? Wallpapers.resolve(Quickshell.screens[0].name, 1) : page.target === "output" ? Wallpapers.resolve(page.output, -1) : Wallpapers.resolve(page.output, page.wsIdx)
                    readonly property bool active: currentHere === modelData
                    width: grid.cell
                    height: Math.round(grid.cell * 9 / 16)

                    PxBox {
                        anchors.fill: parent
                        sunken: true
                        color: Theme.sunken
                        edgeColor: thumb.active ? Theme.accent : Theme.edge
                        Image {
                            anchors.fill: parent
                            source: "file://" + thumb.modelData
                            sourceSize: Qt.size(width, height)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            smooth: true
                        }
                    }
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: tm.containsMouse || thumb.active ? Theme.u * 2 : 0
                        border.color: Theme.accent
                    }
                    PxIcon {
                        visible: thumb.active
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Theme.u * 3
                        name: "heart"
                    }
                    MouseArea {
                        id: tm
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.pick(thumb.modelData)
                    }
                }
            }
        }
    }
}
