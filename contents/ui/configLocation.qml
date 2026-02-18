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
    property string cfg_altitudeUnit: "m"

    property var searchResults: []

    function displayAltitudeUnit() {
        return cfg_altitudeUnit === "ft" ? "feet" : "meters";
    }

    function performSearch(query) {
        if (!query || query.trim().length < 2) {
            searchResults = [];
            return;
        }

        var req = new XMLHttpRequest();
        var endpoint = "https://geocoding-api.open-meteo.com/v1/search?count=20&language=en&format=json&name="
            + encodeURIComponent(query.trim());
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

    function applySearchResult(item) {
        if (!item) {
            return;
        }

        cfg_locationName = item.name + ", " + (item.country ? item.country : "");
        cfg_latitude = item.latitude;
        cfg_longitude = item.longitude;
        cfg_timezone = item.timezone ? item.timezone : cfg_timezone;
        if (item.elevation !== undefined) {
            cfg_altitude = Math.round(item.elevation);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 74
            color: Qt.rgba(0.88, 0.85, 0.80, 0.65)
            radius: 3

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Label {
                    text: "ℹ"
                    font.pixelSize: 18
                }

                Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: "Please change location name to your liking and correct altitude and timezone if they are not auto-detected correctly."
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 10
            rowSpacing: 8

            Label { text: "Location name:" }
            TextField {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                text: root.cfg_locationName
                onTextChanged: root.cfg_locationName = text
            }
            Button {
                text: "Change..."
                onClicked: {
                    searchField.text = root.cfg_locationName.split(",")[0].trim();
                    root.performSearch(searchField.text);
                    searchDialog.open();
                }
            }

            Label { text: "Latitude:" }
            SpinBox {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                from: -900000
                to: 900000
                editable: true
                stepSize: 1
                value: Math.round(root.cfg_latitude * 10000)
                textFromValue: function(value) { return (value / 10000).toFixed(4); }
                valueFromText: function(text) {
                    var parsed = parseFloat(text);
                    return isNaN(parsed) ? 0 : Math.round(parsed * 10000);
                }
                onValueModified: root.cfg_latitude = value / 10000
            }
            Label { text: "°" }

            Label { text: "Longitude:" }
            SpinBox {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                from: -1800000
                to: 1800000
                editable: true
                stepSize: 1
                value: Math.round(root.cfg_longitude * 10000)
                textFromValue: function(value) { return (value / 10000).toFixed(4); }
                valueFromText: function(text) {
                    var parsed = parseFloat(text);
                    return isNaN(parsed) ? 0 : Math.round(parsed * 10000);
                }
                onValueModified: root.cfg_longitude = value / 10000
            }
            Label { text: "°" }

            Label { text: "Altitude:" }
            SpinBox {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                from: -500
                to: 12000
                value: root.cfg_altitude
                onValueModified: root.cfg_altitude = value
            }
            Label { text: root.displayAltitudeUnit() }

            Label { text: "Timezone:" }
            TextField {
                Layout.columnSpan: 3
                Layout.fillWidth: true
                text: root.cfg_timezone
                onTextChanged: root.cfg_timezone = text
            }
        }

        Item { Layout.fillHeight: true }
    }

    Dialog {
        id: searchDialog
        title: "Search location"
        modal: true
        width: 620
        height: 540
        standardButtons: Dialog.Ok | Dialog.Cancel

        property var selectedResult: null

        onAccepted: {
            root.applySearchResult(selectedResult);
        }

        contentItem: ColumnLayout {
            spacing: 8

            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "Enter a city name or address"
            }

            RowLayout {
                Layout.fillWidth: true
                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: "Vienna"
                    onAccepted: root.performSearch(text)
                }
                Button {
                    text: "Search"
                    onClicked: root.performSearch(searchField.text)
                }
            }

            Label {
                text: "Results"
                font.bold: true
                opacity: 0.8
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                border.color: Qt.rgba(0.6, 0.6, 0.6, 1)
                color: "transparent"

                ListView {
                    id: resultsList
                    anchors.fill: parent
                    clip: true
                    model: root.searchResults

                    delegate: ItemDelegate {
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        highlighted: searchDialog.selectedResult === modelData
                        text: {
                            var admin = modelData.admin1 ? ", " + modelData.admin1 : "";
                            var country = modelData.country ? ", " + modelData.country : "";
                            return modelData.name + admin + country;
                        }
                        onClicked: {
                            searchDialog.selectedResult = modelData;
                            resultsList.currentIndex = index;
                        }
                    }
                }
            }
        }
    }
}
