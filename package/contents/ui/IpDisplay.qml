/**
 * IP Address Display Representation
 * Purpose: Renders the address, type label and country flag in every Plasma form factor
 * Operation: Uses the panel's real thickness while keeping a natural size on the desktop
 * Usage: Instantiated as both the compact panel view and the full desktop view
 * Interactions: Left click toggles local/public mode; middle click copies the visible address
 */

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import "../data/countries.js" as Countries
import "../translations/translations.js" as Translations

Item {
    id: display

    // The controller owns network state and actions. Keeping presentation in a
    // separate component lets Plasma create distinct panel and desktop views.
    required property var controller
    property bool compactMode: false

    readonly property bool horizontalPanel: compactMode
        && Plasmoid.formFactor === PlasmaCore.Types.Horizontal
    readonly property bool verticalPanel: compactMode
        && Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool panelMode: horizontalPanel || verticalPanel
    readonly property real contentPadding: compactMode ? Kirigami.Units.smallSpacing : 0

    /*
     * Keep the original two-line hierarchy: the IP type stays above the
     * address. A panel still has one fixed thickness, so scale the complete
     * block only when it physically cannot fit. Using its real implicit height
     * avoids guessed font metrics and preserves the configured font ratio.
     */
    readonly property real panelThickness: horizontalPanel ? height : (verticalPanel ? width : 0)
    readonly property real panelContentScale: {
        if (!panelMode || panelThickness <= 0 || contentRow.implicitHeight <= 0) return 1.0

        var availableThickness = Math.max(1, panelThickness - 2 * contentPadding)
        return Math.min(1.0, availableThickness / contentRow.implicitHeight)
    }
    // A country flag remains a compact status marker in a panel. Letting it
    // grow to 200% would unnecessarily force the adjacent text to shrink.
    readonly property real flagSize: compactMode
        ? Kirigami.Units.iconSizes.small
        : Math.max(8, Kirigami.Units.iconSizes.small * controller.configuredFontScale)

    implicitWidth: (verticalPanel ? contentRow.implicitHeight : contentRow.implicitWidth)
        * panelContentScale + 2 * contentPadding
    implicitHeight: (verticalPanel ? contentRow.implicitWidth : contentRow.implicitHeight)
        * panelContentScale + 2 * contentPadding

    // Plasma panels are fixed on their cross-axis and free on their main axis.
    // These axis-aware constraints mirror Plasma's own compact representations.
    Layout.minimumWidth: horizontalPanel ? implicitWidth : (verticalPanel ? 0 : implicitWidth)
    Layout.minimumHeight: verticalPanel ? implicitHeight : (horizontalPanel ? 0 : implicitHeight)
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.maximumWidth: Infinity
    Layout.maximumHeight: Infinity
    Layout.fillWidth: verticalPanel
    Layout.fillHeight: horizontalPanel
    clip: compactMode

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing
        scale: display.panelContentScale
        // A side panel has a fixed width and free vertical space. Rotate the
        // textual row so the address can use that free axis instead of clipping.
        rotation: display.verticalPanel ? -90 : 0
        transformOrigin: Item.Center

        // This diagnostic label remains disabled in normal builds.
        QQC2.Label {
            text: [
                "Country: " + (controller.countryCode || "none"),
                "Public: " + !controller.showingLocalIP,
                "LoadingIP: " + controller.isLoadingIP,
                "LoadingCountry: " + controller.isLoadingCountry,
                "IP: " + (controller.showingLocalIP ? controller.localIP : controller.publicIP)
            ].join(" | ")
            visible: controller.debugMode && !controller.showingLocalIP
            color: "#FF0000"
            font.pixelSize: 8
            Layout.alignment: Qt.AlignVCenter
        }

        RowLayout {
            id: ipAndFlagRow
            spacing: Kirigami.Units.smallSpacing
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

            // Index 0 places the flag on the right; index 1 places it on the left.
            layoutDirection: Plasmoid.configuration.flagPosition === 1
                ? Qt.RightToLeft
                : Qt.LeftToRight

            Item {
                id: ipInfoContainer
                implicitWidth: ipInfoColumn.implicitWidth
                implicitHeight: ipInfoColumn.implicitHeight
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                visible: !Plasmoid.configuration.showFlagOnly || controller.showingLocalIP

                ColumnLayout {
                    id: ipInfoColumn
                    anchors.fill: parent
                    spacing: 0

                    QQC2.Label {
                        id: ipTypeLabel
                        text: controller.showingLocalIP
                            ? Translations.getTranslation("localIP", controller.currentLocale)
                            : Translations.getTranslation("publicIP", controller.currentLocale)
                        font.pixelSize: Math.max(
                            1,
                            Kirigami.Theme.defaultFont.pixelSize * 0.8 * controller.configuredFontScale
                        )
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        color: controller.configuredTextColor()
                        visible: Plasmoid.configuration.showTypeLabel
                    }

                    QQC2.Label {
                        text: controller.displayedText()
                        font.pixelSize: Math.max(
                            1,
                            Kirigami.Theme.defaultFont.pixelSize * controller.configuredFontScale
                        )
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        color: controller.displayedTextColor()
                    }
                }

                // The pointer target wraps the layout instead of participating
                // in it, avoiding undefined anchors on a layout-managed child.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.MiddleButton) {
                            controller.copyDisplayedIP()
                        } else {
                            controller.toggleIPDisplay()
                        }
                    }
                }
            }

            Image {
                id: flagImage
                Layout.preferredWidth: visible ? display.flagSize : 0
                Layout.preferredHeight: visible ? display.flagSize : 0
                // As a sibling of the complete two-line text block, the flag
                // is centered against both lines rather than either label.
                Layout.alignment: Qt.AlignVCenter
                visible: controller.shouldShowFlag()
                // Keep the flag upright when the text row is rotated in a side panel.
                rotation: display.verticalPanel ? 90 : 0
                source: visible && !controller.debugMode
                    ? controller.flagsPath + controller.countryCode.toLowerCase() + ".svg"
                    : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: false

                QQC2.ToolTip {
                    text: Countries.getCountryName(controller.countryCode)
                    visible: flagMouseArea.containsMouse
                    delay: 500
                }

                MouseArea {
                    id: flagMouseArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.MiddleButton) {
                            controller.copyDisplayedIP()
                        } else {
                            controller.toggleIPDisplay()
                        }
                    }
                }
            }
        }
    }

    QQC2.ToolTip {
        text: controller.copyFeedbackText
        visible: controller.copyFeedbackVisible
    }
}
