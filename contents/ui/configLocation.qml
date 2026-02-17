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

    property var searchResults: []

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

    ColumnLayout {
        anchors.fill: parent

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Set a single location for this widget. Use search or enter coordinates manually."
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: 10
            rowSpacing: 8

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
            Label { text: "m" }

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
                placeholderText: "Search city (e.g. Helsinki)"
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
