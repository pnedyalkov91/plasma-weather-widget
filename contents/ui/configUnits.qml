import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property string cfg_temperatureUnit: "C"
    property string cfg_pressureUnit: "hPa"
    property string cfg_windSpeedUnit: "kmh"
    property string cfg_precipitationUnit: "mm"
    property string cfg_altitudeUnit: "m"
    property string cfg_apparentTemperatureMode: "apparent"

    function setCombo(combo, value) {
        for (var i = 0; i < combo.model.length; ++i) {
            if (combo.model[i].value === value) {
                combo.currentIndex = i;
                return;
            }
        }
    }

    Component.onCompleted: {
        setCombo(temperatureCombo, cfg_temperatureUnit);
        setCombo(pressureCombo, cfg_pressureUnit);
        setCombo(windCombo, cfg_windSpeedUnit);
        setCombo(precipCombo, cfg_precipitationUnit);
        setCombo(altitudeCombo, cfg_altitudeUnit);
        setCombo(apparentCombo, cfg_apparentTemperatureMode);
    }

    GridLayout {
        anchors.fill: parent
        columns: 2
        rowSpacing: 8
        columnSpacing: 12

        Label { text: "Temperature:" }
        ComboBox {
            id: temperatureCombo
            model: [
                { text: "Celsius (°C)", value: "C" },
                { text: "Fahrenheit (°F)", value: "F" }
            ]
            textRole: "text"
            onActivated: root.cfg_temperatureUnit = model[currentIndex].value
        }

        Label { text: "Barometric pressure:" }
        ComboBox {
            id: pressureCombo
            model: [
                { text: "hPa", value: "hPa" },
                { text: "mmHg", value: "mmHg" },
                { text: "inHg", value: "inHg" }
            ]
            textRole: "text"
            onActivated: root.cfg_pressureUnit = model[currentIndex].value
        }

        Label { text: "Wind speed:" }
        ComboBox {
            id: windCombo
            model: [
                { text: "Kilometers per hour (km/h)", value: "kmh" },
                { text: "Miles per hour (mph)", value: "mph" },
                { text: "Meters per second (m/s)", value: "ms" },
                { text: "Knots (kn)", value: "kn" }
            ]
            textRole: "text"
            onActivated: root.cfg_windSpeedUnit = model[currentIndex].value
        }

        Label { text: "Precipitations:" }
        ComboBox {
            id: precipCombo
            model: [
                { text: "Millimeters (mm)", value: "mm" },
                { text: "Inches (in)", value: "in" }
            ]
            textRole: "text"
            onActivated: root.cfg_precipitationUnit = model[currentIndex].value
        }

        Label { text: "Altitude:" }
        ComboBox {
            id: altitudeCombo
            model: [
                { text: "Meters (m)", value: "m" },
                { text: "Feet (ft)", value: "ft" }
            ]
            textRole: "text"
            onActivated: root.cfg_altitudeUnit = model[currentIndex].value
        }

        Label { text: "Apparent temperature:" }
        ComboBox {
            id: apparentCombo
            model: [
                { text: "Apparent temperature", value: "apparent" },
                { text: "Windchill/Heat index", value: "windchill" }
            ]
            textRole: "text"
            onActivated: root.cfg_apparentTemperatureMode = model[currentIndex].value
        }
    }
}
