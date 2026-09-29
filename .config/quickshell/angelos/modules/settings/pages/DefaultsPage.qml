pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

PxPage {
    heading: I18n.t("Приложения по умолчанию", "Default applications")
    subtitle: I18n.t("Чем открывать ссылки, файлы и папки. Пишется в ~/.config/mimeapps.list (сначала бэкап).", "What opens links, files and folders. Written to ~/.config/mimeapps.list (backed up first).")

    Component.onCompleted: DefaultApps.refresh()

    PxGroup {
        title: I18n.t("По умолчанию", "Defaults")
        icon: "star"
        width: parent.width
        enabled: !DefaultApps.busy

        Repeater {
            model: DefaultApps.categories
            SettingRow {
                id: row
                required property var modelData
                readonly property var info: DefaultApps.data[modelData.id] || ({
                        "current": "",
                        "candidates": []
                    })
                readonly property var cur: info.candidates.find(c => c.id === info.current) || null
                label: modelData.label
                hint: info.candidates.length === 0 ? I18n.t("нет подходящих приложений", "no matching applications") : ""
                Row {
                    spacing: Theme.u * 4
                    Item {
                        width: Theme.u * 12
                        height: Theme.u * 12
                        anchors.verticalCenter: parent.verticalCenter
                        AppIcon {
                            anchors.centerIn: parent
                            visible: !!row.cur
                            iconName: row.cur ? row.cur.icon : ""
                            size: Theme.u * 11
                        }
                        PxIcon {
                            anchors.centerIn: parent
                            visible: !row.cur
                            name: row.modelData.icon
                        }
                    }
                    PxCombo {
                        width: Theme.u * 120
                        model: row.info.candidates.map(c => ({
                                    "label": c.name,
                                    "value": c.id
                                }))
                        currentValue: row.info.current
                        placeholder: row.info.current || "—"
                        onActivated: v => DefaultApps.set(row.modelData.id, v)
                    }
                }
            }
        }
    }
    PxText {
        width: parent.width
        wrapMode: Text.Wrap
        text: DefaultApps.log
        dim: true
    }
}
