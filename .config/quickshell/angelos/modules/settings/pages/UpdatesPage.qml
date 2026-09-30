pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.config
import qs.services
import qs.widgets

// Updates for everyone: check the dotfiles repository and apply new versions.
PxPage {
    id: page

    heading: I18n.t("Обновления", "Updates")
    subtitle: I18n.t("angelOS обновляется из репозитория dotfiles, из которого его установили: git pull и установщик без пакетов. Перед этим снимок конфигов, заменённые файлы остаются как *.bak.", "angelOS updates from the dotfiles repository it was installed from: git pull and the installer without packages. A snapshot of your configs is taken first; replaced files stay as *.bak.")

    Component.onCompleted: {
        Updates.find();
        if (Updates.repo && Updates.state === "idle")
            Updates.check();
    }

    PxGroup {
        title: I18n.t("Состояние", "Status")
        icon: "download"
        width: parent.width

        // no repository yet: offer the official one
        Column {
            visible: !Updates.repo
            width: parent.width
            spacing: Theme.u * 4
            PxText {
                width: parent.width
                wrapMode: Text.Wrap
                text: I18n.t("Репозиторий dotfiles не найден. Скачать официальный в ~/.local/share/angelos/dotfiles, чтобы получать обновления?", "No dotfiles repository found. Download the official one to ~/.local/share/angelos/dotfiles to receive updates?")
            }
            PxButton {
                icon: "download"
                accent: true
                enabled: !Updates.busy
                text: Updates.state === "cloning" ? I18n.t("скачиваю…", "downloading…") : I18n.t("Скачать dotfiles", "Download dotfiles")
                onClicked: Updates.clone()
            }
        }

        SettingRow {
            visible: !!Updates.repo
            label: I18n.t("Репозиторий", "Repository")
            hint: Updates.remote
            PxText {
                width: parent.width
                elide: Text.ElideMiddle
                text: Updates.repo + (Updates.branch ? "  ·  " + Updates.branch : "")
            }
        }
        SettingRow {
            visible: !!Updates.repo
            label: I18n.t("Новое", "New")
            hint: Config.updates.lastCheck ? I18n.t("проверено ", "checked ") + new Date(Config.updates.lastCheck).toLocaleString(Qt.locale(), "dd.MM HH:mm") : ""
            PxText {
                width: parent.width
                wrapMode: Text.Wrap
                color: Updates.available ? Theme.accent : Theme.textDim
                text: Updates.state === "checking" ? I18n.t("проверяю…", "checking…") : Updates.error ? "✕ " + Updates.error : Updates.available ? I18n.t("доступно изменений: ", "changes available: ") + Updates.behind : I18n.t("у тебя последняя версия ♡", "you are up to date ♡")
            }
        }
        PxText {
            visible: !Updates.trusted && !!Updates.repo
            width: parent.width
            wrapMode: Text.Wrap
            color: Theme.danger
            text: I18n.t("origin репозитория указывает не на официальный репозиторий и не на тот, из которого ставилась система — обновление отключено.", "The repository origin is neither the official one nor the one this system was installed from — updating is disabled.")
        }
        PxText {
            visible: Updates.dirty > 0
            width: parent.width
            wrapMode: Text.Wrap
            color: Theme.accent3
            text: I18n.t("В папке репозитория есть свои правки (" + Updates.dirty + "). Обновление остановится, чтобы их не потерять.", "The repository folder has local edits (" + Updates.dirty + "). The update stops so they are not lost.")
        }
        Flow {
            visible: !!Updates.repo
            width: parent.width
            spacing: Theme.u * 3
            PxButton {
                icon: "refresh"
                text: I18n.t("Проверить", "Check")
                enabled: !Updates.busy
                onClicked: Updates.check()
            }
            PxButton {
                icon: "download"
                accent: Updates.available
                enabled: !Updates.busy && Updates.dirty === 0 && Updates.trusted
                text: Updates.state === "updating" ? I18n.t("обновляю…", "updating…") : I18n.t("Обновить", "Update")
                onClicked: Updates.update()
            }
            PxButton {
                visible: Updates.state === "done"
                icon: "power"
                text: I18n.t("Перезапустить оболочку", "Restart the shell")
                onClicked: Updates.restartShell()
            }
        }
        SettingRow {
            label: I18n.t("Проверять раз в день", "Check once a day")
            hint: I18n.t("только уведомление, ставится по кнопке", "only a notification; installing is up to you")
            PxToggle {
                checked: Config.updates.autoCheck
                onToggled: c => Config.updates.autoCheck = c
            }
        }
    }

    PxGroup {
        visible: Updates.incoming.length > 0
        title: I18n.t("Что нового", "What's new")
        icon: "sparkle"
        width: parent.width
        Repeater {
            model: Updates.incoming
            PxText {
                required property string modelData
                width: parent.width
                elide: Text.ElideRight
                text: "✧ " + modelData.replace(/^\S+\s/, "")
            }
        }
    }

    PxGroup {
        visible: Updates.log.length > 0
        title: I18n.t("Журнал", "Log")
        icon: "terminal"
        width: parent.width
        PxBox {
            width: parent.width
            height: Theme.u * 110
            sunken: true
            color: Theme.sunken
            PxScroll {
                id: logScroll
                anchors.fill: parent
                anchors.margins: Theme.u * 3
                contentHeight: logText.implicitHeight
                PxText {
                    id: logText
                    width: logScroll.width - Theme.u * 6
                    kind: "mono"
                    wrapMode: Text.WrapAnywhere
                    textFormat: Text.PlainText
                    text: Updates.log.join("\n")
                    onTextChanged: Qt.callLater(() => logScroll.contentY = Math.max(0, logScroll.contentHeight - logScroll.height))
                }
            }
        }
    }
}
