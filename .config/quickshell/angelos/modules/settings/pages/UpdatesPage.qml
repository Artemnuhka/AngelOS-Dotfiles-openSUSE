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
    subtitle: I18n.t("angelOS обновляется из репозитория dotfiles, из которого его установили: git pull и установщик без пакетов. Сначала снимок всех файлов, которые он может заменить, — если что-то пойдёт не так, отсюда же можно вернуть как было. Конфиги, которые ты менял, установщик не трогает.", "angelOS updates from the dotfiles repository it was installed from: git pull and the installer without packages. First a snapshot of every file it may replace — if something goes wrong, you can go back from here. Configs you changed are left alone.")

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
        // stopped before the snapshot: nothing was changed, but say why
        PxText {
            visible: Updates.lastRun === "failed" && !Updates.canRestore && !!Updates.failure
            width: parent.width
            wrapMode: Text.Wrap
            color: Theme.danger
            text: "✕ " + Updates.failure
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
                visible: Updates.needsRestart
                accent: true
                icon: "power"
                text: I18n.t("Перезапустить оболочку", "Restart the shell")
                onClicked: Updates.restartShell()
            }
        }
        PxText {
            visible: Updates.needsRestart
            width: parent.width
            wrapMode: Text.Wrap
            color: Theme.accent
            text: Updates.restored ? I18n.t("Прежняя версия возвращена на диск, но в памяти ещё та, что была запущена, — перезапусти оболочку.", "The previous version is back on disk, but the one in memory is still running — restart the shell.") : I18n.t("Новая версия установлена, но работает ещё прошлая — она загрузится после перезапуска оболочки или следующего входа.", "The new version is installed, but the previous one is still running: it loads after a shell restart or the next login.")
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

    // the last attempt went wrong: what, where its snapshot is, the way back
    PxGroup {
        id: failedGroup
        visible: Updates.canRestore || Updates.lastStatus === "restored" && Updates.conflicts.length > 0
        title: Updates.lastStatus === "restored" ? I18n.t("Возвращено как было", "Restored") : Updates.lastStatus === "restore-failed" ? I18n.t("Вернуть не получилось", "The restore failed") : I18n.t("Обновление не установлено", "The update is not installed")
        icon: Updates.lastStatus === "restored" ? "heart" : "warn"
        width: parent.width

        PxText {
            visible: Updates.lastStatus !== "restored"
            width: parent.width
            wrapMode: Text.Wrap
            color: Theme.danger
            text: "✕ " + (Updates.lastStatus === "restore-failed" ? "" : Updates.stageText(Updates.failedStage) + (Updates.failure && Updates.failure !== Updates.stageText(Updates.failedStage) ? ": " : "")) + (Updates.failure && Updates.failure !== Updates.stageText(Updates.failedStage) ? Updates.failure : "")
        }
        PxText {
            visible: Updates.lastStatus !== "restored"
            width: parent.width
            wrapMode: Text.Wrap
            text: Updates.lastStatus === "restore-failed" ? I18n.t("Снимок цел, ничего из него не потеряно. Подробности — в журнале ниже; можно поправить и попробовать ещё раз.", "The snapshot is intact, nothing from it is lost. Details are in the log below; fix it and try again.") : I18n.t("Часть файлов могла уже смениться. Перед обновлением всё, что оно трогает, сохранено — можно вернуть систему к состоянию до этой попытки. Файлы, которые ты успел изменить после неё, останутся как есть.", "Some files may already have changed. Everything the update touches was saved first — you can put the system back to how it was before this attempt. Files you changed after it stay as they are.")
        }
        SettingRow {
            label: I18n.t("Снимок", "Snapshot")
            hint: I18n.t("резервная копия до обновления", "the copy taken before the update")
            PxText {
                width: parent.width
                wrapMode: Text.WrapAnywhere
                kind: "mono"
                text: Updates.backupDir
            }
        }
        PxButton {
            visible: Updates.canRestore
            icon: "refresh"
            accent: true
            enabled: !Updates.busy
            text: Updates.state === "restoring" ? I18n.t("возвращаю…", "restoring…") : I18n.t("Вернуть как было до обновления", "Restore the state before the update")
            onClicked: Updates.restore()
        }
        PxText {
            visible: Updates.conflicts.length > 0
            width: parent.width
            wrapMode: Text.Wrap
            color: Theme.accent3
            text: I18n.t("Эти файлы изменились уже после обновления — оставлены как есть (версия до обновления лежит в снимке):", "These files changed after the update — kept as they are (the version from before is in the snapshot):")
        }
        Repeater {
            model: Updates.conflicts
            PxText {
                required property string modelData
                width: parent.width
                elide: Text.ElideMiddle
                kind: "mono"
                text: "• " + modelData.replace(Config.home + "/", "~/")
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
