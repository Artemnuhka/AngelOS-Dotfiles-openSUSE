import QtQuick
import qs.config

// The original tile list stays intact for classic; optional looks use new tiles.
Loader {
    id: root
    readonly property string settingsSkin: Theme.settingsSkinFor(root.parent)
    source: settingsSkin === "classic" ? "ClassicMorePage.qml" : "DlcMorePage.qml"
}
