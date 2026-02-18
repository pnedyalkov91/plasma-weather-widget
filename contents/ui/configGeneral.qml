import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property string cfg_weatherProvider: "adaptive"

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Choose weather provider. Adaptive will automatically fallback to other providers if one is unavailable."
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 12

            Label { text: "Weather provider:" }
            ComboBox {
                id: providerCombo
                Layout.fillWidth: true
                model: [
                    { text: "Adaptive", value: "adaptive" },
                    { text: "Open-Meteo", value: "openMeteo" },
                    { text: "OpenWeather", value: "openWeather" },
                    { text: "WeatherAPI.com", value: "weatherApi" },
                    { text: "met.no", value: "metno" }
                ]
                textRole: "text"

                Component.onCompleted: {
                    for (var i = 0; i < model.length; ++i) {
                        if (model[i].value === root.cfg_weatherProvider) {
                            currentIndex = i;
                            break;
                        }
                    }
                }

                onActivated: root.cfg_weatherProvider = model[currentIndex].value
            }
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            opacity: 0.8
            text: "OpenWeather and WeatherAPI.com are preconfigured in this widget build with bundled API keys."
        }

        Item { Layout.fillHeight: true }
    }
}
