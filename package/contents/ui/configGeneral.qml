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
import org.kde.plasma.plasma5support 2.0 as P5Support
import "../translations/translations.js" as Translations

/**
 * Main Configuration Form
 * Purpose: Root container for all configuration options
 * Operation: Organizes settings in a structured layout
 * Usage: Presents configuration options to users
 * Interactions: Manages form layout and user inputs
 */
Kirigami.FormLayout {
    id: page

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
    property alias cfg_showFlagOnly: showFlagOnly.checked
    property alias cfg_flagPosition: flagPosition.currentIndex
    property alias cfg_customPrefix: customPrefixField.text
    property alias cfg_noIPMessage: noIPMessageField.text
    property alias cfg_disconnectedTextColor: disconnectedColorPicker.chosenColor
    property alias cfg_defaultShowLocalIP: defaultShowLocalIP.checked

    /**
     * Network Interface Management
     * Purpose: Handle network interface selection
     * Operation: Lists and manages available network interfaces
     * Usage: Allows interface selection for IP monitoring
     * Interactions: Updates based on system interfaces
     */
    property string selectedInterface: plasmoid.configuration.selectedInterface || ""
    property var networkInterfaces: []

    Component.onCompleted: {
        executable.exec("ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo'")
    }

    Connections {
        target: executable
        function onExited(cmd, stdout) {
            if (cmd.indexOf("ip -o link") !== -1) {
                networkInterfaces = stdout.trim().split("\n")
                    .filter(iface => iface && !iface.startsWith("lo"))
            }
        }
    }

    // Shell command execution component
    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: {
            var stdout = data["stdout"]
            exited(sourceName, stdout)
            disconnectSource(sourceName)
        }

        function exec(cmd) {
            connectSource(cmd)
        }

        signal exited(string cmd, string stdout)
    }

    QQC2.Label {
        id: currentInterfaceLabel
        Kirigami.FormData.label: Translations.getTranslation("currentInterface", currentLocale)
        text: (plasmoid.configuration.selectedInterface || Translations.getTranslation("noInterfaceSelected", currentLocale))
    }

    QQC2.ComboBox {
        id: networkInterfaceComboBox
        Kirigami.FormData.label: Translations.getTranslation("networkInterface", currentLocale)
        model: networkInterfaces
        Layout.fillWidth: true

        // Initialize with saved value
        Component.onCompleted: {
            currentIndex = networkInterfaces.indexOf(selectedInterface)
        }

        // Save only on user action
        onActivated: {
            if (currentIndex >= 0 && currentIndex < model.length) {
                plasmoid.configuration.selectedInterface = model[currentIndex]
            }
        }
    }
    
    // Option to choose the default display (local or public IP)
    QQC2.CheckBox {
        id: defaultShowLocalIP
        Kirigami.FormData.label: Translations.getTranslation("defaultShowLocalIP", currentLocale)
        checked: plasmoid.configuration.defaultShowLocalIP
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
        onCheckedChanged: {
            if (checked) {
                // If checked, force flag display and disable IP type display
                showFlag.checked = true
                showTypeLabel.checked = false
            } else {
                // If unchecked, restore default options
                showFlag.checked = true
                showTypeLabel.checked = true
            }
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