import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

// `qs -c angelos ipc call angelos <fn> [args]` — the `angelos` CLI wraps this.
IpcHandler {
    target: "angelos"

    function settings(page: string): void {
        Shell.toggleSettings(page);
    }
    function showLyrics(): void {
        Config.lyrics.enabled = true;
        Config.lyrics.screens = [];
        Lyrics.visibleToggle = true;
    }
    function setup(): void {
        Shell.setupOpen = true;
    }
    function launcher(): void {
        Shell.launcherOpen = !Shell.launcherOpen;
    }
    function launcherWith(text: string): void {
        Shell.launcherPrefill = text;
        Shell.launcherOpen = true;
    }
    function session(): void {
        Shell.sessionOpen = !Shell.sessionOpen;
    }
    function clipboard(): void {
        Shell.clipboardOpen = !Shell.clipboardOpen;
    }
    // toggle a desktop widget: angelos widget clock DP-1 (types: clock sysmon cava nowplaying plugin:<id>)
    function widget(type: string, screen: string): string {
        if (!DesktopWidgets.typeInfo(type))
            return "unknown widget: " + type + " (" + DesktopWidgets.types.map(t => t.type).join(", ") + ")";
        DesktopWidgets.toggle(type, screen || (Shell.focusedScreen ? Shell.focusedScreen.name : ""));
        return "ok";
    }
    function widgetEdit(): void {
        DesktopWidgets.editMode = !DesktopWidgets.editMode;
    }
    function tour(): void {
        Tour.start();
    }
    function lock(): void {
        Shell.lock();
    }
    function lyrics(): void {
        Config.lyrics.enabled = !Config.lyrics.enabled;
    }
    function theme(mode: string): void {
        Config.appearance.mode = mode === "toggle" ? (Theme.dark ? "light" : "dark") : mode;
    }
    function flavor(name: string): void {
        Config.appearance.flavor = name;
    }
    function wallpaper(path: string): void {
        if (path === "random")
            Wallpapers.random("");
        else
            Wallpapers.setEverywhere(path);
    }
    function bar(style: string): void {
        Config.bar.style = style;
    }
    function volumeUp(): void {
        Audio.step(0.05);
    }
    function volumeDown(): void {
        Audio.step(-0.05);
    }
    function mute(): void {
        Audio.toggleMute();
    }
    function micMute(): void {
        Audio.toggleMic();
    }
    function media(cmd: string): void {
        const p = Lyrics.player;
        if (!p)
            return;
        if (cmd === "next")
            p.next();
        else if (cmd === "previous" || cmd === "prev")
            p.previous();
        else if (cmd === "pause")
            p.pause();
        else if (cmd === "play")
            p.play();
        else
            p.togglePlaying();
    }
    // owner only: dotfiles pull | publish | check (no-op in the public version)
    function dotfiles(action: string): string {
        if (!Owner.enabled || !Owner.jobs)
            return "owner features are not available";
        Shell.openSettings("dotfiles");
        if (action === "pull")
            Owner.jobs.update();
        else if (action === "publish")
            Owner.jobs.publish(false);
        else if (action === "check")
            Owner.jobs.publish(true);
        return "ok";
    }
    // used by ~/.local/bin/polkit-agent-guard to hand the session slot back to angelOS
    function polkitRegister(): void {
        if (Shell.polkitReregister)
            Shell.polkitReregister();
    }
    function plugins(): void {
        Plugins.reload();
    }
    function reload(): void {
        Quickshell.reload(true);
    }
    // replay the workspace switch animation on an output (handy after tweaking settings)
    function testFx(output: string): void {
        const ws = Niri.activeWorkspace(output || Niri.focusedOutput);
        if (ws)
            Niri.workspaceActivated(ws, false);
    }
    function testNotify(): void {
        if (!Shell.dev) {
            Quickshell.execDetached(["notify-send", "-a", "angelOS", I18n.t("Привет ♡", "Hello ♡"), I18n.t("тестовое уведомление", "test notification")]);
            return;
        }
        Notifs.popups = Notifs.popups.concat([
            {
                "id": 900000 + Math.floor(Math.random() * 99999),
                "appName": "angelOS",
                "summary": I18n.t("Привет, это тест ♡", "Hello, this is a test ♡"),
                "body": I18n.t("Уведомление в стиле <b>NGO</b>: пиксели, розовый и сердечки. <i>Клик</i> — закрыть.", "An <b>NGO</b> notification: pixels, pink and hearts. <i>Click</i> to dismiss."),
                "actions": [
                    {
                        "text": I18n.t("Ответить", "Reply"),
                        "identifier": "reply",
                        "invoke": () => {}
                    }
                ],
                "urgency": 1,
                "expireTimeout": -1,
                "image": "",
                "appIcon": "kitty",
                "desktopEntry": "",
                "tracked": false
            }
        ]);
    }
    function testOsd(): void {
        Audio.changed("volume");
    }
    function panel(name: string, output: string): bool {
        return PopupManager.showPanel(name, output);
    }
    function taskLabels(show: bool): void {
        Config.bar.taskLabels = show;
    }
    function claudeBar(mode: string): void {
        if (["off", "five", "week", "both"].includes(mode)) {
            const p = Plugins.byId("claude-companion");
            if (p)
                Plugins.context(p).set("barLimit", mode);
        }
    }
    function lyricArtwork(mode: string): void {
        if (["note", "cover"].includes(mode))
            Config.lyrics.artwork = mode;
    }
    function blur(enabled: bool): void {
        Config.appearance.blur = enabled;
    }
    function diagnostics(): string {
        const bars = {};
        for (const k of Object.keys(Shell.barViews))
            bars[k] = Shell.barViews[k].diagnostics();
        return JSON.stringify({
            settings: Shell.settingsView ? Shell.settingsView.diagnostics() : null,
            bars: bars,
            lyrics: {
                status: Lyrics.status,
                hasLyrics: Lyrics.hasLyrics,
                enabled: Config.lyrics.enabled,
                visible: Lyrics.visibleToggle,
                screens: Config.lyrics.screens,
                index: Lyrics.index,
                line: Lyrics.current,
                count: Lyrics.lines.length
            },
            popup: PopupManager.active ? PopupManager.active.title : "",
            panels: PopupManager.registered.map(p => ({
                        id: p.panelId,
                        output: p.outputName,
                        visible: p.visible,
                        width: p.width,
                        height: p.height
                    })),
            language: Config.appearance.language
        });
    }
    function status(): string {
        return JSON.stringify({
            "theme": Theme.dark ? "dark" : "light",
            "flavor": Config.appearance.flavor,
            "bar": Config.bar.style,
            "lyrics": Lyrics.status,
            "track": Lyrics.title,
            "plugins": Plugins.enabledPlugins.map(p => p.id),
            "screens": Shell.screens.map(s => s.name),
            "polkit": Shell.polkitRegistered,
            "notifications": true
        });
    }
}
