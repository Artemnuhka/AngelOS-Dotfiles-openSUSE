pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

FloatingWindow {
    id: root
    title: "angelOS · " + I18n.t("Добро пожаловать", "Welcome")
    visible: Shell.setupOpen
    color: "transparent"
    implicitWidth: 920
    implicitHeight: 720
    minimumSize: Qt.size(720, 500)
    property int step: 0
    property bool offered: false
    readonly property var steps: [I18n.t("Привет", "Welcome"), I18n.t("Хоткеи", "Shortcuts"), I18n.t("Мониторы", "Monitors"), I18n.t("Ввод", "Input"), I18n.t("Окна", "Windows"), I18n.t("Тема", "Theme"), I18n.t("Готово", "Finish")]
    onClosed: Shell.setupOpen = false
    onVisibleChanged: if (!visible)
        Shell.setupOpen = false
    Timer {
        interval: 1200
        running: Config.ready && !Config.setup.complete && !root.offered && !Shell.dev
        onTriggered: {
            root.offered = true;
            Shell.setupOpen = true;
        }
    }
    BackgroundEffect.blurRegion: Config.appearance.blur ? setupBlur : null
    Region {
        id: setupBlur
        item: setupFrame
    }
    PxWindow {
        id: setupFrame
        anchors.fill: parent
        anchors.rightMargin: Theme.u * 2
        anchors.bottomMargin: Theme.u * 2
        title: "angelOS · " + root.steps[root.step]
        icon: "heart"
        onCloseClicked: Shell.setupOpen = false
        onTitlePressed: root.startSystemMove()
        Column {
            id: header
            width: parent.width
            spacing: Theme.u * 4
            Row {
                spacing: Theme.u * 6
                Repeater {
                    model: root.steps
                    PxButton {
                        required property string modelData
                        required property int index
                        compact: true
                        text: (index + 1) + ""
                        checked: root.step === index
                        onClicked: root.step = index
                    }
                }
            }
            Rectangle {
                width: parent.width
                height: Theme.u
                color: Theme.menuBorder
            }
        }
        Loader {
            anchors.top: header.bottom
            anchors.topMargin: Theme.u * 4
            anchors.bottom: footer.top
            anchors.bottomMargin: Theme.u * 5
            anchors.left: parent.left
            anchors.right: parent.right
            sourceComponent: root.step === 0 ? welcome : root.step === 1 ? shortcuts : root.step === 6 ? finish : settingsStep
        }
        Row {
            id: footer
            anchors.bottom: parent.bottom
            spacing: Theme.u * 5
            PxButton {
                text: I18n.t("Назад", "Back")
                enabled: root.step > 0
                onClicked: root.step--
            }
            PxButton {
                text: root.step === 6 ? I18n.t("Начать работу", "Start using angelOS") : I18n.t("Далее", "Next")
                accent: true
                onClicked: {
                    if (root.step < 6)
                        root.step++;
                    else {
                        Config.setup.complete = true;
                        Shell.setupOpen = false;
                    }
                }
            }
            PxButton {
                text: I18n.t("Настроить позже", "Set up later")
                onClicked: {
                    Config.setup.complete = true;
                    Shell.setupOpen = false;
                }
            }
        }
    }
    Component {
        id: settingsStep
        Loader {
            source: root.step === 2 ? "pages/MonitorPage.qml" : root.step === 3 ? "pages/KeyboardPage.qml" : root.step === 4 ? "pages/WindowsPage.qml" : "pages/AppearancePage.qml"
        }
    }
    Component {
        id: welcome
        PxPage {
            heading: I18n.t("Твой angelOS", "Your angelOS")
            subtitle: I18n.t("Настрой оболочку под себя. Основная тема останется доступной, а мастер можно снова открыть в настройках внешнего вида.", "Make the shell your own. The original theme stays available, and you can reopen this wizard in Appearance settings.")
            SettingRow {
                label: "Язык / Language"
                PxCombo {
                    model: [
                        {
                            label: "Русский",
                            value: "ru"
                        },
                        {
                            label: "English",
                            value: "en"
                        }
                    ]
                    currentValue: Config.appearance.language
                    onActivated: v => Config.appearance.language = v
                }
            }
            PxText {
                width: parent.width
                wrapMode: Text.Wrap
                text: I18n.t("Панель и рабочий стол запускаются на всех подключённых экранах. Параметры мониторов и ввода меняются только по твоему действию.", "The bar and desktop run on every connected display. Monitor and input settings change only when you edit them.")
            }
        }
    }
    Component {
        id: shortcuts
        PxPage {
            heading: I18n.t("Основные хоткеи", "Essential shortcuts")
            subtitle: I18n.t("Mod — клавиша Super / Windows. Полный список для текущего конфига: Mod+Shift+Escape.", "Mod is the Super / Windows key. Show your configuration's shortcut list with Mod+Shift+Escape.")
            Repeater {
                model: [["Mod+Space", I18n.t("Запуск приложений", "Launch applications")], ["Mod+S", I18n.t("Настройки", "Settings")], ["Mod+V", I18n.t("История буфера обмена", "Clipboard history")], ["Mod+Alt+L", I18n.t("Блокировка", "Lock screen")], ["Mod+Alt+Y", I18n.t("Показать или скрыть Lyrics", "Toggle lyrics")], ["Mod+Alt+T", I18n.t("Светлая / тёмная тема", "Light / dark theme")], ["Mod+Shift+Q", I18n.t("Меню питания", "Power menu")]]
                SettingRow {
                    required property var modelData
                    label: modelData[0]
                    PxText {
                        text: modelData[1]
                    }
                }
            }
        }
    }
    Component {
        id: finish
        PxPage {
            heading: I18n.t("Всё готово ♡", "You're ready ♡")
            subtitle: I18n.t("Изменения уже сохранены. Настройки всегда доступны из меню angelOS или по Mod+S.", "Your changes are saved. Open Settings from the angelOS menu or press Mod+S at any time.")
            PxText {
                text: I18n.t("Тема: ", "Theme: ") + Theme.flavors[Config.appearance.flavor].name
            }
            PxText {
                text: I18n.t("Экраны: ", "Displays: ") + Shell.screens.map(s => s.name).join(", ")
            }
            PxText {
                width: parent.width
                wrapMode: Text.Wrap
                text: I18n.t("Для геометрии мониторов нажми «Сохранить в конфиг» на шаге «Мониторы», если менял её.", "If you changed monitor geometry, use Save to config on the Monitors step to keep it after login.")
            }
        }
    }
}
