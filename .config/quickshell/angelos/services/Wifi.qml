pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.config

// Wi-Fi and wired state through NetworkManager (Quickshell.Networking).
// Scanning runs only while something asks for it (the settings page).
Singleton {
    id: root

    readonly property bool available: Networking.backend === NetworkBackendType.NetworkManager
    readonly property var devices: Networking.devices ? Networking.devices.values : []
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) || null
    readonly property var wiredDevice: devices.find(d => d.type === DeviceType.Wired && d.hasLink) || devices.find(d => d.type === DeviceType.Wired) || null
    readonly property bool hasWifi: !!wifiDevice
    readonly property bool enabled: Networking.wifiEnabled
    readonly property bool hardwareEnabled: Networking.wifiHardwareEnabled
    readonly property var networks: {
        if (!wifiDevice || !wifiDevice.networks)
            return [];
        const list = wifiDevice.networks.values.filter(n => n.name !== "");
        // connected first, then known, then by signal
        return list.sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength));
    }
    readonly property var connected: networks.find(n => n.connected) || null
    readonly property real strength: connected ? connected.signalStrength : 0
    readonly property bool online: Networking.connectivity === NetworkConnectivity.Full
    readonly property string connectivityText: ({
            [NetworkConnectivity.Full]: I18n.t("интернет есть", "online"),
            [NetworkConnectivity.Limited]: I18n.t("ограничено", "limited"),
            [NetworkConnectivity.Portal]: I18n.t("нужен вход (captive portal)", "sign-in needed (captive portal)"),
            [NetworkConnectivity.None]: I18n.t("нет интернета", "offline")
        })[Networking.connectivity] || I18n.t("неизвестно", "unknown")

    // how many pages/panels want fresh scan results
    property int scanners: 0
    Binding {
        when: !!root.wifiDevice
        target: root.wifiDevice
        property: "scannerEnabled"
        value: root.scanners > 0 && root.enabled
    }

    property bool serviceInstalled: false
    property bool serviceActive: false
    property string lastError: ""
    property string pending: ""          // name of the network being connected

    function startService() {
        Quickshell.execDetached(["pkexec", "systemctl", "enable", "--now", "NetworkManager.service"]);
        serviceCheck.running = true;
        recheck.restart();
    }

    function setEnabled(on) {
        Networking.wifiEnabled = on;
    }
    function secured(n) {
        return !!n && n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe;
    }
    function needsPassword(n) {
        return secured(n) && !n.known;
    }
    function connect(n, psk) {
        if (!n)
            return;
        lastError = "";
        pending = n.name;
        if (psk !== undefined && psk !== "")
            n.connectWithPsk(psk);
        else
            n.connect();
    }
    function disconnect(n) {
        if (n)
            n.disconnect();
    }
    function forget(n) {
        if (n)
            n.forget();
    }
    function bars(s) {
        return s > 0.75 ? 4 : s > 0.5 ? 3 : s > 0.25 ? 2 : s > 0.05 ? 1 : 0;
    }
    function securityName(n) {
        return n ? WifiSecurityType.toString(n.security) : "";
    }

    Instantiator {
        model: root.networks
        delegate: Connections {
            required property var modelData
            target: modelData
            function onConnectionFailed(reason) {
                root.pending = "";
                root.lastError = modelData.name + ": " + ({
                        [ConnectionFailReason.NoSecrets]: I18n.t("неверный пароль", "wrong password"),
                        [ConnectionFailReason.WifiAuthTimeout]: I18n.t("точка не ответила вовремя", "the access point timed out"),
                        [ConnectionFailReason.WifiNetworkLost]: I18n.t("сеть пропала", "network lost"),
                        [ConnectionFailReason.WifiClientFailed]: I18n.t("не удалось подключиться", "connection failed"),
                        [ConnectionFailReason.WifiClientDisconnected]: I18n.t("отключено", "disconnected")
                    }[reason] || I18n.t("ошибка подключения", "connection error"));
            }
            function onConnectedChanged() {
                if (modelData.connected && root.pending === modelData.name)
                    root.pending = "";
            }
        }
    }

    Process {
        id: serviceCheck
        command: ["sh", "-c", "[ -e /usr/lib/systemd/system/NetworkManager.service ] || [ -e /lib/systemd/system/NetworkManager.service ] && echo installed; systemctl is-active --quiet NetworkManager.service && echo active; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.serviceInstalled = text.includes("installed");
                root.serviceActive = text.includes("active");
            }
        }
    }
    Timer {
        id: recheck
        interval: 3000
        onTriggered: serviceCheck.running = true
    }
    Component.onCompleted: serviceCheck.running = true
}
