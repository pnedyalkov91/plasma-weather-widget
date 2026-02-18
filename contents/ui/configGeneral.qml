import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property string cfg_weatherProvider: "openMeteo"
    property string cfg_openWeatherApiKey: ""

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Choose which weather service to use for current conditions."
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
                    { text: "Open-Meteo", value: "openMeteo" },
                    { text: "OpenWeather", value: "openWeather" },
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

            Label {
                text: "OpenWeather API key:"
                visible: root.cfg_weatherProvider === "openWeather"
            }
            TextField {
                Layout.fillWidth: true
                visible: root.cfg_weatherProvider === "openWeather"
                placeholderText: "Enter OpenWeather API key"
                echoMode: TextInput.Password
                text: root.cfg_openWeatherApiKey
                onTextChanged: root.cfg_openWeatherApiKey = text
            }
        }

        Label {
            Layout.fillWidth: true
            visible: root.cfg_weatherProvider === "openWeather"
            wrapMode: Text.WordWrap
            opacity: 0.8
            text: "OpenWeather requires an API key. Without it, weather updates will be skipped."
        }

        Item { Layout.fillHeight: true }
    }
}
