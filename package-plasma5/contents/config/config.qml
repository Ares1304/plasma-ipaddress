// Import necessary QtQuick and KDE Plasma configuration modules
import QtQuick 2.0
import org.kde.plasma.configuration 2.0

// Define the configuration model for the widget
ConfigModel {
    // Add a configuration category for general settings
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "configGeneral.qml"
    }
}