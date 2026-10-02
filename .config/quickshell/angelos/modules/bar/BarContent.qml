import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Left / center / right sections from BarLayout. `inline` packs everything in one row (island,
// dock). Capsules: the full-width layout, each section as wide as it needs (the window draws
// a capsule behind each: leftBox / centerBox / rightBox give their places). In hell
// (BarLayout.hell) every pixel of the content takes one of four colours of the circle's
// palette (shaders/hell_bar_ink.frag: face, dim, text, accent — each checked against the
// plate), and `hellPlates` tells the window's HellBarFrame where the runs of widgets are,
// so they sit on a calm plate and never on the pattern. The dock stays as it is in hell.
Item {
    id: root

    required property string screenName
    required property var barWindow
    required property string style        // BarLayout.styles
    readonly property bool hug: style === "capsules"
    property bool compact: false
    property bool inline: false
    property int itemHeight: Theme.u * 15
    readonly property bool above: style === "taskbar" || style === "dock" || style === "windose"
    // the sections, for the capsules behind them (CapsuleWindow)
    readonly property alias leftBox: left
    readonly property alias centerBox: center
    readonly property alias rightBox: right
    readonly property bool hellInk: BarLayout.hell && style !== "dock"
    layer.enabled: hellInk
    layer.effect: ShaderEffect {
        fragmentShader: Qt.resolvedUrl("../../shaders/hell_bar_ink.frag.qsb")
        property color plate: Theme.hellPlate
        property color face: Theme.mix(Theme.hellRim, Theme.hellFace, 0.4)
        property color dim: Theme.hellTextDim
        property color text: Theme.hellText
        property color accent: Theme.hellAccent
    }
    // where a section's widgets really are, in its own coordinates: [from, to] or null (a
    // stretched "Windows" counts as wide as its buttons)
    function usedRange(sec) {
        let a = Infinity, b = -Infinity;
        for (const c of sec.children) {
            if (c.wid === undefined || !c.visible || c.width <= 0)
                continue;
            const w = c.wid === "tasks" && c.item && c.item.naturalWidth !== undefined ? Math.min(c.width, c.item.naturalWidth) : c.width;
            if (w <= 0)
                continue;
            a = Math.min(a, c.x);
            b = Math.max(b, c.x + w);
        }
        return a < b ? [a, b] : null;
    }
    // the runs of widgets in hell, in this item's coordinates: [{x, y, w, h}]
    readonly property var hellPlates: {
        if (!hellInk)
            return [];
        const out = [];
        const pad = Theme.u * 2;
        const h = itemHeight + Theme.u * 2;
        const y = Math.round((height - h) / 2);
        const secs = inline ? [[inlineRow.children[0], inlineRow], [inlineRow.children[1], inlineRow], [inlineRow.children[2], inlineRow]] : [[left, full], [center, full], [right, full]];
        for (const [sec, holder] of secs) {
            if (!sec || !sec.visible)
                continue;
            const r = usedRange(sec);
            if (!r)
                continue;
            const x0 = holder.x + sec.x + r[0] - pad;
            out.push({
                "x": x0,
                "y": y,
                "w": r[1] - r[0] + pad * 2,
                "h": h
            });
        }
        return out;
    }
    readonly property var layout: BarLayout.effective
    readonly property bool lyricsShown: BarLayout.has("lyrics") && Config.lyrics.enabled && Lyrics.visibleToggle && Lyrics.hasLyrics && (!Config.lyrics.screens.length || Config.lyrics.screens.includes(screenName))
    readonly property int gap: Theme.u * 4

    Component.onCompleted: Shell.barViews[screenName] = root
    Component.onDestruction: {
        if (Shell.barViews[screenName] === root)
            delete Shell.barViews[screenName];
    }
    function diagnostics() {
        return {
            width: width,
            lyricsShown: lyricsShown,
            leftWidth: left.width,
            leftImplicit: left.implicitWidth,
            rightX: right.x,
            rightWidth: right.width,
            centerX: center.x,
            centerWidth: center.width,
            centerImplicit: center.implicitWidth,
            leftNeed: center.leftNeed,
            lyricsMax: center.lyricsMax
        };
    }
    implicitWidth: inline ? inlineRow.implicitWidth : 0
    implicitHeight: itemHeight

    // Behind the widgets: right-clicks on task buttons keep their own action.
    ContextClick {
        anchors.fill: parent
        onMenu: (x, y) => panelMenu.openAt(x, y)
    }
    PanelMenu {
        id: panelMenu
        anchorItem: root
        above: root.above
    }
    // Over the widgets: any press on the bar closes the open popup first (the
    // grab of an xdg popup does not end on clicks inside the same client), then
    // lets the press through to whatever is underneath.
    MouseArea {
        anchors.fill: parent
        z: 100
        acceptedButtons: Qt.AllButtons
        onPressed: mouse => {
            PopupManager.barPressed();
            mouse.accepted = false;
        }
    }

    // ---- inline (island) ----
    Row {
        id: inlineRow
        visible: root.inline
        anchors.centerIn: parent
        spacing: Theme.u * 5
        BarSection {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.layout.left.length > 0
            ids: root.inline ? root.layout.left : []
            bar: root
            centered: root.style === "dock"
            lyricsMax: root.compact ? Theme.u * 110 : Theme.u * 200
        }
        BarSection {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.layout.center.length > 0
            ids: root.inline ? root.layout.center : []
            bar: root
            centered: root.style === "dock"
            lyricsMax: root.compact ? Theme.u * 110 : Theme.u * 200
        }
        BarSection {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.layout.right.length > 0
            ids: root.inline ? root.layout.right : []
            bar: root
            centered: root.style === "dock"
            lyricsMax: root.compact ? Theme.u * 110 : Theme.u * 200
            density: Config.bar.rightDensity || "normal"
        }
    }

    // ---- full width (taskbar / top) ----
    Item {
        id: full
        anchors.fill: parent
        visible: !root.inline

        readonly property bool tasksLeft: root.layout.left.includes("tasks")
        readonly property real mid: width / 2
        // Settings → Bar → Start → "Taskbar": like Windows 11, Start with the window buttons in
        // the middle (they slide there and back); the lyrics then take the room on the left
        readonly property bool centered: Config.bar.taskbarAlign === "center"

        // sunken Win98 notification area behind the right side of the taskbar
        PxBox {
            visible: (root.style === "taskbar") && right.implicitWidth > 0 && !root.hellInk
            x: right.x - Theme.u * 4
            width: right.width + Theme.u * 6
            height: root.itemHeight
            anchors.verticalCenter: parent.verticalCenter
            sunken: true
            outline: false
            color: Qt.alpha(Theme.sunken, 0.35)
        }

        BarSection {
            id: right
            anchors.right: parent.right
            anchors.rightMargin: Theme.u * 2
            anchors.verticalCenter: parent.verticalCenter
            ids: root.inline ? [] : root.layout.right
            bar: root
            lyricsMax: Theme.u * 150
            density: Config.bar.rightDensity || "normal"
        }

        BarSection {
            id: center
            anchors.verticalCenter: parent.verticalCenter
            x: parent.centered && !root.hug ? Theme.u * 2 : Math.round(Math.max(leftNeed, Math.min(parent.mid - width / 2, right.x - root.gap - width)))
            ids: root.inline ? [] : root.layout.center
            bar: root
            // widest centred run that still leaves room for the left side (+ a few task buttons) and the right side
            readonly property real leftNeed: Theme.u * 2 + left.implicitWidth + (parent.tasksLeft && !root.hug ? (root.compact ? Theme.u * 4 : Theme.u * 44) : 0) + root.gap + (root.hug ? Theme.u * 10 : 0)
            // the lyrics box takes the song's longest line, up to all the room between the sides
            // (centred taskbar: the room left of the centred group)
            lyricsMax: parent.centered && !root.hug ? Math.max(0, left.x - root.gap - Theme.u * 2 - (root.layout.center.length > 1 ? Theme.u * 60 : 0)) : Math.max(0, Math.min(parent.width * 0.6, right.x - root.gap - leftNeed - (root.hug ? Theme.u * 10 : 0) - (root.layout.center.length > 1 ? Theme.u * 60 : 0)))
        }

        BarSection {
            id: left
            anchors.verticalCenter: parent.verticalCenter
            // left: from the edge to the lyrics; centred: as wide as it needs, in the middle
            readonly property real room: right.x - root.gap - Theme.u * 2
            readonly property real centeredX: Math.round(Math.max(Theme.u * 2, Math.min((parent.width - width) / 2, right.x - root.gap - width)))
            x: parent.centered && !root.hug ? centeredX : Theme.u * 2
            width: parent.centered || root.hug ? Math.min(implicitWidth, room) : Math.max(implicitWidth, (center.implicitWidth > 0 && center.visible ? center.x : right.x - Theme.u * 6) - root.gap - x)
            ids: root.inline ? [] : root.layout.left
            bar: root
            fillTasks: !parent.centered && !root.hug
            centered: parent.centered || root.hug
            lyricsMax: Theme.u * 150
            // the Windows 11 slide when the alignment changes or a window button comes and goes
            Behavior on x {
                NumberAnimation {
                    duration: 320
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
