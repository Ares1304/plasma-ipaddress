/**
 * IP Address Display Plasmoid
 * Purpose: Displays local and public IP addresses with country flags in Plasma panel
 * Operation: Fetches and displays IP information with automatic updates
 * Usage: Helps users monitor their network connectivity and location
 * Interactions: Responds to user clicks and system network changes
 */

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.plasma5support 2.0 as P5Support
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.20 as Kirigami
import "../translations/translations.js" as Translations
import "../data/countries.js" as Countries

/**
 * Main Plasmoid Container
 * Purpose: Root container managing the entire widget's state and appearance
 * Operation: Coordinates data fetching, display updates, and user interactions
 * Usage: Provides the foundation for all widget components
 * Interactions: Manages communication between UI and data components
 */
PlasmoidItem {
    id: root

    /**
     * Core Properties
     * Purpose: Define essential state variables for the widget
     * Operation: Maintain current state of IPs, loading states, and display modes
     * Usage: Referenced throughout the widget for state management
     * Interactions: Updated by various functions and user actions
     */
    readonly property string currentLocale: Qt.locale().name.split("_")[0]
    property bool isPublicMode: false
    property bool isLoadingIP: false
    property bool isLoadingCountry: false
    property string localIP: Translations.getTranslation("loading", currentLocale)
    property string publicIP: ""
    property string publicIP_OLD: ""
    property string countryCode: ""
    property bool showingLocalIP: plasmoid.configuration.defaultShowLocalIP
    readonly property bool debugMode: false
    readonly property string flagsPath: "../images/pays/"
    property bool isResuming: false
    property string customPrefix: plasmoid.configuration.customPrefix
    property string selectedInterface: plasmoid.configuration.selectedInterface

    /**
    * Country Names Mapping
    * Purpose: Maps country codes to their full names
    * Operation: Used for tooltip display when hovering over flags
    */

    /**
     * Layout Settings
     * Purpose: Control widget dimensions and layout behavior
     * Operation: Manages widget sizing based on content
     * Usage: Ensures proper display in Plasma panel
     * Interactions: Adapts to panel position and content changes
     */
    Layout.fillWidth: false
    Layout.fillHeight: false
    Layout.preferredWidth: contentLayout.implicitWidth
    Layout.preferredHeight: contentLayout.implicitHeight

    /**
     * Main Layout Structure
     * Purpose: Organizes visual elements of the widget
     * Operation: Arranges IP information and flag in a structured layout
     * Usage: Creates the visual hierarchy of the widget
     * Interactions: Updates based on content and state changes
     */
    ColumnLayout {
        id: contentLayout
        anchors.fill: parent
        spacing: 5

        RowLayout {
            id: contentRow
            Layout.fillWidth: true
            spacing: 5

            // Debug Information Display
            QQC2.Label {
                id: debugLabel
                text: {
                    let debugInfo = [
                        "Country: " + (countryCode || "none"),
                        "Public: " + !showingLocalIP,
                        "LoadingIP: " + isLoadingIP,
                        "LoadingCountry: " + isLoadingCountry,
                        "IP: " + (showingLocalIP ? localIP : publicIP)
                    ].join(" | ")
                    return debugInfo
                }
                visible: debugMode && !showingLocalIP
                color: "#FF0000"
                font.pointSize: 8
                Layout.alignment: Qt.AlignVCenter
            }

            // Container for IP information and flag
            RowLayout {
                id: ipAndFlagRow
                spacing: 5
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true

                // Adjust the layoutDirection based on flagPosition
                // 0: Flag on the right (default), 1: Flag on the left
                layoutDirection: plasmoid.configuration.flagPosition === 1 ? Qt.RightToLeft : Qt.LeftToRight

                // IP Information Display
                ColumnLayout {
                    id: ipInfoColumn
                    spacing: 0
                    Layout.alignment: Qt.AlignHCenter
                    visible: !plasmoid.configuration.showFlagOnly || showingLocalIP

                    QQC2.Label {
                        id: ipTypeLabel
                        text: showingLocalIP ?
                            Translations.getTranslation("localIP", currentLocale) :
                            Translations.getTranslation("publicIP", currentLocale)
                        font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 0.8)
                        Layout.alignment: Qt.AlignHCenter
                        color: plasmoid.configuration.textColor != "" && String(plasmoid.configuration.textColor) !== "#00000000" 
                            ? plasmoid.configuration.textColor 
                            : Kirigami.Theme.textColor
                        visible: plasmoid.configuration.showTypeLabel
                    }


                    QQC2.Label {
                        id: ipAddressLabel
                        text: {
                            let ipText;
                            if (showingLocalIP) {
                                ipText = localIP ? localIP : plasmoid.configuration.noIPMessage;
                            } else {
                                ipText = publicIP ? publicIP : plasmoid.configuration.noIPMessage;
                            }
                            return customPrefix ? (customPrefix + " " + ipText) : ipText;
                        }
                        Layout.alignment: Qt.AlignHCenter
                        color: {
                            if ((!localIP && showingLocalIP) || (!publicIP && !showingLocalIP)) {
                                return plasmoid.configuration.disconnectedTextColor;
                            }
                            return plasmoid.configuration.textColor != "" && String(plasmoid.configuration.textColor) !== "#00000000" 
                                ? plasmoid.configuration.textColor 
                                : Kirigami.Theme.textColor;
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: toggleIPDisplay()
                    }
                }

                // Flag Display Component
                Item {
                    id: flagContainer
                    Layout.preferredWidth: 17
                    Layout.preferredHeight: 17
                    Layout.alignment: Qt.AlignVCenter

                    Image {
                        id: flagImage
                        anchors.fill: parent
                        source: {
                            if (countryCode && !debugMode) {
                                return flagsPath + countryCode.toLowerCase() + ".svg"
                            }
                            return ""
                        }
                        visible: !debugMode && shouldShowFlag()
                        fillMode: Image.PreserveAspectFit
                        smooth: true

                        QQC2.ToolTip {
                            text: Countries.getCountryName(countryCode)
                            visible: flagMouseArea.containsMouse
                            delay: 500
                        }
                    }

                    MouseArea {
                        id: flagMouseArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true  // Enable hover detection
                        onClicked: toggleIPDisplay()
                    }
                }
            }
        }
    }

    /**
     * Command Execution Component
     * Purpose: Handles shell command execution for IP and country data
     * Operation: Executes commands and processes their output
     * Usage: Retrieves network information from system
     * Interactions: Provides data to update widget state
     */
    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        onNewData: {
            var stdout = data["stdout"]
            var stderr = data["stderr"]
            if (debugMode) {
                console.log("📡 Command:", sourceName)
                console.log("📤 Stdout:", stdout)
                console.log("📥 Stderr:", stderr)
            }
            exited(sourceName, stdout, stderr)
            disconnectSource(sourceName)
        }
        
        function exec(cmd) {
            connectSource(cmd)
        }
        
        signal exited(string cmd, string stdout, string stderr)
    }

    P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["powerdevil"]
        
        onSourceAdded: {
            disconnectSource(source);
            connectSource(source);
        }
        
        onDataChanged: {
            if (data["powerdevil"] && data["powerdevil"]["Is Resuming"] === true) {
                if (debugMode) console.log("💻 Wake from sleep detected")
                isResuming = true
                // Force a complete update
                updateData()
            }
        }
    }

    Component.onCompleted: {
        if (debugMode) {
            console.log("🎬 Widget startup")
        }
        updateData()
    }

    /**
     * Data Retrieval Functions
     * Purpose: Fetch IP and location information
     * Operation: Execute system commands to get network data
     * Usage: Called periodically and on user interaction
     * Interactions: Update widget state with retrieved data
     */
    function getLocalIP() {
        if (debugMode) console.log("🏠 Requesting local IP for interface:", selectedInterface)
        if (selectedInterface) {
            executable.exec("ip -4 addr show " + selectedInterface + " scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n1")
        } else {
            executable.exec("ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n1")
        }
    }

    function getPublicIP() {
        if (!isLoadingIP) {
            if (debugMode) console.log("🌐 Requesting public IP")
            isLoadingIP = true
            executable.exec("curl -s --max-time 5 https://api.ipify.org")
        }
    }

    function getCountryCode() {
        if (!isLoadingCountry && publicIP) {
            if (debugMode) console.log("🌍 Requesting country code for IP:", publicIP)
            isLoadingCountry = true
            executable.exec("curl -s --max-time 5 https://ipapi.co/" + publicIP + "/country")
        }
    }

    /**
     * Data Management
     * Purpose: Process command outputs and update widget state
     * Operation: Handles responses from various data sources
     * Usage: Maintains consistency between data and display
     * Interactions: Triggers UI updates based on new data
     */
    Connections {
        target: executable
        function onExited(cmd, stdout, stderr) {
            if (cmd.indexOf("ip -4 addr") !== -1) {
                localIP = stdout.trim()
                if (debugMode) console.log("🏠 Local IP received:", localIP)
            } 
            else if (cmd.indexOf("ipify.org") !== -1) {
                isLoadingIP = false
                if (stdout.trim() !== "") {
                    var newIP = stdout.trim()
                    // Check if IP has changed
                    if (newIP !== publicIP) {
                        if (debugMode) console.log("🔄 IP change detected:", publicIP, "->", newIP)
                        publicIP = newIP
                        countryCode = ""  // Reset country code
                        getCountryCode()  // Request new country code
                    }
                } else {
                    publicIP = ""
                    countryCode = ""
                    if (debugMode) console.log("❌ No public IP received")
                }
            }
            else if (cmd.indexOf("ipapi.co") !== -1) {
                isLoadingCountry = false
                var newCountry = stdout.trim()
                if (newCountry.length === 2) {
                    countryCode = newCountry
                    if (debugMode) console.log("🌍 Country code received:", countryCode)
                } else {
                    countryCode = ""
                    if (debugMode) console.log("❌ Invalid country code received")
                }
            }

            updateDisplay()
        }
    }

    /**
     * Update Timer
     * Purpose: Periodically refresh IP information
     * Operation: Triggers data update every 5 seconds
     * Usage: Keeps displayed information current
     * Interactions: Initiates data retrieval cycle
     */
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: {
            if (showingLocalIP) {
                getLocalIP()
            } else {
                // Check current public IP first
                executable.exec("curl -s --max-time 5 https://api.ipify.org")
            }
        }
    }

    /**
     * Utility Functions
     * Purpose: Provide helper functions for widget operation
     * Operation: Handle various widget states and updates
     * Usage: Called by different widget components
     * Interactions: Coordinate between UI and data components
     */
    function shouldShowFlag() {
        return (plasmoid.configuration.showFlagOnly || plasmoid.configuration.showFlag) 
                && countryCode.length === 2
                && !showingLocalIP
    }

    function updateData() {
        if (showingLocalIP) {
            getLocalIP()
        } else if (!publicIP) {
            getPublicIP()
        }
    }

    function toggleIPDisplay() {
        showingLocalIP = !showingLocalIP
        if (debugMode) {
            console.log("🔄 Mode change:", showingLocalIP ? "Local" : "Public")
        }
        updateData()
    }

    function updateDisplay() {
        if (debugMode) {
            console.log("🔄 Refreshing widget")
            console.log("📊 State:", JSON.stringify({
                showingLocalIP: showingLocalIP,
                localIP: localIP,
                publicIP: publicIP,
                countryCode: countryCode,
                isLoadingIP: isLoadingIP,
                isLoadingCountry: isLoadingCountry
            }, null, 2))
        }

        contentLayout.Layout.preferredWidth = -1
        contentLayout.Layout.preferredHeight = -1
        Qt.callLater(function() {
            contentLayout.Layout.preferredWidth = contentLayout.implicitWidth
            contentLayout.Layout.preferredHeight = contentLayout.implicitHeight
        })
    }

    /**
     * Configuration Handler
     * Purpose: Respond to widget configuration changes
     * Operation: Updates display when settings change
     * Usage: Maintains widget appearance per user preferences
     * Interactions: Triggers display updates on config changes
     */
    Connections {
        target: plasmoid.configuration
        function onShowFlagOnlyChanged() { updateDisplay() }
        function onShowFlagChanged() { updateDisplay() }
        function onShowTypeLabelChanged() { updateDisplay() }
    }
}