import QtQuick
import qs.config

// Keep the original angelOS home intact; the optional looks have their own layout.
Loader {
    id: root
    readonly property string settingsSkin: Theme.settingsSkinFor(root.parent)
    source: settingsSkin === "classic" ? "ClassicHomePage.qml" : "DlcHomePage.qml"
}
