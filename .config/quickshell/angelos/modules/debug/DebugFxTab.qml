pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// Every effect on its own: each kind of what her fist breaks, each prank, the quakes, the
// rays, each circle's splash, hell's rare events. On her screen; the usual conditions hold
// (no effects on a streamed screen or over a fullscreen window).
Column {
    id: root

    spacing: Theme.u * 5

    PxGroup {
        width: parent.width
        title: I18n.t("Что она ломает", "What she breaks")
        icon: "warn"
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            kind: "tiny"
            text: I18n.t("Набор этого круга (circles.json → breakage): ", "This circle's set (circles.json → breakage): ") + HellLook.breakage.join(", ") + I18n.t(" · сейчас: ", " · now: ") + (Cracks.on ? Cracks.kind + (Cracks.falling ? I18n.t(" (выпадает)", " (falling)") : "") : "—") + I18n.t(" · настройка трещин: ", " · cracks setting: ") + Config.y2k.cracks
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 2
            PxButton {
                compact: true
                icon: "fire"
                text: I18n.t("Удар по кругу", "A punch by the circle")
                onClicked: GameDebug.punch("")
            }
            Repeater {
                model: HellLook.breakageKinds
                PxButton {
                    required property string modelData
                    compact: true
                    checked: Cracks.on && Cracks.kind === modelData
                    text: modelData
                    onClicked: GameDebug.punch(modelData)
                }
            }
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 2
            PxButton {
                compact: true
                icon: "arrowDown"
                enabled: Cracks.on && !Cracks.falling
                text: I18n.t("Стекло выпадает", "The glass falls out")
                onClicked: GameDebug.shatter()
            }
            PxButton {
                compact: true
                icon: "close"
                enabled: Cracks.on
                text: I18n.t("Убрать сразу", "Gone at once")
                onClicked: Cracks.on = false
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Проделки демоницы", "The demon's pranks")
        icon: "skull"
        PxText {
            width: parent.width
            wrapMode: Text.Wrap
            dim: true
            kind: "tiny"
            text: Angel.demon ? I18n.t("Меняют настоящие настройки; «Верни!» в её пузыре или «Вернуть все» здесь. Сделаны: ", "They change real settings; “Undo!” in her bubble or “Undo all” here. Done: ") + ((Story.player.pranks || []).map(p => p.id + (p.undone ? "↺" : "")).join(", ") || "—") : I18n.t("Только пока в углу демоница.", "Only while the demon is in the corner.")
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 2
            Repeater {
                model: Angel.pranks.map(p => p.id)
                PxButton {
                    required property string modelData
                    compact: true
                    enabled: Angel.demon
                    text: modelData
                    onClicked: GameDebug.prank(modelData)
                }
            }
            PxButton {
                compact: true
                icon: "refresh"
                enabled: (Story.player.pranks || []).some(p => !p.undone)
                text: I18n.t("Вернуть все", "Undo all")
                onClicked: GameDebug.note(I18n.t("возвращено: ", "undone: ") + Angel.undoAllPranks())
            }
        }
    }

    PxGroup {
        width: parent.width
        title: I18n.t("Тряска, лучи, переходы", "Quakes, rays, transitions")
        icon: "sparkle"
        Flow {
            width: parent.width
            spacing: Theme.u * 2
            PxButton {
                compact: true
                icon: "fire"
                text: I18n.t("Землетрясение ада", "Hell's quake")
                onClicked: GameDebug.quake("hell")
            }
            PxButton {
                compact: true
                icon: "sun"
                text: I18n.t("Тряска рая", "Heaven's quake")
                onClicked: GameDebug.quake("heaven")
            }
            PxButton {
                compact: true
                icon: "sun"
                text: I18n.t("Лучи и хор", "Rays and the choir")
                onClicked: GameDebug.rays()
            }
            PxButton {
                compact: true
                icon: "ghost"
                enabled: Angel.demon
                text: I18n.t("Событие ада (раз в несколько минут)", "Hell's rare event")
                onClicked: {
                    HellAmbient.now();
                    GameDebug.note(I18n.t("событие ада: ", "hell's event: ") + (HellLook.ambient || "—"));
                }
            }
            PxButton {
                compact: true
                icon: "bot"
                enabled: Angel.demon
                text: I18n.t("Цербер", "Cerberus")
                onClicked: HellFx.cerberus(GameDebug.screen)
            }
            PxButton {
                compact: true
                icon: "cursor"
                enabled: Angel.demon
                text: I18n.t("Проклятый курсор", "Cursed cursor")
                onClicked: Angel.curseCursor()
            }
            PxButton {
                compact: true
                icon: "refresh"
                enabled: Angel.demon
                text: I18n.t("Колесо Ада (сброс ожидания)", "Wheel of Hell (no wait)")
                onClicked: {
                    Story.player.wheelAt = 0;
                    GameDebug.note(Angel.wheelSpin(GameDebug.screen) ? "wheel" : I18n.t("не крутится", "won't spin"));
                }
            }
        }
        Flow {
            width: parent.width
            spacing: Theme.u * 2
            PxText {
                height: Theme.sizeBody + Theme.u * 6
                verticalAlignment: Text.AlignVCenter
                text: I18n.t("Заставка круга:", "A circle's splash:")
            }
            Repeater {
                model: Story.order
                PxButton {
                    required property string modelData
                    compact: true
                    text: Theme.roman(Story.circleN(modelData))
                    onClicked: GameDebug.circleShow(modelData)
                }
            }
        }
    }
}
