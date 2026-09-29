pragma Singleton

import QtQuick
import Quickshell
import qs.config

// Region screenshot / screen recording through the dotfiles tools, which draw
// the selector in the skin chosen in Settings → Screenshots (Config.capture.skin).
Singleton {
    readonly property string screenshotTool: Config.home + "/.local/bin/niri-screenshot-region"
    readonly property string recordTool: Config.home + "/.local/bin/niri-record-region"

    function screenshot() {
        Quickshell.execDetached(["sh", "-c", '[ -x "$1" ] && exec "$1"; exec niri msg action screenshot', "sh", screenshotTool]);
    }
    function record() {
        Quickshell.execDetached(["sh", "-c", '[ -x "$1" ] && exec "$1"; notify-send -a angelOS "niri-record-region не найден"', "sh", recordTool]);
    }
}
