pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

PxPage {
    id: page

    heading: I18n.t("Монитор", "Monitor")
    subtitle: I18n.t("«Применить» меняет сразу, «Сохранить» пишет ~/.config/niri/monitor.kdl (с бэкапом и проверкой niri validate).", "Apply changes the live layout. Save to config writes monitor.kdl with a backup and niri validation.")

    property string selected: Object.keys(Outputs.draft)[0] || ""
    readonly property var d: Outputs.draft[selected] || null
    readonly property var o: Outputs.outputs[selected] || null

    function logicalSize(name) {
        const dd = Outputs.draft[name];
        if (!dd || !dd.mode)
            return [1920, 1080];
        const m = dd.mode.match(/(\d+)x(\d+)/);
        let w = parseInt(m[1]), h = parseInt(m[2]);
        if (/90|270/.test(dd.transform))
            [w, h] = [h, w];
        return [w / dd.scale, h / dd.scale];
    }

    PxGroup {
        title: I18n.t("Расположение", "Arrangement")
        icon: "monitor"
        width: parent.width

        PxBox {
            id: canvas
            width: parent.width
            height: Theme.u * 110
            sunken: true
            color: Qt.alpha(Theme.sunken, 0.8)

            readonly property var names: Object.keys(Outputs.draft).filter(n => !Outputs.draft[n].off)
            readonly property var bounds: {
                let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
                for (const n of names) {
                    const dd = Outputs.draft[n], s = page.logicalSize(n);
                    x0 = Math.min(x0, dd.x);
                    y0 = Math.min(y0, dd.y);
                    x1 = Math.max(x1, dd.x + s[0]);
                    y1 = Math.max(y1, dd.y + s[1]);
                }
                return names.length ? [x0, y0, x1, y1] : [0, 0, 1920, 1080];
            }
            readonly property real k: Math.min((width - Theme.u * 20) / (bounds[2] - bounds[0]), (height - Theme.u * 20) / (bounds[3] - bounds[1]))
            readonly property real ox: (width - (bounds[2] - bounds[0]) * k) / 2
            readonly property real oy: (height - (bounds[3] - bounds[1]) * k) / 2

            Repeater {
                model: canvas.names
                Item {
                    id: mon
                    required property string modelData
                    readonly property var dd: Outputs.draft[modelData]
                    readonly property var sz: page.logicalSize(modelData)
                    x: canvas.ox + (dd.x - canvas.bounds[0]) * canvas.k
                    y: canvas.oy + (dd.y - canvas.bounds[1]) * canvas.k
                    width: sz[0] * canvas.k
                    height: sz[1] * canvas.k

                    PxBox {
                        anchors.fill: parent
                        color: page.selected === mon.modelData ? Theme.mix(Theme.face, Theme.accent, 0.35) : Theme.face
                        edgeColor: page.selected === mon.modelData ? Theme.accent : Theme.edge
                        Column {
                            anchors.centerIn: parent
                            PxIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                name: "monitor"
                            }
                            PxText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: mon.modelData
                                font.bold: true
                            }
                            PxText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Math.round(mon.dd.x) + ", " + Math.round(mon.dd.y)
                                kind: "tiny"
                                dim: true
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeAllCursor
                        property point start
                        property point orig
                        onPressed: m => {
                            page.selected = mon.modelData;
                            start = mapToItem(canvas, m.x, m.y);
                            orig = Qt.point(mon.dd.x, mon.dd.y);
                        }
                        onPositionChanged: m => {
                            if (!pressed)
                                return;
                            const p = mapToItem(canvas, m.x, m.y);
                            let nx = orig.x + (p.x - start.x) / canvas.k;
                            let ny = orig.y + (p.y - start.y) / canvas.k;
                            // snap to other monitors' edges
                            const snap = 40;
                            for (const other of canvas.names) {
                                if (other === mon.modelData)
                                    continue;
                                const od = Outputs.draft[other], os = page.logicalSize(other);
                                for (const [a, b] of [[nx, od.x + os[0]], [nx + mon.sz[0], od.x], [nx, od.x], [nx + mon.sz[0], od.x + os[0]]])
                                    if (Math.abs(a - b) < snap)
                                        nx += b - a;
                                for (const [a, b] of [[ny, od.y + os[1]], [ny + mon.sz[1], od.y], [ny, od.y], [ny + mon.sz[1], od.y + os[1]]])
                                    if (Math.abs(a - b) < snap)
                                        ny += b - a;
                            }
                            Outputs.set(mon.modelData, "x", Math.round(nx));
                            Outputs.set(mon.modelData, "y", Math.round(ny));
                        }
                    }
                }
            }
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 3
            Repeater {
                model: Object.keys(Outputs.draft)
                PxButton {
                    required property string modelData
                    text: modelData
                    icon: "monitor"
                    checked: page.selected === modelData
                    onClicked: page.selected = modelData
                }
            }
        }
    }

    PxGroup {
        visible: !!page.d
        title: page.selected + (page.o ? "  ·  " + (page.o.make || "") + " " + (page.o.model || "") : "")
        icon: "gear"
        width: parent.width

        SettingRow {
            label: I18n.t("Включён", "Enabled")
            PxToggle {
                checked: page.d ? !page.d.off : false
                onToggled: c => Outputs.set(page.selected, "off", !c)
            }
        }
        SettingRow {
            label: I18n.t("Режим", "Mode")
            PxCombo {
                width: parent.width
                model: page.o ? page.o.modes.map(m => ({
                            "label": Outputs.modeLabel(m),
                            "value": Outputs.modeString(m)
                        })) : []
                currentValue: page.d ? page.d.mode : ""
                onActivated: v => Outputs.set(page.selected, "mode", v)
            }
        }
        SettingRow {
            label: I18n.t("Масштаб", "Scale")
            PxSpin {
                from: 0.5
                to: 3
                stepSize: 0.05
                decimals: 2
                value: page.d ? page.d.scale : 1
                onMoved: v => Outputs.set(page.selected, "scale", v)
            }
        }
        SettingRow {
            label: I18n.t("Поворот", "Rotation")
            PxCombo {
                width: Theme.u * 100
                model: Outputs.transforms
                currentValue: page.d ? page.d.transform : "normal"
                onActivated: v => Outputs.set(page.selected, "transform", v)
            }
        }
        SettingRow {
            label: I18n.t("Позиция", "Position")
            Row {
                spacing: Theme.u * 3
                PxField {
                    width: Theme.u * 40
                    text: page.d ? String(Math.round(page.d.x)) : "0"
                    onAccepted: Outputs.set(page.selected, "x", parseInt(text) || 0)
                }
                PxField {
                    width: Theme.u * 40
                    text: page.d ? String(Math.round(page.d.y)) : "0"
                    onAccepted: Outputs.set(page.selected, "y", parseInt(text) || 0)
                }
            }
        }
        SettingRow {
            label: "VRR / FreeSync"
            hint: page.o && !page.o.vrr_supported ? I18n.t("монитор не поддерживает", "Not supported by the display") : ""
            PxToggle {
                enabled: page.o ? !!page.o.vrr_supported : false
                checked: page.d ? page.d.vrr : false
                onToggled: c => Outputs.set(page.selected, "vrr", c)
            }
        }
    }

    Row {
        spacing: Theme.u * 4
        PxButton {
            text: I18n.t("Применить", "Apply")
            icon: "check"
            accent: true
            enabled: !Outputs.busy
            onClicked: Outputs.apply()
        }
        PxButton {
            text: I18n.t("Сохранить в конфиг", "Save to config")
            icon: "package"
            enabled: !Outputs.busy
            onClicked: Outputs.save()
        }
        PxButton {
            text: I18n.t("Сбросить", "Reset")
            icon: "refresh"
            onClicked: Outputs.refresh()
        }
    }
    PxText {
        width: parent.width
        wrapMode: Text.Wrap
        text: Outputs.log
        dim: true
    }
}
