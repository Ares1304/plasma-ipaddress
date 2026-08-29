/**
 * Configuration Panel for IP Address Display Plasmoid
 * Purpose: Provides user interface for widget settings
 * Operation: Manages user preferences and interface selection
 * Usage: Allows users to customize widget appearance and behavior
 * Interactions: Handles user input and saves configuration
 */

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support 2.0 as P5Support
import "../translations/translations.js" as Translations

/**
 * Main Configuration Page
 * Purpose: Root page for all configuration options
 * Operation: Scrolls automatically when translated content does not fit
 * Usage: Presents configuration options to users
 * Interactions: Manages form layout and user inputs
 */
KCM.SimpleKCM {
    id: page

    // Keep a visible affordance whenever the dialog is too short. This avoids
    // relying on wheel discovery or on an overlay scrollbar that stays hidden.
    verticalScrollBarPolicy: QQC2.ScrollBar.AlwaysOn

    /**
     * Core Properties
     * Purpose: Define essential configuration variables
     * Operation: Maintain settings and UI state
     * Usage: Referenced throughout the configuration panel
     * Interactions: Updated based on user actions
     */
    property string currentLocale: {
        var locale = Qt.locale().name.split("_")[0];
        return Translations.translations.hasOwnProperty(locale) ? locale : "en";
    }

    // Configuration bindings
    property alias cfg_showFlag: showFlag.checked
    property alias cfg_textColor: colorPicker.chosenColor
    property alias cfg_showTypeLabel: showTypeLabel.checked
    property alias cfg_fontScale: fontScaleSpinBox.value
    property alias cfg_showFlagOnly: showFlagOnly.checked
    property alias cfg_flagPosition: flagPosition.currentIndex
    property alias cfg_customPrefix: customPrefixField.text
    property alias cfg_noIPMessage: noIPMessageField.text
    property alias cfg_disconnectedTextColor: disconnectedColorPicker.chosenColor
    property alias cfg_defaultShowLocalIP: defaultShowLocalIP.checked
    // Plasma reads and writes cfg_* properties when Apply/Cancel is used.
    // Keep interface selection in that transaction instead of saving eagerly.
    property string cfg_selectedInterface: ""
    property string cfg_lastSelectedInterface: ""

    // Plasma 6 provides both the saved cfg_* values and their cfg_*Default
    // counterparts when it creates this page. Declaring the default properties
    // keeps the configuration loader quiet and preserves reliable Reset/Cancel
    // behavior without writing anything before the user presses Apply or OK.
    property color cfg_textColorDefault: "transparent"
    property bool cfg_showFlagDefault: true
    property bool cfg_showTypeLabelDefault: true
    property int cfg_fontScaleDefault: 100
    property bool cfg_showFlagOnlyDefault: false
    property int cfg_flagPositionDefault: 0
    property string cfg_selectedInterfaceDefault: ""
    property string cfg_customPrefixDefault: ""
    property bool cfg_defaultShowLocalIPDefault: true
    property string cfg_lastSelectedInterfaceDefault: ""
    property string cfg_noIPMessageDefault: "Disconnected"
    property color cfg_disconnectedTextColorDefault: "#ff0000"

    /**
     * Network Interface Management
     * Purpose: Handle network interface selection
     * Operation: Lists and manages available network interfaces
     * Usage: Allows interface selection for IP monitoring
     * Interactions: Updates based on system interfaces
     */
    property var networkInterfaces: []
    property string detectedInterface: ""
    readonly property var interfaceChoices: [
        Translations.getTranslation("automaticInterfaceSelection", currentLocale)
    ].concat(networkInterfaces)

    Component.onCompleted: {
        executable.exec("ip -o link show")
        // Route inspection is local and identifies the interface used by the
        // automatic setting without opening any network connection.
        executable.exec("ip -4 route get 1.1.1.1 2>/dev/null")
        syncInterfaceSelection()
    }

    onCfg_selectedInterfaceChanged: syncInterfaceSelection()

    function syncInterfaceSelection() {
        if (!networkInterfaceComboBox) return

        if (!cfg_selectedInterface) {
            networkInterfaceComboBox.currentIndex = 0
            return
        }

        var savedIndex = networkInterfaces.indexOf(cfg_selectedInterface)
        // Keep an unavailable saved interface visible in the label instead of
        // silently overwriting it when the configuration page opens.
        networkInterfaceComboBox.currentIndex = savedIndex >= 0 ? savedIndex + 1 : -1
    }

    function interfacesFromOutput(output) {
        var interfaces = []
        var lines = String(output).trim().split("\n")
        for (var i = 0; i < lines.length; ++i) {
            var match = /^\d+:\s+([^:]+):/.exec(lines[i])
            if (!match) continue

            var interfaceName = match[1].split("@")[0]
            if (isUserFacingInterface(interfaceName)
                    && interfaces.indexOf(interfaceName) === -1) {
                interfaces.push(interfaceName)
            }
        }
        return interfaces
    }

    function isUserFacingInterface(interfaceName) {
        var name = String(interfaceName || "").toLowerCase()
        if (!name || name === "lo") return false

        // Container engines can create dozens of bridges and veth peers. They
        // are implementation details rather than connections a user normally
        // wants to monitor. Keep VPN devices such as tailscale, tun and wg in
        // the list because those are meaningful selectable interfaces.
        var containerInterface = /^(docker.*|veth.*|br-[0-9a-f]{6,}|virbr\d*(?:-nic)?|lxcbr\d*|podman.*|cni[0-9-].*|flannel\..*|cali.*|kube-ipvs\d*)$/
        return !containerInterface.test(name)
    }

    function interfaceFromRoute(output) {
        var match = /\bdev\s+(\S+)/.exec(String(output))
        return match ? match[1].split("@")[0] : ""
    }

    Connections {
        target: executable
        function onExited(cmd, stdout) {
            if (cmd === "ip -o link show") {
                networkInterfaces = interfacesFromOutput(stdout)
                syncInterfaceSelection()
            } else if (cmd === "ip -4 route get 1.1.1.1 2>/dev/null") {
                detectedInterface = interfaceFromRoute(stdout)
            }
        }
    }

    // Shell command execution component
    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: function(sourceName, data) {
            var stdout = data["stdout"]
            exited(sourceName, stdout)
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }

        signal exited(string cmd, string stdout)
    }

    // SimpleKCM supplies the adaptive viewport; the explicitly visible scroll
    // bar above makes additional settings discoverable in short dialogs.
    Kirigami.FormLayout {
        id: settingsForm
        Layout.fillWidth: true

        QQC2.Label {
            id: currentInterfaceLabel
            Kirigami.FormData.label: Translations.getTranslation("currentInterface", currentLocale)
            text: cfg_selectedInterface
                || detectedInterface
                || Translations.getTranslation("noInterfaceSelected", currentLocale)
        }

        QQC2.ComboBox {
            id: networkInterfaceComboBox
            Kirigami.FormData.label: Translations.getTranslation("networkInterface", currentLocale)
            model: interfaceChoices
            Layout.fillWidth: true

            // Index zero is the explicit automatic-selection option.
            onActivated: function(index) {
                cfg_selectedInterface = index > 0 ? networkInterfaces[index - 1] : ""
                if (cfg_selectedInterface) cfg_lastSelectedInterface = cfg_selectedInterface
            }
        }

        // Option to choose the default display (local or public IP)
        QQC2.CheckBox {
            id: defaultShowLocalIP
            Kirigami.FormData.label: Translations.getTranslation("defaultShowLocalIP", currentLocale)
        }

        QQC2.TextField {
            id: customPrefixField
            Kirigami.FormData.label: Translations.getTranslation("customPrefix", currentLocale)
            placeholderText: Translations.getTranslation("customPrefixPlaceholder", currentLocale)
            Layout.fillWidth: true
        }

        QQC2.TextField {
            id: noIPMessageField
            Kirigami.FormData.label: Translations.getTranslation("noIPMessage", currentLocale)
            placeholderText: Translations.getTranslation("noIPMessagePlaceholder", currentLocale)
            Layout.fillWidth: true
        }

        QQC2.ComboBox {
            id: flagPosition
            Kirigami.FormData.label: Translations.getTranslation("flagPosition", currentLocale)
            model: [
                Translations.getTranslation("flagRight", currentLocale),
                Translations.getTranslation("flagLeft", currentLocale)
            ]
            enabled: showFlag.checked || showFlagOnly.checked
        }

        // Checkbox for displaying country flag
        QQC2.CheckBox {
            id: showFlag
            Kirigami.FormData.label: Translations.getTranslation("showCountryFlag", currentLocale)
            text: ""
            enabled: !showFlagOnly.checked  // Disabled if "Show only flag" is checked
        }

        // Checkbox for displaying IP type (local/public)
        QQC2.CheckBox {
            id: showTypeLabel
            Kirigami.FormData.label: Translations.getTranslation("showIPType", currentLocale)
            text: ""
            enabled: !showFlagOnly.checked  // Disabled if "Show only flag" is checked
        }

        // Checkbox for displaying only the flag
        QQC2.CheckBox {
            id: showFlagOnly
            Kirigami.FormData.label: Translations.getTranslation("showFlagOnly", currentLocale)
            text: ""
            // `toggled` only reacts to the user. `checkedChanged` also fires while
            // Plasma restores settings and used to overwrite saved preferences.
            onToggled: {
                if (checked) {
                    showFlag.checked = true
                    showTypeLabel.checked = false
                }
            }
        }

        QQC2.SpinBox {
            id: fontScaleSpinBox
            Kirigami.FormData.label: Translations.getTranslation("fontSize", currentLocale)
            from: 60
            to: 200
            stepSize: 5
            editable: true

            textFromValue: function(value, locale) {
                return value + " %"
            }

            valueFromText: function(text, locale) {
                var parsedValue = parseInt(text, 10)
                return isNaN(parsedValue) ? fontScaleSpinBox.value : parsedValue
            }
        }

        // Text color pickers
        RowLayout {
            Kirigami.FormData.label: Translations.getTranslation("textColor", currentLocale)

            ColorPicker {
                id: colorPicker
            }
        }

        RowLayout {
            Kirigami.FormData.label: Translations.getTranslation("disconnectedTextColor", currentLocale)
            ColorPicker {
                id: disconnectedColorPicker
            }
        }
    }
}
