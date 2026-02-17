import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property string cfg_locationName: "London, United Kingdom"
    property real cfg_latitude: 51.5072
    property real cfg_longitude: -0.1276
    property int cfg_altitude: 35
    property string cfg_timezone: "Europe/London"

    property string cfg_temperatureUnit: "C"
    property string cfg_pressureUnit: "hPa"
    property string cfg_windSpeedUnit: "kmh"
    property string cfg_precipitationUnit: "mm"
    property string cfg_altitudeUnit: "m"
    property string cfg_apparentTemperatureMode: "apparent"

    property string cfg_tooltipStyle: "verbose"
    property string cfg_forecastLayout: "rows"
    property int cfg_forecastDays: 5
    property bool cfg_roundValues: true
    property bool cfg_singlePanelRow: true

    property bool cfg_showScrollbox: true
    property int cfg_scrollboxLines: 2
    property string cfg_scrollboxItems: "Humidity;Wind;Pressure;Dew Point;Visibility"
    property bool cfg_animateTransitions: true

    property int cfg_refreshIntervalMinutes: 15
    property bool cfg_autoRefresh: true

    implicitWidth: 700
    implicitHeight: 520

    property var searchResults: []

    function applyComboValue(combo, value) {
        for (var i = 0; i < combo.model.length; ++i) {
            if (combo.model[i].value === value) {
                combo.currentIndex = i;
                return;
            }
        }
    }

    function triggerLocationSearch() {
        if (!searchField.text || searchField.text.trim().length < 2) {
            return;
        }

        var req = new XMLHttpRequest();
        var endpoint = "https://geocoding-api.open-meteo.com/v1/search?count=20&language=en&format=json&name="
            + encodeURIComponent(searchField.text.trim());
        req.onreadystatechange = function() {
            if (req.readyState !== XMLHttpRequest.DONE) {
                return;
            }

            if (req.status !== 200) {
                searchResults = [];
                return;
            }

            var data = JSON.parse(req.responseText);
            searchResults = data.results ? data.results : [];
        };
        req.open("GET", endpoint);
        req.send();
    }

    Component.onCompleted: {
        applyComboValue(temperatureCombo, cfg_temperatureUnit);
        applyComboValue(pressureCombo, cfg_pressureUnit);
        applyComboValue(windCombo, cfg_windSpeedUnit);
        applyComboValue(precipCombo, cfg_precipitationUnit);
        applyComboValue(altitudeCombo, cfg_altitudeUnit);
        applyComboValue(apparentCombo, cfg_apparentTemperatureMode);
        applyComboValue(tooltipCombo, cfg_tooltipStyle);
        applyComboValue(layoutCombo, cfg_forecastLayout);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        TabBar {
            id: tabs
            Layout.fillWidth: true
            TabButton { text: "Location" }
            TabButton { text: "Units" }
            TabButton { text: "Appearance" }
            TabButton { text: "Scrollbox" }
        }

        StackLayout {
            currentIndex: tabs.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true

            Frame {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        color: Qt.rgba(0.88, 0.85, 0.8, 0.65)
                        radius: 4
                        implicitHeight: 64
                        Label {
                            anchors.fill: parent
                            anchors.margins: 10
                            wrapMode: Text.WordWrap
                            text: "Please set location name and correct coordinates/timezone if needed."
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        rowSpacing: 8
                        columnSpacing: 10

                        Label { text: "Location name:" }
                        TextField {
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            text: root.cfg_locationName
                            onTextChanged: root.cfg_locationName = text
                        }

                        Label { text: "Latitude:" }
                        SpinBox {
                            id: latitudeSpin
                            from: -900000
                            to: 900000
                            stepSize: 1
                            editable: true
                            value: Math.round(root.cfg_latitude * 10000)
                            textFromValue: function(value) { return (value / 10000).toFixed(4); }
                            valueFromText: function(text) { return Math.round(parseFloat(text) * 10000); }
                            onValueModified: root.cfg_latitude = value / 10000
                        }
                        Label { text: "°" }

                        Label { text: "Longitude:" }
                        SpinBox {
                            id: longitudeSpin
                            from: -1800000
                            to: 1800000
                            stepSize: 1
                            editable: true
                            value: Math.round(root.cfg_longitude * 10000)
                            textFromValue: function(value) { return (value / 10000).toFixed(4); }
                            valueFromText: function(text) { return Math.round(parseFloat(text) * 10000); }
                            onValueModified: root.cfg_longitude = value / 10000
                        }
                        Label { text: "°" }

                        Label { text: "Altitude:" }
                        SpinBox {
                            from: -500
                            to: 10000
                            value: root.cfg_altitude
                            onValueModified: root.cfg_altitude = value
                        }
                        Label { text: root.cfg_altitudeUnit === "ft" ? "feet" : "meters" }

                        Label { text: "Timezone:" }
                        TextField {
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            text: root.cfg_timezone
                            onTextChanged: root.cfg_timezone = text
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            placeholderText: "Search location (e.g. Vienna)"
                        }
                        Button {
                            text: "Search"
                            onClicked: triggerLocationSearch()
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: root.searchResults
                        delegate: ItemDelegate {
                            required property var modelData
                            width: ListView.view.width
                            text: modelData.name + ", " + (modelData.country ? modelData.country : "")
                            onClicked: {
                                root.cfg_locationName = modelData.name + ", " + (modelData.country ? modelData.country : "")
                                root.cfg_latitude = modelData.latitude
                                root.cfg_longitude = modelData.longitude
                                root.cfg_timezone = modelData.timezone ? modelData.timezone : root.cfg_timezone
                                if (modelData.elevation !== undefined) {
                                    root.cfg_altitude = Math.round(modelData.elevation)
                                }
                                latitudeSpin.value = Math.round(root.cfg_latitude * 10000)
                                longitudeSpin.value = Math.round(root.cfg_longitude * 10000)
                            }
                        }
                    }
                }
            }

            Frame {
                Layout.fillWidth: true
                Layout.fillHeight: true
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

            Frame {
                Layout.fillWidth: true
                Layout.fillHeight: true
                GridLayout {
                    anchors.fill: parent
                    columns: 2
                    rowSpacing: 8
                    columnSpacing: 12

                    Label { text: "Tooltip style:" }
                    ComboBox {
                        id: tooltipCombo
                        model: [
                            { text: "Verbose", value: "verbose" },
                            { text: "Simple", value: "simple" }
                        ]
                        textRole: "text"
                        onActivated: root.cfg_tooltipStyle = model[currentIndex].value
                    }

                    Label { text: "Forecast layout:" }
                    ComboBox {
                        id: layoutCombo
                        model: [
                            { text: "Days in rows", value: "rows" },
                            { text: "Days in columns", value: "columns" }
                        ]
                        textRole: "text"
                        onActivated: root.cfg_forecastLayout = model[currentIndex].value
                    }

                    Label { text: "Number of forecast days:" }
                    SpinBox {
                        from: 3
                        to: 7
                        value: root.cfg_forecastDays
                        onValueModified: root.cfg_forecastDays = value
                    }

                    CheckBox {
                        Layout.columnSpan: 2
                        text: "Use only a single panel row"
                        checked: root.cfg_singlePanelRow
                        onToggled: root.cfg_singlePanelRow = checked
                    }

                    CheckBox {
                        Layout.columnSpan: 2
                        text: "Round values"
                        checked: root.cfg_roundValues
                        onToggled: root.cfg_roundValues = checked
                    }

                    CheckBox {
                        Layout.columnSpan: 2
                        text: "Refresh weather automatically"
                        checked: root.cfg_autoRefresh
                        onToggled: root.cfg_autoRefresh = checked
                    }

                    Label { text: "Refresh interval (minutes):" }
                    SpinBox {
                        from: 5
                        to: 180
                        value: root.cfg_refreshIntervalMinutes
                        onValueModified: root.cfg_refreshIntervalMinutes = value
                    }
                }
            }

            Frame {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 10

                    RowLayout {
                        CheckBox {
                            text: "Show scrollbox"
                            checked: root.cfg_showScrollbox
                            onToggled: root.cfg_showScrollbox = checked
                        }

                        Label { text: "Lines:" }
                        SpinBox {
                            from: 1
                            to: 6
                            value: root.cfg_scrollboxLines
                            onValueModified: root.cfg_scrollboxLines = value
                        }
                    }

                    Label {
                        text: "Labels to display (semicolon-separated):"
                    }
                    TextArea {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: root.cfg_scrollboxItems
                        wrapMode: TextEdit.Wrap
                        onTextChanged: root.cfg_scrollboxItems = text
                    }

                    CheckBox {
                        text: "Animate transitions between labels"
                        checked: root.cfg_animateTransitions
                        onToggled: root.cfg_animateTransitions = checked
                    }
                }
            }
        }
    }
}
