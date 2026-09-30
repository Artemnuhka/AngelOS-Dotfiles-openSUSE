pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import QtTest
import qs.config
import qs.services
import qs.widgets
import "AngelSprite.js" as AngelArt
import "DemonSprite.js" as DemonArt

// The Y2K helper: a pixel angel (or the demon, services/Angel) floating in the
// bottom-right corner of her screen. Speech bubble with buttons; a click on her
// opens a menu, "Ask…" takes typed questions. Stepped animation at ~8 fps that
// pauses while the screen is locked or covered by a fullscreen window; the
// angel ↔ demon swap drops one through the floor into flames and brings the
// other in.
Scope {
    // created only while she is wanted (no binding on the window's own visible:
    // Quickshell re-applies it when the screen changes, which loops)
    LazyLoader {
        active: Angel.shown && !Shell.bootOpen && !!Angel.screen

        PanelWindow {
            id: win

            screen: Angel.screen
            anchors {
                bottom: true
                right: true
            }
            margins {
                bottom: Theme.u * 4
                right: Theme.u * 6
            }
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 0
            color: "transparent"
            implicitWidth: Theme.u * 160
            // room above her for the one coming down from the sky, or while she is held
            readonly property int headroom: Angel.transition ? Theme.u * 70 : grab.held ? Theme.u * 30 : 0
            implicitHeight: body.height + headroom
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "angelos-angel"
            WlrLayershell.keyboardFocus: Angel.menuOpen && Angel.menuMode === "ask" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            // the bubble's own `visible` follows the window's: the mask uses the state
            readonly property bool bubbleOn: (Angel.talking || Angel.menuOpen) && !Angel.transition
            mask: Region {
                item: angel
                Region {
                    item: win.bubbleOn ? bubble : null
                }
            }

            // ---- 8 fps clock: wings, bobbing, blinking, talking ----
            property int tick: 0
            Timer {
                interval: 125
                running: win.visible && !Shell.hiddenScreen(Angel.screenName)
                repeat: true
                onTriggered: win.tick++
            }
            // the swap flips the sprite halfway through (Angel.becomeDemon/becomeAngel)
            readonly property bool demonArt: Angel.demon
            readonly property var art: demonArt ? DemonArt : AngelArt
            readonly property var frame: {
                if (Angel.talking && typer.shown < Angel.text.length && tick % 2 === 0)
                    return art.talk;
                if (tick % 29 === 0)
                    return art.blink;
                return Math.floor(tick / 3) % 2 ? art.down : art.up;
            }
            readonly property int bob: Angel.transition ? 0 : [0, 1, 2, 2, 1, 0, -1, -1][tick % 8]
            // swap motion: the leaving one hops and drops through the floor, the new one
            // climbs out of the flames (demon) or comes down from the sky (angel)
            readonly property real swapY: {
                const p = Angel.swap;
                if (!Angel.transition)
                    return 0;
                const h = sprite.height + Theme.u * 8;
                if (p < 0.5) {
                    const q = p / 0.5;
                    // thrown: she keeps falling from where she was let go
                    if (Angel.thrown)
                        return Angel.throwY + q * q * (h * 1.2 - Angel.throwY);
                    return q < 0.25 ? -Math.sin(q / 0.25 * Math.PI) * Theme.u * 8 : (q - 0.25) / 0.75 * h * 1.2;
                }
                const q = (p - 0.5) / 0.5;
                return Angel.transition === "toHell" ? (1 - q) * h * 1.2 : -(1 - q) * Theme.u * 70;
            }
            // where the sprite is: held by the pointer, springing back, or falling from the throw
            readonly property real offX: Angel.transition ? (Angel.thrown && Angel.swap < 0.5 ? Angel.throwX : 0) : grab.dx
            readonly property real offY: Angel.transition ? swapY : grab.dy
            // hellfire under her: while the swap runs, and as she is pushed into the floor
            readonly property real flames: Angel.transition ? Math.max(0, 1 - Math.abs(Angel.swap - 0.5) * 2.4) : (!demonArt && grab.dy > 0 ? Math.min(1, grab.dy / (sprite.height * 0.55)) : 0)

            Item {
                id: body
                anchors.bottom: parent.bottom
                width: parent.width
                height: angel.height + (win.bubbleOn ? bubble.height + Theme.u * 2 : 0) + Theme.u * 4

                // ---- speech bubble / menu ----
                PxBox {
                    id: bubble
                    visible: win.bubbleOn
                    anchors.right: parent.right
                    anchors.bottom: angel.top
                    anchors.bottomMargin: Theme.u * 2
                    width: Theme.u * 150
                    height: bubbleCol.implicitHeight + Theme.u * 8
                    color: Theme.menuSurface
                    shadow: Config.appearance.shadows

                    Column {
                        id: bubbleCol
                        x: Theme.u * 4
                        y: Theme.u * 4
                        width: parent.width - Theme.u * 8
                        spacing: Theme.u * 3

                        Row {
                            width: parent.width
                            spacing: Theme.u * 2
                            PxText {
                                width: parent.width - closeBtn.width - Theme.u * 2
                                text: !Angel.menuOpen ? Angel.text.slice(0, typer.shown) : Angel.menuMode === "ask" ? (Angel.demon ? I18n.t("Спрашивай. Может, отвечу.", "Go on, ask. Maybe I'll answer.") : I18n.t("Спроси что угодно — и про настройки тоже ♡", "Ask me anything, settings included ♡")) : (Angel.demon ? I18n.t("Ну? Чего тебе?", "Well? What do you want?") : I18n.t("Чем помочь? ♡", "How can I help? ♡"))
                                wrapMode: Text.Wrap
                            }
                            PxButton {
                                id: closeBtn
                                compact: true
                                flat: true
                                icon: "close"
                                onClicked: Angel.hush()
                            }
                        }

                        // buttons of what she said (undo a prank, show the setting, another joke…)
                        Flow {
                            visible: !Angel.menuOpen && Angel.actions.length > 0 && typer.shown >= Angel.text.length
                            width: parent.width
                            spacing: Theme.u * 2
                            Repeater {
                                model: Angel.menuOpen ? [] : Angel.actions
                                PxButton {
                                    required property var modelData
                                    required property int index
                                    compact: true
                                    accent: index === 0
                                    icon: modelData.icon || "heart"
                                    text: modelData.label
                                    onClicked: {
                                        const run = modelData.run;
                                        Angel.hush();
                                        if (run)
                                            run();
                                    }
                                }
                            }
                        }

                        // ---- the menu ----
                        Flow {
                            visible: Angel.menuOpen && Angel.menuMode === "main"
                            width: parent.width
                            spacing: Theme.u * 2
                            PxButton {
                                compact: true
                                accent: true
                                icon: "chat"
                                text: I18n.t("Спросить…", "Ask…")
                                onClicked: Angel.openMenu("ask")
                            }
                            PxButton {
                                visible: !Angel.demon
                                compact: true
                                icon: "star"
                                text: I18n.t("Совет", "A tip")
                                onClicked: Angel.tip()
                            }
                            PxButton {
                                compact: true
                                icon: "sparkle"
                                text: Angel.demon ? I18n.t("Пошути", "Joke") : I18n.t("Шутка", "A joke")
                                onClicked: Angel.joke()
                            }
                            PxButton {
                                visible: !Angel.demon
                                compact: true
                                icon: "gear"
                                text: I18n.t("Настройки", "Settings")
                                onClicked: {
                                    Angel.hush();
                                    Shell.openSettings();
                                }
                            }
                            PxButton {
                                compact: true
                                icon: "moon"
                                text: Angel.demon ? I18n.t("Отстань на час", "Leave me for an hour") : I18n.t("Спрячься на час", "Hide for an hour")
                                onClicked: Angel.hide(60)
                            }
                            // the owner debugging the swap: no begging (Owner.enabled — never in the public version)
                            PxButton {
                                visible: Angel.demon && Owner.enabled
                                compact: true
                                icon: "terminal"
                                text: I18n.t("Ангела назад (владелец)", "Angel back (owner)")
                                onClicked: Angel.ownerAngel()
                            }
                            PxButton {
                                compact: true
                                icon: "close"
                                text: I18n.t("Выключить", "Turn off")
                                onClicked: {
                                    Angel.hush();
                                    Config.y2k.helper = false;
                                }
                            }
                        }

                        // ---- Ask… ----
                        PxField {
                            id: askField
                            visible: Angel.menuOpen && Angel.menuMode === "ask"
                            width: parent.width
                            icon: "chat"
                            placeholder: Angel.demon ? I18n.t("Ну, спроси…", "Go on, ask…") : I18n.t("Например: как сделать крупнее?", "E.g. how do I make things bigger?")
                            onAccepted: {
                                const q = text;
                                text = "";
                                Angel.answer(q);
                            }
                            onKeyPressed: e => {
                                if (e.key === Qt.Key_Escape) {
                                    Angel.hush();
                                    e.accepted = true;
                                }
                            }
                            onVisibleChanged: if (visible)
                                focusLater.restart()
                            Timer {
                                id: focusLater
                                interval: 60
                                onTriggered: askField.focusField()
                            }
                        }
                        Flow {
                            visible: Angel.menuOpen && Angel.menuMode === "ask"
                            width: parent.width
                            spacing: Theme.u * 2
                            PxButton {
                                visible: Angel.demon
                                compact: true
                                accent: true
                                icon: "heart"
                                text: I18n.t("Верни ангела", "Bring the angel back") + " · " + Angel.pleasCounted + "/" + Angel.pleasNeeded
                                onClicked: Angel.plea()
                            }
                            PxButton {
                                compact: true
                                icon: "sparkle"
                                text: I18n.t("Пошути", "Tell a joke")
                                onClicked: Angel.joke()
                            }
                            PxButton {
                                visible: !Angel.demon
                                compact: true
                                icon: "star"
                                text: I18n.t("Дай совет", "Give me a tip")
                                onClicked: Angel.tip()
                            }
                            PxButton {
                                compact: true
                                icon: "chat"
                                text: I18n.t("Как дела?", "How are you?")
                                onClicked: Angel.answer(I18n.t("как дела", "how are you"))
                            }
                            PxButton {
                                compact: true
                                icon: "info"
                                text: I18n.t("Кто ты?", "Who are you?")
                                onClicked: Angel.answer(I18n.t("кто ты", "who are you"))
                            }
                            PxButton {
                                compact: true
                                flat: true
                                icon: "arrowLeft"
                                text: I18n.t("Назад", "Back")
                                onClicked: Angel.openMenu("main")
                            }
                        }
                    }
                }

                // typewriter for the bubble text
                QtObject {
                    id: typer
                    property int shown: 0
                }
                Timer {
                    interval: 30
                    running: Angel.talking && typer.shown < Angel.text.length
                    repeat: true
                    onTriggered: typer.shown = Math.min(Angel.text.length, typer.shown + 2)
                }
                Connections {
                    target: Angel
                    function onTextChanged() {
                        typer.shown = 0;
                    }
                }

                // ---- the angel (or the demon) ----
                Item {
                    id: angel
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    width: sprite.width
                    height: sprite.height + Theme.u * 4

                    // her stage reaches up into the sky and across the window while she
                    // moves; below the floor she is cut off (drops through it instead of
                    // over the bar)
                    Item {
                        id: stage
                        readonly property bool moving: !!Angel.transition || grab.held
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        width: moving ? win.width : parent.width
                        height: parent.height + win.headroom
                        clip: moving

                        PxIcon {
                            id: sprite
                            x: stage.width - width + win.offX
                            y: stage.height - angel.height + Theme.u * 2 + (stage.moving ? 0 : win.bob * Math.max(1, Theme.u / 2)) + win.offY
                            bitmap: win.frame
                            pixel: Theme.u * 2
                            ink: win.demonArt ? "#1a0a14" : (Theme.dark ? Theme.text : Theme.edge)
                            body: win.demonArt ? "#f7d9e3" : "#ffd9c7"
                            fill: win.demonArt ? "#ff3b6b" : Theme.accent
                            fill2: "#3a1a46"
                            fill3: Theme.dark ? "#ffe07a" : "#f5c542"
                            light: win.demonArt ? "#7a1e46" : "#ffffff"
                            bad: "#d8203a"
                        }
                        // hellfire at the floor under her while they swap, or as she is
                        // pushed down
                        Row {
                            visible: win.flames > 0
                            opacity: win.flames
                            anchors.bottom: parent.bottom
                            x: sprite.x + (sprite.width - width) / 2
                            spacing: 0
                            Repeater {
                                model: 4
                                PxIcon {
                                    required property int index
                                    name: "fire"
                                    pixel: Theme.u * 2
                                    fill3: "#ffd23f"
                                    bad: "#ff4a1c"
                                    light: "#fff3b0"
                                    y: ((win.tick + index) % 2) * Theme.u
                                }
                            }
                        }
                    }
                    // a click opens her menu; press and drag picks her up. Let go deep
                    // below the floor (or fling her down) and she falls into hell;
                    // anything less and she springs back. The demon always springs back.
                    MouseArea {
                        id: grab
                        anchors.fill: parent
                        enabled: !Angel.transition
                        cursorShape: dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                        property bool dragging: false
                        readonly property bool held: dragging || spring.running
                        property real dx: 0
                        property real dy: 0
                        property point start
                        property real vy: 0                      // downward speed, px/ms
                        property real lastY: 0
                        property double lastT: 0
                        readonly property real deep: sprite.height * 0.55

                        onPressed: m => {
                            spring.stop();
                            start = Qt.point(m.x, m.y);
                            dragging = false;
                            dx = 0;
                            dy = 0;
                            vy = 0;
                            lastY = m.y;
                            lastT = Date.now();
                        }
                        onPositionChanged: m => {
                            if (!pressed)
                                return;
                            if (!dragging) {
                                if (Math.abs(m.x - start.x) + Math.abs(m.y - start.y) < Theme.u * 3)
                                    return;
                                dragging = true;
                                Angel.grabbed();
                            }
                            const now = Date.now();
                            if (now > lastT) {
                                vy = vy * 0.4 + (m.y - lastY) / (now - lastT) * 0.6;
                                lastY = m.y;
                                lastT = now;
                            }
                            dx = Math.max(-(win.width - sprite.width), Math.min(Theme.u * 4, m.x - start.x));
                            dy = Math.max(-Theme.u * 26, m.y - start.y);
                        }
                        onReleased: {
                            if (!dragging) {
                                if (Angel.menuOpen)
                                    Angel.hush();
                                else
                                    Angel.openMenu("main");
                                return;
                            }
                            dragging = false;
                            const thrown = !Angel.demon && (dy > deep || (dy > Theme.u * 6 && vy > 0.9));
                            Angel.released(thrown, dx, dy);
                            if (thrown) {
                                dx = 0;
                                dy = 0;
                            } else {
                                spring.start();
                            }
                        }
                        onCanceled: {
                            dragging = false;
                            spring.start();
                        }
                        // dev (`angelos helper "drag DX DY MS"`): the same drag, replayed
                        TestEvent {
                            id: sim
                        }
                        Timer {
                            id: replay
                            property var path: []
                            interval: 16
                            repeat: true
                            onTriggered: {
                                const p = path.shift();
                                if (p.up)
                                    sim.mouseRelease(grab, p.x, p.y, Qt.LeftButton, Qt.NoModifier, -1);
                                else
                                    sim.mouseMove(grab, p.x, p.y, -1, Qt.LeftButton, Qt.NoModifier);
                                if (!path.length)
                                    stop();
                            }
                        }
                        Connections {
                            target: Angel
                            enabled: Shell.dev
                            function onDevDrag(ddx, ddy, ms) {
                                const x0 = grab.width / 2, y0 = grab.height / 2, n = Math.max(2, Math.round(ms / 16));
                                sim.mousePress(grab, x0, y0, Qt.LeftButton, Qt.NoModifier, -1);
                                const path = [];
                                for (let i = 1; i <= n; i++)
                                    path.push({
                                        "x": x0 + ddx * i / n,
                                        "y": y0 + ddy * i / n
                                    });
                                path.push({
                                    "x": x0 + ddx,
                                    "y": y0 + ddy,
                                    "up": true
                                });
                                replay.path = path;
                                replay.start();
                            }
                        }
                        // back to her place with a little bounce
                        ParallelAnimation {
                            id: spring
                            NumberAnimation {
                                target: grab
                                property: "dx"
                                to: 0
                                duration: 320
                                easing.type: Easing.OutBack
                            }
                            NumberAnimation {
                                target: grab
                                property: "dy"
                                to: 0
                                duration: 320
                                easing.type: Easing.OutBack
                            }
                        }
                    }
                }
            }

            RightClickGuard {}
        }
    }
}
