pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// Simple settings view: every section as a tile, in the sidebar's groups.
PxPage {
    id: page

    heading: I18n.t("Все разделы", "All sections")
    subtitle: I18n.t("То же, что в режиме «Эксперт», только плитками.", "The same as in Expert mode, as tiles.")

    Repeater {
        model: Shell.settingsView ? Shell.settingsView.visibleGroups : []
        PxGroup {
            id: grp
            required property var modelData
            width: page.innerWidth
            title: modelData.title
            Grid {
                id: grid
                width: parent.width
                spacing: Theme.u * 4
                columns: Math.max(2, Math.floor((width + spacing) / (Theme.u * 78 + spacing)))
                readonly property real tileW: (width - (columns - 1) * spacing) / columns
                Repeater {
                    model: grp.modelData.pages
                    PxTile {
                        required property var modelData
                        width: grid.tileW
                        small: true
                        icon: modelData.icon
                        text: modelData.label
                        onClicked: Shell.settingsPage = modelData.id
                    }
                }
            }
        }
    }
}
