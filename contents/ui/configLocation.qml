import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtPositioning
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: root

    property bool cfg_autoDetectLocation: false
    property string cfg_locationName: "London, United Kingdom"
    property real cfg_latitude: 51.5072
    property real cfg_longitude: -0.1276
    property int cfg_altitude: 35
    property string cfg_timezone: "Europe/London"
    property string cfg_altitudeUnit: "m"

    property var searchResults: []
    property bool autoDetectBusy: false
    property string autoDetectStatus: ""

    function displayAltitudeUnit() {
        return cfg_altitudeUnit === "ft" ? "feet" : "meters";
    }

    function performSearch(query) {
        if (!query || query.trim().length < 2) {
            searchResults = [];
            searchDialog.selectedResult = null;
            searchDialog.selectedIndex = -1;
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
                searchDialog.selectedResult = null;
                searchDialog.selectedIndex = -1;
                return;
            }
            var data = JSON.parse(req.responseText);
            searchResults = data.results ? data.results : [];
            searchDialog.selectedResult = null;
            searchDialog.selectedIndex = -1;
            resultsList.currentIndex = -1;
        };
        req.open("GET", endpoint);
        req.send();
    }

    function reverseGeocode(lat, lon) {
        // 1) Fetch timezone/elevation from Open-Meteo forecast metadata.
        var metaReq = new XMLHttpRequest();
        var metaEndpoint = "https://api.open-meteo.com/v1/forecast?latitude="
            + encodeURIComponent(lat)
            + "&longitude="
            + encodeURIComponent(lon)
            + "&current=temperature_2m&timezone=auto";

        metaReq.onreadystatechange = function() {
            if (metaReq.readyState !== XMLHttpRequest.DONE) {
                return;
            }

            if (metaReq.status === 200) {
                var meta = JSON.parse(metaReq.responseText);
                if (meta.timezone) {
                    cfg_timezone = meta.timezone;
                }
                if (meta.elevation !== undefined && !isNaN(meta.elevation)) {
                    cfg_altitude = Math.round(meta.elevation);
                }
            }
        };
        metaReq.open("GET", metaEndpoint);
        metaReq.send();

        // 2) Try reverse geocoding for a human-readable city/country.
        var req = new XMLHttpRequest();
        var endpoint = "https://nominatim.openstreetmap.org/reverse?format=jsonv2&zoom=10&addressdetails=1&lat="
            + encodeURIComponent(lat)
            + "&lon="
            + encodeURIComponent(lon);

        req.onreadystatechange = function() {
            if (req.readyState !== XMLHttpRequest.DONE) {
                return;
            }

            if (req.status === 200) {
                var data = JSON.parse(req.responseText);
                if (data && data.address) {
                    var a = data.address;
                    var city = a.city || a.town || a.village || a.municipality || a.county || "";
                    var country = a.country || "";
                    if (city.length > 0 || country.length > 0) {
                        cfg_locationName = city.length > 0 && country.length > 0
                            ? (city + ", " + country)
                            : (city + country);
                    }
                }
                autoDetectStatus = "Auto-detected via GeoClue2.";
            } else {
                autoDetectStatus = "Auto-detection updated coordinates.";
            }
            autoDetectBusy = false;
        };

        req.open("GET", endpoint);
        req.send();
    }


    function refreshAutoDetectedLocation() {
        if (!cfg_autoDetectLocation) {
            autoDetectBusy = false;
            return;
        }

        autoDetectBusy = true;
        autoDetectStatus = "Requesting location from GeoClue2…";

        if (!positionSource.supportedPositioningMethods) {
            autoDetectBusy = false;
            autoDetectStatus = "GeoClue2 location unavailable on this system.";
            return;
        }

        positionSource.update();
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

    onCfg_autoDetectLocationChanged: {
        if (cfg_autoDetectLocation) {
            refreshAutoDetectedLocation();
        } else {
            autoDetectBusy = false;
            autoDetectStatus = "";
        }
    }

    PositionSource {
        id: positionSource
        active: root.cfg_autoDetectLocation
        updateInterval: 300000

        onPositionChanged: {
            if (!root.cfg_autoDetectLocation) {
                return;
            }

            var c = position.coordinate;
            if (!c || !c.isValid) {
                root.autoDetectBusy = false;
                root.autoDetectStatus = "Unable to get valid position from GeoClue2.";
                return;
            }

            root.cfg_latitude = c.latitude;
            root.cfg_longitude = c.longitude;
            if (!isNaN(c.altitude)) {
                root.cfg_altitude = Math.round(c.altitude);
            }

            root.reverseGeocode(c.latitude, c.longitude);
        }

        onSourceErrorChanged: {
            if (sourceError !== PositionSource.NoError) {
                root.autoDetectBusy = false;
                root.autoDetectStatus = "GeoClue2 error while retrieving location.";
            }
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

        ButtonGroup {
            id: locationModeGroup
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RadioButton {
                text: "Automatically detect location"
                checked: root.cfg_autoDetectLocation
                ButtonGroup.group: locationModeGroup
                onClicked: root.cfg_autoDetectLocation = true
            }

            RowLayout {
                Layout.leftMargin: 24
                spacing: 8
                Label {
                    text: root.autoDetectBusy ? "Detecting…" : (root.autoDetectStatus.length > 0 ? root.autoDetectStatus : "GeoLocation can be provided by KDE/GeoClue2 depending on system configuration and permissions.")
                    opacity: 0.78
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
                Button {
                    text: "Refresh"
                    enabled: root.cfg_autoDetectLocation && !root.autoDetectBusy
                    visible: root.cfg_autoDetectLocation
                    onClicked: root.refreshAutoDetectedLocation()
                }
            }

            RowLayout {
                Layout.leftMargin: 24
                RadioButton {
                    text: "Use manual location"
                    checked: !root.cfg_autoDetectLocation
                    ButtonGroup.group: locationModeGroup
                    onClicked: root.cfg_autoDetectLocation = false
                }
                Label { text: "Latitude:"; opacity: root.cfg_autoDetectLocation ? 0.45 : 1.0 }
                Label { text: Number(root.cfg_latitude).toFixed(2); opacity: root.cfg_autoDetectLocation ? 0.45 : 1.0 }
                Label { text: "Longitude:"; opacity: root.cfg_autoDetectLocation ? 0.45 : 1.0 }
                Label { text: Number(root.cfg_longitude).toFixed(2); opacity: root.cfg_autoDetectLocation ? 0.45 : 1.0 }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 10
            rowSpacing: 8
            enabled: !root.cfg_autoDetectLocation
            opacity: root.cfg_autoDetectLocation ? 0.5 : 1.0

            Label { text: "Location name:" }
            TextField {
                Layout.columnSpan: 2
                Layout.fillWidth: true
                text: root.cfg_locationName
                onTextChanged: root.cfg_locationName = text
            }
            Button {
                text: "Change..."
                visible: true
                enabled: !root.cfg_autoDetectLocation
                opacity: root.cfg_autoDetectLocation ? 0.45 : 1.0
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

        property var selectedResult: null
        property int selectedIndex: -1

        onOpened: {
            selectedResult = null;
            selectedIndex = -1;
            resultsList.currentIndex = -1;
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
                    selectByMouse: true
                    color: "white"
                    background: Rectangle {
                        radius: 4
                        color: Qt.rgba(0.10, 0.10, 0.10, 0.35)
                        border.color: Qt.rgba(0.7, 0.7, 0.7, 0.8)
                    }
                    onAccepted: root.performSearch(text)
                }
                Button {
                    text: "Search"
                    icon.name: "edit-find"
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
                    currentIndex: searchDialog.selectedIndex

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        width: ListView.view.width
                        height: 34
                        color: index === searchDialog.selectedIndex
                            ? Qt.rgba(0.24, 0.52, 0.91, 0.9)
                            : "transparent"

                        Label {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            text: {
                                var admin = modelData.admin1 ? ", " + modelData.admin1 : "";
                                var country = modelData.country ? ", " + modelData.country : "";
                                return modelData.name + admin + country;
                            }
                            color: "white"
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                searchDialog.selectedIndex = index;
                                searchDialog.selectedResult = modelData;
                                resultsList.currentIndex = index;
                            }
                            onDoubleClicked: {
                                searchDialog.selectedIndex = index;
                                searchDialog.selectedResult = modelData;
                                root.applySearchResult(modelData);
                                searchDialog.close();
                            }
                        }
                    }
                }
            }
        }

        footer: DialogButtonBox {
            alignment: Qt.AlignRight

            Button {
                text: "OK"
                icon.name: "dialog-ok-apply"
                enabled: searchDialog.selectedIndex >= 0
                onClicked: {
                    root.applySearchResult(searchDialog.selectedResult);
                    searchDialog.close();
                }
            }

            Button {
                text: "Cancel"
                icon.name: "dialog-cancel"
                onClicked: searchDialog.close()
            }
        }
    }
}
