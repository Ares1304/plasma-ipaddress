/**
 * IP Address Display Plasmoid
 * Purpose: Displays local and public IP addresses with country flags in Plasma panel
 * Operation: Fetches and displays IP information with automatic updates
 * Usage: Helps users monitor their network connectivity and location
 * Interactions: Responds to user clicks and system network changes
 */

import QtQuick 2.15
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.plasma5support 2.0 as P5Support
import org.kde.kirigami 2.20 as Kirigami
import org.kde.kquickcontrolsaddons 2.0 as KQuickControlsAddons
import "../translations/translations.js" as Translations

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
    property bool isLoadingIP: false
    property bool isLoadingCountry: false
    property bool isLoadingLocalIP: false
    property bool isProbingRoute: false
    property bool resumeSignalActive: false
    property string localIP: Translations.getTranslation("loading", currentLocale)
    property string publicIP: ""
    property string countryCode: ""
    property bool showingLocalIP: plasmoid.configuration.defaultShowLocalIP
    readonly property bool debugMode: false
    readonly property string flagsPath: "../images/pays/"
    property string customPrefix: plasmoid.configuration.customPrefix
    property string selectedInterface: plasmoid.configuration.selectedInterface || ""
    readonly property real configuredFontScale: Math.max(
        0.6,
        Math.min(2.0, Number(plasmoid.configuration.fontScale || 100) / 100)
    )

    // Network requests are versioned so a reply from an old mode or route is
    // never allowed to overwrite the currently displayed information.
    property int modeEpoch: 0
    property int networkEpoch: 0
    property int publicRequestModeEpoch: -1
    property int publicRequestNetworkEpoch: -1
    property int publicFailureCount: 0
    property string routeFingerprint: ""
    property string routedLocalIP: ""
    property string copyFeedbackText: ""
    property bool copyFeedbackVisible: false

    readonly property int publicRefreshInterval: 5 * 60 * 1000
    readonly property string localAddressesCommand: "ip -4 -o addr show scope global"
    // `ip route get` only inspects the local routing table; it sends no packet.
    readonly property string routeProbeCommand: "ip -4 route get 1.1.1.1 2>/dev/null"
    // One public request returns both values, avoiding the old second provider
    // and its rate limit. This command is only started while public mode is shown.
    readonly property string publicLookupCommand: "curl -fsS --connect-timeout 3 --max-time 8 https://api.country.is/"

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
    // Plasma uses a compact representation inside panels and a full one on the
    // desktop. Keeping them explicit prevents panel geometry from being treated
    // like a freely resizable desktop widget.
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar
        ? fullRepresentation
        : compactRepresentation

    /**
     * Main Layout Structure
     * Purpose: Organizes visual elements of the widget
     * Operation: Arranges IP information and flag in a structured layout
     * Usage: Creates the visual hierarchy of the widget
     * Interactions: Updates based on content and state changes
     */
    compactRepresentation: IpDisplay {
        controller: root
        compactMode: true
    }

    fullRepresentation: IpDisplay {
        controller: root
        compactMode: false
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

        onNewData: function(sourceName, data) {
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

    KQuickControlsAddons.Clipboard {
        id: clipboard
    }

    P5Support.DataSource {
        id: pmSource
        engine: "powermanagement"
        connectedSources: ["powerdevil"]
        
        onSourceAdded: function(source) {
            disconnectSource(source)
            connectSource(source)
        }
        
        onDataChanged: {
            // Missing power-management data is a normal startup state. Always
            // coerce it to false before assigning the strongly typed property.
            var resuming = Boolean(
                data["powerdevil"] && data["powerdevil"]["Is Resuming"] === true
            )
            if (resuming && !resumeSignalActive) {
                if (debugMode) console.log("💻 Wake from sleep detected")
                refreshAfterNetworkEvent("resume")
            }
            resumeSignalActive = resuming
        }
    }

    Component.onCompleted: {
        if (debugMode) {
            console.log("🎬 Widget startup")
        }
        probeRoute()
        refreshCurrentMode(true)
    }

    /**
     * Data Retrieval Functions
     * Purpose: Fetch IP and location information
     * Operation: Execute system commands to get network data
     * Usage: Called periodically and on user interaction
     * Interactions: Update widget state with retrieved data
     */
    function getLocalIP() {
        if (isLoadingLocalIP) return

        if (debugMode) console.log("🏠 Requesting local addresses")
        isLoadingLocalIP = true
        executable.exec(localAddressesCommand)
    }

    function getPublicIP() {
        if (showingLocalIP || isLoadingIP) return

        if (debugMode) console.log("🌐 Requesting public IP and country")
        isLoadingIP = true
        isLoadingCountry = true
        publicRequestModeEpoch = modeEpoch
        publicRequestNetworkEpoch = networkEpoch
        executable.exec(publicLookupCommand)
    }

    function probeRoute() {
        if (isProbingRoute) return

        isProbingRoute = true
        executable.exec(routeProbeCommand)
    }

    function isValidIPv4(address) {
        var parts = String(address).split(".")
        if (parts.length !== 4) return false

        for (var i = 0; i < parts.length; ++i) {
            if (!/^\d{1,3}$/.test(parts[i])) return false
            var octet = Number(parts[i])
            if (octet < 0 || octet > 255) return false
        }
        return true
    }

    function isValidIPv6(address) {
        var value = String(address).trim()
        if (!value || value.indexOf(":") === -1 || !/^[0-9A-Fa-f:]+$/.test(value)) return false
        if (value.indexOf("::") !== value.lastIndexOf("::")) return false

        var halves = value.split("::")
        var leftGroups = halves[0] ? halves[0].split(":") : []
        var rightGroups = halves.length === 2 && halves[1] ? halves[1].split(":") : []
        var groupCount = leftGroups.length + rightGroups.length

        for (var i = 0; i < leftGroups.length; ++i) {
            if (!/^[0-9A-Fa-f]{1,4}$/.test(leftGroups[i])) return false
        }
        for (var j = 0; j < rightGroups.length; ++j) {
            if (!/^[0-9A-Fa-f]{1,4}$/.test(rightGroups[j])) return false
        }

        // A compressed address must omit at least one of the eight groups.
        return halves.length === 2 ? groupCount < 8 : groupCount === 8
    }

    function isValidIPAddress(address) {
        return isValidIPv4(address) || isValidIPv6(address)
    }

    function localAddressFromOutput(output) {
        var lines = String(output).trim().split("\n")
        var wantedInterface = String(selectedInterface || "").split("@")[0]
        var firstAddress = ""
        var routedAddress = ""

        // Parse the constant command output in QML. The configured interface is
        // data, never shell input, so a hand-edited setting cannot inject code.
        for (var i = 0; i < lines.length; ++i) {
            var match = /^\d+:\s+(\S+)\s+inet\s+([0-9.]+)\//.exec(lines[i])
            if (!match || !isValidIPv4(match[2])) continue

            var interfaceName = match[1].split("@")[0]
            var address = match[2]
            if (!firstAddress) firstAddress = address
            if (address === routedLocalIP) routedAddress = address
            if (wantedInterface && interfaceName === wantedInterface) return address
        }

        return wantedInterface ? "" : (routedAddress || firstAddress)
    }

    function publicDataFromOutput(output) {
        try {
            var response = JSON.parse(String(output).trim())
            var address = response && typeof response.ip === "string" ? response.ip.trim() : ""
            var country = response && typeof response.country === "string" ? response.country.trim().toUpperCase() : ""
            return {
                address: address,
                country: country,
                isAddressValid: isValidIPAddress(address),
                isCountryValid: /^[A-Z]{2}$/.test(country)
            }
        } catch (error) {
            if (debugMode) console.log("❌ Invalid public lookup response:", error)
            return {
                address: "",
                country: "",
                isAddressValid: false,
                isCountryValid: false
            }
        }
    }

    function publicRetryDelay() {
        var delays = [30000, 60000, 120000, 300000, 600000, 1800000]
        return delays[Math.min(Math.max(publicFailureCount - 1, 0), delays.length - 1)]
    }

    function schedulePublicRefresh(delay) {
        if (showingLocalIP) {
            publicRefreshTimer.stop()
            return
        }

        publicRefreshTimer.interval = Math.max(1000, delay)
        publicRefreshTimer.restart()
    }

    function refreshCurrentMode(forcePublicRefresh) {
        if (showingLocalIP) {
            publicRefreshTimer.stop()
            getLocalIP()
        } else if (forcePublicRefresh || !publicIP || !countryCode) {
            publicRefreshTimer.stop()
            getPublicIP()
        } else if (!publicRefreshTimer.running) {
            schedulePublicRefresh(publicRefreshInterval)
        }
    }

    function refreshAfterNetworkEvent(reason) {
        networkEpoch += 1
        if (debugMode) console.log("🔄 Network context changed:", reason)
        refreshCurrentMode(true)
    }

    function handleRouteProbe(output) {
        var normalizedRoute = String(output).trim()
        var sourceMatch = /\bsrc\s+([0-9.]+)/.exec(normalizedRoute)
        routedLocalIP = sourceMatch && isValidIPv4(sourceMatch[1]) ? sourceMatch[1] : ""

        if (!routeFingerprint) {
            routeFingerprint = normalizedRoute || "unavailable"
            if (showingLocalIP && !selectedInterface && routedLocalIP) {
                localIP = routedLocalIP
            }
            return
        }

        var newFingerprint = normalizedRoute || "unavailable"
        if (newFingerprint !== routeFingerprint) {
            routeFingerprint = newFingerprint
            refreshAfterNetworkEvent("route")
        }
    }

    function handlePublicLookup(output) {
        isLoadingIP = false
        isLoadingCountry = false

        // A curl already running cannot be reliably cancelled by DataSource.
        // Ignore its result if the user changed mode or the route changed.
        var staleReply = showingLocalIP
            || publicRequestModeEpoch !== modeEpoch
            || publicRequestNetworkEpoch !== networkEpoch
        if (staleReply) {
            if (!showingLocalIP) getPublicIP()
            return
        }

        var publicData = publicDataFromOutput(output)
        if (publicData.isAddressValid) {
            publicIP = publicData.address
            if (publicData.isCountryValid) {
                countryCode = publicData.country
                publicFailureCount = 0
                schedulePublicRefresh(publicRefreshInterval)
                if (debugMode) console.log("🌍 Public data received for country:", countryCode)
            } else {
                // The address remains useful on its own. Hide a stale flag and
                // retry only the combined lookup with bounded backoff.
                countryCode = ""
                publicFailureCount += 1
                schedulePublicRefresh(publicRetryDelay())
                if (debugMode) console.log("❌ Country code missing; retry scheduled")
            }
            return
        }

        // Keep the last valid values during a temporary outage instead of
        // making a known IP and flag disappear after one failed request.
        publicFailureCount += 1
        schedulePublicRefresh(publicRetryDelay())
        if (debugMode) console.log("❌ Public lookup failed; retry scheduled")
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
            if (cmd === localAddressesCommand) {
                isLoadingLocalIP = false
                localIP = localAddressFromOutput(stdout)
                if (debugMode) console.log("🏠 Local IP received:", localIP)
            } else if (cmd === routeProbeCommand) {
                isProbingRoute = false
                handleRouteProbe(stdout)
            } else if (cmd === publicLookupCommand) {
                handlePublicLookup(stdout)
            }
        }
    }

    /**
     * Update Timer
     * Purpose: Periodically refresh IP information
     * Operation: Uses local route probes plus mode-specific refresh intervals
     * Usage: Keeps displayed information current
     * Interactions: Initiates data retrieval cycle
     */
    Timer {
        id: routeProbeTimer
        interval: 15000
        running: true
        repeat: true
        onTriggered: probeRoute()
    }

    Timer {
        id: localRefreshTimer
        interval: 60000
        running: showingLocalIP
        repeat: true
        onTriggered: getLocalIP()
    }

    Timer {
        id: publicRefreshTimer
        interval: publicRefreshInterval
        repeat: false
        onTriggered: getPublicIP()
    }

    Timer {
        id: copyFeedbackTimer
        interval: 2000
        repeat: false
        onTriggered: copyFeedbackVisible = false
    }

    /**
     * Utility Functions
     * Purpose: Provide helper functions for widget operation
     * Operation: Handle various widget states and updates
     * Usage: Called by different widget components
     * Interactions: Coordinate between UI and data components
     */
    function shouldShowFlag() {
        return !showingLocalIP
            && (plasmoid.configuration.showFlagOnly || plasmoid.configuration.showFlag)
            && /^[A-Z]{2}$/.test(countryCode)
    }

    function displayedText() {
        var address = showingLocalIP ? localIP : publicIP
        var ipText = address || plasmoid.configuration.noIPMessage
        return customPrefix ? customPrefix + " " + ipText : ipText
    }

    function configuredTextColor() {
        var configuredColor = plasmoid.configuration.textColor
        return configuredColor !== "" && String(configuredColor) !== "#00000000"
            ? configuredColor
            : Kirigami.Theme.textColor
    }

    function displayedTextColor() {
        var address = showingLocalIP ? localIP : publicIP
        return address ? configuredTextColor() : plasmoid.configuration.disconnectedTextColor
    }

    function copyDisplayedIP() {
        var address = showingLocalIP ? localIP : publicIP
        if (!isValidIPAddress(address)) {
            copyFeedbackText = Translations.getTranslation("noIPToCopy", currentLocale)
        } else {
            try {
                clipboard.content = address
                copyFeedbackText = Translations.getTranslation("ipCopied", currentLocale)
            } catch (error) {
                copyFeedbackText = Translations.getTranslation("copyError", currentLocale)
                if (debugMode) console.log("❌ Clipboard error:", error)
            }
        }

        copyFeedbackVisible = true
        copyFeedbackTimer.restart()
    }

    function updateData() {
        refreshCurrentMode(true)
    }

    function toggleIPDisplay() {
        showingLocalIP = !showingLocalIP
        modeEpoch += 1
        if (debugMode) {
            console.log("🔄 Mode change:", showingLocalIP ? "Local" : "Public")
        }
        refreshCurrentMode(true)
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
        function onSelectedInterfaceChanged() {
            if (showingLocalIP) Qt.callLater(getLocalIP)
        }
    }
}
