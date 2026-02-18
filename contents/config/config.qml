import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: qsTr("General")
        icon: "settings-configure"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: qsTr("Location")
        icon: "mark-location"
        source: "configLocation.qml"
    }
    ConfigCategory {
        name: qsTr("Units")
        icon: "preferences-desktop-locale"
        source: "configUnits.qml"
    }
    ConfigCategory {
        name: qsTr("Appearance")
        icon: "preferences-desktop-theme"
        source: "configAppearance.qml"
    }
    ConfigCategory {
        name: qsTr("Scrollbox")
        icon: "view-list-text"
        source: "configScrollbox.qml"
    }
}
