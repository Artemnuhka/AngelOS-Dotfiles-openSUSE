//@ pragma UseQApplication
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import Quickshell
import qs.services
import qs.modules
import qs.modules.background
import qs.modules.desktop
import qs.modules.clipboard
import qs.modules.bar
import qs.modules.launcher
import qs.modules.lock
import qs.modules.notifications
import qs.modules.osd
import qs.modules.polkit
import qs.modules.session
import qs.modules.settings
import qs.modules.workspace
import qs.modules.tour
import qs.modules.voxtype
import qs.modules.idle
import qs.modules.sidebar
import qs.widgets

// angelOS — pixel pink shell for niri.
ShellRoot {
    // no hot reload on save: edits land via `angelos reload` once they are checked
    settings.watchFiles: Quickshell.env("ANGELOS_DEV") === "1"

    Background {}
    Bar {}
    StartOverlay {}
    SidebarHost {}
    WorkspaceFx {}
    NotificationPopups {}
    Osd {}
    VoxIndicator {}
    Launcher {}
    ClipboardPanel {}
    SessionMenu {}
    IdleScreen {}
    Lock {}
    PolkitDialog {}
    SettingsWindow {}
    SetupWizard {}
    TourOverlay {}
    PluginHost {}
    Ipc {}

    // Keep dynamically loaded settings pages visible to Quickshell's static
    // QML importer. Without these type anchors, pages loaded later through a
    // Loader report "PxPositionPicker/BarLayoutEditor is not a type".
    Component {
        id: positionPickerTypeAnchor
        PxPositionPicker {}
    }
    Component {
        id: barLayoutEditorTypeAnchor
        BarLayoutEditor {}
    }
    Component {
        id: textAreaTypeAnchor
        PxTextArea {}
    }

    Component.onCompleted: {
        ThemeExport.signature; // wake the template exporter
        PaletteGenerator.auto; // follow wallpaper colours from startup
        Fonts.files; // register fonts installed into ~/.local/share/fonts/angelos
        MetaTap.status; // Meta tap → Start menu
        Idle.active; // idle-minutes watcher
        NautilusSetup.status; // first run: Nautilus defaults + mediafix
        PluginStudio.loaded; // make the worker available to dynamically loaded pages
    }
}
