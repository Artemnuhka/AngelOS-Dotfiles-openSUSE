import QtQuick
import qs.config
import qs.services
import qs.widgets

PxButton {
    compact: true
    flat: true
    icon: Config.notifications.dnd ? "bellOff" : "bell"
    text: Notifs.unread > 0 ? String(Notifs.unread) : ""
    onClicked: Config.notifications.dnd = !Config.notifications.dnd
}
