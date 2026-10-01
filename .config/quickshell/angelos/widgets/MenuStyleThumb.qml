import QtQuick
import qs.config

// A small picture of a right-click menu look (Settings → Right-click menu, the setup
// wizard): list | radial | y2k | tiles | pentagram.
Item {
    id: root

    property string style: "list"
    implicitWidth: Theme.u * 58
    implicitHeight: Theme.u * 42

    // the wallpaper
    Rectangle {
        anchors.fill: parent
        color: root.style === "pentagram" ? "#1a0508" : Theme.mix(Theme.desk, Theme.accent, 0.12)
        border.width: Math.max(1, Theme.u / 2)
        border.color: Theme.lo
    }

    // list: the Windows 11-like menu
    Rectangle {
        visible: root.style === "list"
        x: Theme.u * 12
        y: Theme.u * 5
        width: Theme.u * 34
        height: Theme.u * 32
        color: Theme.menuSurface
        border.width: Math.max(1, Theme.u / 2)
        border.color: Theme.edge
        Row {
            x: Theme.u * 3
            y: Theme.u * 3
            spacing: Theme.u * 2
            Repeater {
                model: 4
                Rectangle {
                    width: Theme.u * 5
                    height: Theme.u * 5
                    color: Theme.accent
                }
            }
        }
        Column {
            x: Theme.u * 3
            y: Theme.u * 11
            spacing: Theme.u * 2
            Repeater {
                model: 5
                Rectangle {
                    required property int index
                    width: index === 1 ? Theme.u * 28 : Theme.u * (18 + index * 2)
                    height: Theme.u * 2
                    color: index === 1 ? Theme.accent : Theme.textDim
                }
            }
        }
    }

    // radial: a ring of slots
    Item {
        visible: root.style === "radial"
        anchors.fill: parent
        Repeater {
            model: 8
            Rectangle {
                required property int index
                readonly property real a: -Math.PI / 2 + index * Math.PI / 4
                width: Theme.u * 6
                height: width
                color: index === 2 ? Theme.accent : Theme.menuSurface
                border.width: Math.max(1, Theme.u / 2)
                border.color: Theme.edge
                x: root.width / 2 + Math.cos(a) * Theme.u * 14 - width / 2
                y: root.height / 2 + Math.sin(a) * Theme.u * 14 - height / 2
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: Theme.u * 7
            height: width
            color: Theme.accent
            border.width: Math.max(1, Theme.u / 2)
            border.color: Theme.edge
        }
    }

    // y2k: the glossy bubble
    Item {
        visible: root.style === "y2k"
        x: Theme.u * 12
        y: Theme.u * 5
        width: Theme.u * 34
        height: Theme.u * 32
        Y2kGloss {
            anchors.fill: parent
            radius: Theme.u * 5
            sparkles: false
        }
        Column {
            x: Theme.u * 3
            y: Theme.u * 7
            spacing: Theme.u * 2
            Repeater {
                model: 5
                Rectangle {
                    required property int index
                    width: Theme.u * 28
                    height: Theme.u * 3
                    radius: height / 2
                    color: index === 1 ? Theme.accent : Qt.alpha(Theme.text, 0.25)
                }
            }
        }
    }

    // tiles: a frosted grid
    Rectangle {
        visible: root.style === "tiles"
        x: Theme.u * 10
        y: Theme.u * 5
        width: Theme.u * 38
        height: Theme.u * 32
        radius: Theme.u * 4
        color: Qt.alpha(Theme.menuSurface, 0.9)
        border.width: Math.max(1, Theme.u / 2)
        border.color: Qt.alpha("#ffffff", 0.3)
        Grid {
            x: Theme.u * 3
            y: Theme.u * 4
            columns: 3
            spacing: Theme.u * 2
            Repeater {
                model: 6
                Rectangle {
                    required property int index
                    width: Theme.u * 9
                    height: Theme.u * 11
                    radius: Theme.u * 2
                    color: index === 4 ? Theme.accent : Qt.alpha(Theme.faceAlt, 0.9)
                }
            }
        }
    }

    // pentagram: hell's own
    Canvas {
        visible: root.style === "pentagram"
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const cx = width / 2, cy = height / 2, r = Math.min(width, height) * 0.38;
            ctx.strokeStyle = "#e0203a";
            ctx.lineWidth = Math.max(1, Theme.u);
            ctx.beginPath();
            ctx.arc(cx, cy, r + Theme.u * 2, 0, Math.PI * 2);
            ctx.stroke();
            ctx.beginPath();
            for (let k = 0; k <= 5; k++) {
                const a = -Math.PI / 2 + (k * 2 % 5) * 2 * Math.PI / 5;
                const x = cx + Math.cos(a) * r, y = cy + Math.sin(a) * r;
                if (k === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            ctx.stroke();
            ctx.fillStyle = "#ff7a2a";
            for (let k = 0; k < 5; k++) {
                const a = -Math.PI / 2 + k * 2 * Math.PI / 5;
                ctx.fillRect(cx + Math.cos(a) * r - Theme.u * 2, cy + Math.sin(a) * r - Theme.u * 2, Theme.u * 4, Theme.u * 4);
            }
        }
    }
}
