import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property alias cfg_selectedCity: selectedCityField.text
    property alias cfg_customCityList: customCityListField.text
    property alias cfg_showFeelsLike: showFeelsLikeCheck.checked
    property alias cfg_showHumidity: showHumidityCheck.checked
    property alias cfg_showWind: showWindCheck.checked
    property alias cfg_showPressure: showPressureCheck.checked
    property alias cfg_showDailyForecast: showDailyForecastCheck.checked
    property alias cfg_temperatureUnit: temperatureUnitCombo.currentValue
    property alias cfg_windSpeedUnit: windUnitCombo.currentValue
    property alias cfg_pressureUnit: pressureUnitCombo.currentValue
    property alias cfg_timeFormat: timeFormatCombo.currentValue
    property alias cfg_refreshIntervalMinutes: refreshIntervalSpin.value
    property alias cfg_autoRefresh: autoRefreshCheck.checked

    implicitWidth: 640

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        TabBar {
            id: tabs
            Layout.fillWidth: true
            TabButton { text: "Location" }
            TabButton { text: "Layout" }
            TabButton { text: "Units" }
            TabButton { text: "Refresh" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabs.currentIndex

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ColumnLayout {
                    width: parent.width
                    spacing: 10

                    Label {
                        text: "Primary city"
                        font.bold: true
                    }
                    TextField {
                        id: selectedCityField
                        Layout.fillWidth: true
                        placeholderText: "London|51.5072|-0.1276"
                    }

                    Label {
                        text: "Additional cities"
                        font.bold: true
                    }
                    Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "Use semicolon-separated values: Name|Latitude|Longitude;Name|Latitude|Longitude"
                        opacity: 0.8
                    }
                    TextArea {
                        id: customCityListField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100
                        placeholderText: "Sofia|42.6977|23.3219;Varna|43.2141|27.9147"
                        wrapMode: TextEdit.Wrap
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ColumnLayout {
                    width: parent.width
                    spacing: 8

                    Label {
                        text: "Data blocks"
                        font.bold: true
                    }
                    CheckBox { id: showFeelsLikeCheck; text: "Show feels-like temperature" }
                    CheckBox { id: showHumidityCheck; text: "Show humidity" }
                    CheckBox { id: showWindCheck; text: "Show wind speed" }
                    CheckBox { id: showPressureCheck; text: "Show pressure" }
                    CheckBox { id: showDailyForecastCheck; text: "Show daily min/max line" }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ColumnLayout {
                    width: parent.width
                    spacing: 10

                    GridLayout {
                        columns: 2
                        columnSpacing: 12
                        rowSpacing: 8

                        Label { text: "Temperature" }
                        ComboBox {
                            id: temperatureUnitCombo
                            textRole: "text"
                            valueRole: "value"
                            model: [
                                { text: "Celsius (°C)", value: "C" },
                                { text: "Fahrenheit (°F)", value: "F" }
                            ]
                        }

                        Label { text: "Wind speed" }
                        ComboBox {
                            id: windUnitCombo
                            textRole: "text"
                            valueRole: "value"
                            model: [
                                { text: "km/h", value: "kmh" },
                                { text: "mph", value: "mph" },
                                { text: "m/s", value: "ms" },
                                { text: "knots", value: "kn" }
                            ]
                        }

                        Label { text: "Pressure" }
                        ComboBox {
                            id: pressureUnitCombo
                            textRole: "text"
                            valueRole: "value"
                            model: [
                                { text: "hPa", value: "hPa" },
                                { text: "mmHg", value: "mmHg" },
                                { text: "inHg", value: "inHg" }
                            ]
                        }

                        Label { text: "Clock" }
                        ComboBox {
                            id: timeFormatCombo
                            textRole: "text"
                            valueRole: "value"
                            model: [
                                { text: "System default", value: "system" },
                                { text: "12-hour", value: "12h" },
                                { text: "24-hour", value: "24h" }
                            ]
                        }
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ColumnLayout {
                    width: parent.width
                    spacing: 10

                    CheckBox {
                        id: autoRefreshCheck
                        text: "Refresh weather automatically"
                    }

                    RowLayout {
                        Label { text: "Interval (minutes):" }
                        SpinBox {
                            id: refreshIntervalSpin
                            from: 5
                            to: 180
                            value: 15
                        }
                    }
                }
            }
        }
    }
}
