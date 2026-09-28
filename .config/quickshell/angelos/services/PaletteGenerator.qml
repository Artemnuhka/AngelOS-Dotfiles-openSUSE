pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root
    property string error: ""
    readonly property bool busy: process.running
    function generate() {
        if (busy)
            return;
        const screen = Niri.focusedOutput || (Shell.screens[0] ? Shell.screens[0].name : "");
        const ws = Niri.activeWorkspace(screen);
        const path = Wallpapers.resolve(screen, ws ? ws.idx : 1);
        if (!path) {
            error = I18n.t("Сначала выбери обои", "Choose a wallpaper first");
            return;
        }
        error = "";
        process.command = ["python3", Quickshell.shellDir + "/scripts/wallpaper-color.py", path];
        process.running = true;
    }
    Process {
        id: process
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text);
                    if (!/^#[0-9a-f]{6}$/i.test(result.accent))
                        throw "Invalid color";
                    Config.appearance.customAccent = result.accent;
                    Config.appearance.flavor = "wallpaper";
                } catch (e) {
                    root.error = String(e);
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim())
                root.error = text.trim()
        }
    }
}
