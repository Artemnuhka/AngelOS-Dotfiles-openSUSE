import QtQuick
import qs.config
import qs.services
import qs.widgets

// Scrollable settings page: a column of PxGroups, and at the bottom "Reset this
// page" for the settings the page shows (services/SettingsKeys) — asks once
// more before it resets; "Undo" at the top brings everything back.
PxScroll {
    id: root

    property string heading: ""
    property string subtitle: ""
    default property alias items: col.data
    readonly property int innerWidth: col.width
    // the settings page this is (plugin pages and the home tiles have nothing to reset)
    property string pageId: Shell.settingsPage
    readonly property var changed: SettingsKeys.loaded ? SettingsKeys.changedOn(pageId) : []
    property bool confirming: false
    property int resetCount: -1

    contentHeight: col.implicitHeight + (footer.visible ? footer.height + Theme.u * 8 : 0) + Theme.u * 10

    Column {
        id: col
        x: Theme.u * 4
        y: Theme.u * 4
        width: parent.width - Theme.u * 8
        spacing: Theme.u * 8

        Column {
            visible: root.heading !== ""
            width: parent.width
            spacing: Theme.u
            PxText {
                text: root.heading
                kind: "big"
                color: Theme.dark ? Theme.accent : Theme.edge
            }
            PxText {
                visible: root.subtitle !== ""
                width: parent.width
                text: root.subtitle
                dim: true
                wrapMode: Text.Wrap
            }
        }
    }

    Row {
        id: footer
        visible: root.pageId !== "home" && root.pageId !== "more" && SettingsKeys.keysOf(root.pageId).length > 0 && (root.changed.length > 0 || root.resetCount >= 0)
        x: col.x
        y: col.y + col.implicitHeight + Theme.u * 8
        spacing: Theme.u * 4
        PxButton {
            compact: true
            danger: root.confirming
            icon: "refresh"
            enabled: root.changed.length > 0
            text: root.confirming ? I18n.t("Точно сбросить? Нажми ещё раз", "Sure? Click again") : I18n.t("Сбросить эту страницу", "Reset this page")
            onClicked: {
                if (!root.confirming) {
                    root.confirming = true;
                    unconfirm.restart();
                    return;
                }
                root.confirming = false;
                root.resetCount = Config.resetKeys(root.changed);
            }
        }
        PxText {
            anchors.verticalCenter: parent.verticalCenter
            kind: "tiny"
            dim: true
            text: root.resetCount >= 0 && root.changed.length === 0 ? I18n.t("Сброшено ♡ «Отменить» вверху вернёт как было", "Reset ♡ “Undo” at the top brings it back") : I18n.t("изменено здесь: ", "changed here: ") + root.changed.length
        }
    }
    Timer {
        id: unconfirm
        interval: 4000
        onTriggered: root.confirming = false
    }
    Component.onCompleted: SettingsKeys.load()
}
