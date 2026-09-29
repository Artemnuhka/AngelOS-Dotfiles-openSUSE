import QtQuick
import Quickshell
import Quickshell.Io
import "."

// IPC:  qs -c angelos ipc call codex <fn>
Item {
    id: root
    property var plugin

    Component.onCompleted: CodexState.intervalSec = plugin ? plugin.get("interval", 60) : 60
    onPluginChanged: if (plugin)
        CodexState.intervalSec = plugin.get("interval", 60)

    IpcHandler {
        target: "codex"

        function status(): string {
            return JSON.stringify({
                "state": CodexState.state,
                "five_left": CodexState.fiveLeft,
                "week_left": CodexState.weekLeft,
                "today_tokens": CodexState.today.total_tokens || 0,
                "sessions": CodexState.sessions.length,
                "provider": CodexState.data.provider || ""
            });
        }
        function refresh(): void {
            CodexState.refresh();
        }
        function resume(): void {
            CodexState.launch(["resume", "--last"]);
        }
        function ask(question: string): void {
            CodexState.ask(question);
        }
    }
}
