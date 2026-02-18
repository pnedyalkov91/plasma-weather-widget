import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtPositioning
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: root


    property bool cfg_autoDetectLocation: true
    property string cfg_locationName: ""
    property real cfg_latitude: 0.0
    property real cfg_longitude: 0.0
    property int cfg_altitude: 0
    property string cfg_timezone: ""
    property string cfg_altitudeUnit: "m"

    property var searchResults: []
    property bool autoDetectBusy: false
    property string autoDetectStatus: ""

    property int pageIndex: 0

    function displayAltitudeUnit() {
        return cfg_altitudeUnit === "ft" ? "feet" : "meters";
    }

    function openSearchPage() {
        searchPanel.selectedResult = null;
        searchPanel.selectedIndex = -1;
        resultsList.currentIndex = -1;
        searchField.text = root.cfg_locationName.split(",")[0].trim();
        root.performSearch(searchField.text);
        root.pageIndex = 1;
    }

    function closeSearchPage() {
        root.pageIndex = 0;
    }

    function performSearch(query) {
        if (!query || query.trim().length < 2) {
            searchResults = [];
            searchPanel.selectedResult = null;
            searchPanel.selectedIndex = -1;
            resultsList.currentIndex = -1;
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
                searchPanel.selectedResult = null;
                searchPanel.selectedIndex = -1;
                resultsList.currentIndex = -1;
                return;
            }
            var data = JSON.parse(req.responseText);
            searchResults = data.results ? data.results : [];
            searchPanel.selectedResult = null;
            searchPanel.selectedIndex = -1;
            resultsList.currentIndex = -1;
        };
        req.open("GET", endpoint);
        req.send();
    }

    function reverseGeocode(lat, lon) {
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
                if (meta.timezone) cfg_timezone = meta.timezone;
                if (meta.elevation !== undefined && !isNaN(meta.elevation)) cfg_altitude = Math.round(meta.elevation);
            }
        };
        metaReq.open("GET", metaEndpoint);
        metaReq.send();

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
                        cfg_locationName = city.length > 0 && country.length > 0 ? (city + ", " + country) : (city + country);
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

    Timer {
        id: searchDebounce
        interval: 260
        repeat: false
        onTriggered: root.performSearch(searchField.text)
    }

    Item {
        anchors.fill: parent
        clip: true

        Row {
            id: pageRow
            height: parent.height
            width: parent.width * 2
            x: -root.pageIndex * parent.width

            Behavior on x {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.InOutCubic
                }
            }

            Item {
                width: parent.width / 2
                height: parent.height

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
                            Label { text: "ℹ"; font.pixelSize: 18 }
                            Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                text: "Please change location name to your liking and correct altitude and timezone if they are not auto-detected correctly."
                            }
                        }
                    }

                    ButtonGroup { id: locationModeGroup }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            RadioButton {
                                text: "Automatically detect location"
                                checked: root.cfg_autoDetectLocation
                                ButtonGroup.group: locationModeGroup
                                onClicked: root.cfg_autoDetectLocation = true
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 24
                            spacing: 8
                            Label {
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                opacity: 0.78
                                text: root.autoDetectBusy
                                    ? "Detecting…"
                                    : (root.autoDetectStatus.length > 0
                                        ? root.autoDetectStatus
                                        : "GeoLocation can be provided by KDE/GeoClue2 depending on system configuration and permissions.")
                            }
                            Button {
                                text: "Refresh"
                                visible: root.cfg_autoDetectLocation
                                enabled: root.cfg_autoDetectLocation && !root.autoDetectBusy
                                onClicked: root.refreshAutoDetectedLocation()
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            RadioButton {
                                text: "Use manual location"
                                checked: !root.cfg_autoDetectLocation
                                ButtonGroup.group: locationModeGroup
                                onClicked: root.cfg_autoDetectLocation = false
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 24
                            spacing: 8
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
                            enabled: !root.cfg_autoDetectLocation
                            opacity: root.cfg_autoDetectLocation ? 0.45 : 1.0
                            onClicked: root.openSearchPage()
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
            }

            Item {
                id: searchPanel
                width: parent.width / 2
                height: parent.height

                property var selectedResult: null
                property int selectedIndex: -1

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ToolButton {
                            icon.name: "go-previous"
                            text: ""
                            onClicked: root.closeSearchPage()
                        }

                        Label {
                            text: "Search location"
                            font.bold: true
                            font.pixelSize: 16
                        }

                        Item { Layout.fillWidth: true }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TextField {
                            id: searchField
                            Layout.preferredWidth: Math.min(460, searchPanel.width * 2.72)
                            Layout.fillWidth: true
                            placeholderText: ""
                            selectByMouse: true
                            onTextEdited: {
                                searchPanel.selectedResult = null;
                                searchPanel.selectedIndex = -1;
                                resultsList.currentIndex = -1;
                                searchDebounce.restart();
                            }
                            onAccepted: root.performSearch(text)
                        }

                        Button {
                            text: "Search"
                            icon.name: "edit-find"
                            enabled: searchField.text.trim().length >= 2
                            onClicked: root.performSearch(searchField.text)
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Label { text: "Results"; font.bold: true; opacity: 0.8 }

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
                            currentIndex: searchPanel.selectedIndex

                            delegate: Rectangle {
                                required property var modelData
                                required property int index

                                width: ListView.view.width
                                height: 34
                                color: index === searchPanel.selectedIndex ? Kirigami.Theme.highlightColor : "transparent"

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
                                    color: index === searchPanel.selectedIndex ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        searchPanel.selectedIndex = index;
                                        searchPanel.selectedResult = modelData;
                                        resultsList.currentIndex = index;
                                    }
                                    onDoubleClicked: {
                                        searchPanel.selectedIndex = index;
                                        searchPanel.selectedResult = modelData;
                                        root.applySearchResult(modelData);
                                        root.closeSearchPage();
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        Layout.alignment: Qt.AlignRight
                        text: "Double-click a result to apply and return"
                        opacity: 0.72
                    }
                }
            }
        }
    }
}
