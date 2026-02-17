import QtQuick
import QtQuick.Controls
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_selectedCity: selectedCityField.text
    property alias cfg_refreshIntervalMinutes: intervalSpin.value

    implicitWidth: 420

    Column {
        spacing: 12
        width: parent.width

        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "City format: Name|Latitude|Longitude (example: Berlin|52.52|13.4050)."
        }

        TextField {
            id: selectedCityField
            width: parent.width
            placeholderText: "London|51.5072|-0.1276"
        }

        Row {
            spacing: 8

            Label {
                text: "Refresh interval (minutes)"
                verticalAlignment: Text.AlignVCenter
            }

            SpinBox {
                id: intervalSpin
                from: 5
                to: 120
                value: 15
            }
        }
    }
}
