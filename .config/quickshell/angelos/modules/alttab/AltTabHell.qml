pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Alt+Tab while the demon rules (Y2K → Angel or demon → Alt+Tab in hell: "hell's own"):
// an obsidian "inferno.exe" window licked by flames, blood dripping off its foot. The
// windows are slabs of obsidian; the pick burns — flames rise from its foot, its rim
// glows, little horns sit on its corner — and a pentagram draws itself under it and
// follows it around. Workspaces are hell's circles: "circle III".
Item {
    id: root

    required property var host
    readonly property int s: Theme.u
    readonly property int cell: s * 46
    readonly property int perRow: Math.max(1, Math.min(AltTab.items.length, Math.floor(((host.screen ? host.screen.width : 1920) * 0.8) / (cell + s * 4))))
    // the window's flames above and its drips below need room inside the surface
    readonly property int above: s * 8
    readonly property int below: s * 9
    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight + above + below

    // drawn once as the switcher opens, then it simply follows the pick
    property real reveal: 0
    NumberAnimation on reveal {
        from: 0
        to: 1
        duration: 520
        easing.type: Easing.OutCubic
    }
    property real flameTime: 0
    Timer {
        interval: 140
        repeat: true
        running: root.visible
        onTriggered: root.flameTime += 0.14
    }

    function label(w) {
        return root.host.appName(w);
    }
    function circle(w) {
        const ws = w ? Niri.workspaceById(w.workspace_id) : null;
        if (!ws)
            return "";
        const names = Config.workspaces.names || {};
        const name = names[ws.output + ":" + ws.idx] || ws.name || "";
        return (name ? name + " · " : "") + I18n.t("круг ", "circle ") + Theme.roman(ws.idx) + (Quickshell.screens.length > 1 ? " · " + ws.output : "");
    }

    PxWindow {
        id: frame
        y: root.above
        width: parent.width
        height: implicitHeight
        hell: true
        title: "inferno.exe"
        icon: "pentagram"
        compact: true
        closable: false
        translucent: true
        flamesLive: root.visible
        implicitWidth: grid.width + chrome * 2 + bodyPadding * 2
        implicitHeight: chrome * 2 + titleHeight + bodyPadding * 2 + grid.height + footer.height + root.s * 4

        Column {
            spacing: root.s * 4
            Item {
                width: grid.width
                height: grid.height

                // the sigil under the pick: draws itself as the switcher opens, then follows
                ShaderEffect {
                    id: sigil
                    // where the pick's card sits in the grid
                    readonly property int col: Math.max(0, AltTab.index) % root.perRow
                    readonly property int row: Math.floor(Math.max(0, AltTab.index) / root.perRow)
                    readonly property real d: root.cell * 1.75
                    width: d
                    height: d
                    x: col * (root.cell + grid.spacing) + root.cell / 2 - d / 2
                    y: row * (geo.cardH + grid.spacing) + geo.cardH / 2 - d / 2
                    z: -1
                    opacity: 0.9
                    Behavior on x {
                        NumberAnimation {
                            duration: 130
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on y {
                        NumberAnimation {
                            duration: 130
                            easing.type: Easing.OutCubic
                        }
                    }
                    property real progress: root.reveal
                    property real side: d
                    property real star: d * 0.34
                    property real ring: d * 0.44
                    property real u: root.s
                    property color blood: Theme.hellBlood
                    property color ember: Theme.hellEmber
                    fragmentShader: Qt.resolvedUrl("../../shaders/pentagram.frag.qsb")
                }
                QtObject {
                    id: geo
                    readonly property int cardH: root.cell + (Config.alttab.titles ? root.s * 10 : 0)
                }

                Grid {
                    id: grid
                    columns: root.perRow
                    spacing: root.s * 4
                    Repeater {
                        model: AltTab.items
                        Item {
                            id: card
                            required property var modelData
                            required property int index
                            readonly property bool picked: index === AltTab.index
                            width: root.cell
                            height: root.cell + (Config.alttab.titles ? root.s * 10 : 0)

                            PxBox {
                                anchors.fill: parent
                                hell: true
                                sunken: !card.picked
                                outline: card.picked || mouse.containsMouse
                                color: card.picked ? Qt.alpha(Theme.hellFaceAlt, 0.72) : mouse.containsMouse ? Qt.alpha(Theme.hellFace, 0.85) : Qt.alpha(Theme.hellSunken, 0.78)
                                edgeColor: card.picked ? Theme.hellEmber : Theme.hellEdge
                                hiColor: card.picked ? Theme.hellBlood : Theme.hellHi
                                loColor: Theme.hellLo
                            }
                            // the pick burns: flames rise from its foot, inside the slab
                            Item {
                                anchors.fill: parent
                                anchors.margins: root.s * 2
                                clip: true
                                visible: card.picked
                                ShaderEffect {
                                    readonly property int rows: 9
                                    width: parent.width
                                    height: root.s * rows
                                    y: parent.height - height
                                    opacity: 0.9
                                    property real time: root.flameTime
                                    property real seed: card.index * 1.7
                                    property size cells: Qt.size(Math.max(1, Math.round(width / root.s)), rows)
                                    fragmentShader: Qt.resolvedUrl("../../shaders/hell_flames.frag.qsb")
                                }
                            }
                            AppIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: root.s * 7 - (card.picked ? root.s : 0)
                                appId: card.modelData.app_id || ""
                                size: root.s * 26
                                opacity: card.picked ? 1 : 0.62
                                Behavior on y {
                                    NumberAnimation {
                                        duration: 120
                                    }
                                }
                            }
                            PxText {
                                visible: Config.alttab.titles
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: root.s * 3
                                width: parent.width - root.s * 4
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: root.label(card.modelData)
                                kind: "tiny"
                                font.bold: card.picked
                                color: card.picked ? Theme.hellFlame : Theme.hellTextDim
                                // readable over the flames
                                style: card.picked ? Text.Outline : Text.Normal
                                styleColor: Theme.hellEdge
                            }
                            // little horns on the pick's corner
                            PxIcon {
                                visible: card.picked
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: root.s * 2
                                pixel: root.s
                                bitmap: ["#.....#", "o#...#o", "oo#.#oo", ".ooooo."]
                                ink: Theme.hellEdge
                                fill: Theme.hellBlood
                            }
                            MouseArea {
                                id: mouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: AltTab.select(card.index)
                                onClicked: {
                                    AltTab.select(card.index);
                                    AltTab.commit();
                                }
                            }
                        }
                    }
                }
            }
            // the pick's full title and its circle of hell
            Column {
                id: footer
                width: grid.width
                spacing: root.s
                PxText {
                    readonly property string t: AltTab.current ? (Niri.titleOf(AltTab.current) || root.label(AltTab.current)) : ""
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideMiddle
                    text: "⛧ " + t
                    font.bold: true
                    color: Theme.hellFlame
                }
                PxText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.circle(AltTab.current)
                    kind: "tiny"
                    color: Theme.hellTextDim
                }
            }
        }
    }
}
