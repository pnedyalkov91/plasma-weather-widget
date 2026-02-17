import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    implicitWidth: 520
    implicitHeight: 280

    property bool loading: false
    property real temperatureC: NaN
    property real apparentC: NaN
    property real windKmh: NaN
    property real pressureHpa: NaN
    property real humidityPercent: NaN
    property real visibilityKm: NaN
    property real dewPointC: NaN
    property int weatherCode: -1
    property var dailyData: []
    property int scrollIndex: 0
    property string updateText: ""

    function weatherCodeToText(code) {
        if (code === 0) return "Sunny";
        if (code === 1 || code === 2) return "Mostly cloudy";
        if (code === 3) return "Overcast";
        if (code === 45 || code === 48) return "Fog";
        if (code === 61 || code === 63 || code === 65) return "Rain";
        if (code === 71 || code === 73 || code === 75) return "Snow";
        if (code === 95 || code === 96 || code === 99) return "Thunderstorm";
        return "Partly cloudy";
    }

    function weatherCodeToIcon(code) {
        if (code === 0) return "weather-clear";
        if (code === 1 || code === 2) return "weather-few-clouds";
        if (code === 3) return "weather-overcast";
        if (code === 45 || code === 48) return "weather-fog";
        if (code === 61 || code === 63 || code === 65) return "weather-showers";
        if (code === 71 || code === 73 || code === 75) return "weather-snow";
        if (code === 95 || code === 96 || code === 99) return "weather-storm";
        return "weather-few-clouds";
    }

    function tempValue(celsius) {
        if (isNaN(celsius)) return "--";
        var value = Plasmoid.configuration.temperatureUnit === "F" ? (celsius * 9 / 5 + 32) : celsius;
        value = Plasmoid.configuration.roundValues ? Math.round(value) : Number(value).toFixed(1);
        return value + (Plasmoid.configuration.temperatureUnit === "F" ? "°F" : "°C");
    }

    function windValue(kmh) {
        if (isNaN(kmh)) return "--";
        var unit = Plasmoid.configuration.windSpeedUnit;
        if (unit === "mph") return (kmh * 0.621371).toFixed(1) + " mph";
        if (unit === "ms") return (kmh / 3.6).toFixed(1) + " m/s";
        if (unit === "kn") return (kmh * 0.539957).toFixed(1) + " kn";
        return Math.round(kmh) + " km/h";
    }

    function pressureValue(hpa) {
        if (isNaN(hpa)) return "--";
        if (Plasmoid.configuration.pressureUnit === "mmHg") return (hpa * 0.750062).toFixed(0) + " mmHg";
        if (Plasmoid.configuration.pressureUnit === "inHg") return (hpa * 0.02953).toFixed(2) + " inHg";
        return Math.round(hpa) + " hPa";
    }

    function refreshNow() {
        loading = true;
        var request = new XMLHttpRequest();
        var endpoint = "https://api.open-meteo.com/v1/forecast?latitude=" + Plasmoid.configuration.latitude
            + "&longitude=" + Plasmoid.configuration.longitude
            + "&timezone=" + encodeURIComponent(Plasmoid.configuration.timezone)
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,surface_pressure,dew_point_2m,visibility"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min";

        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE) return;
            loading = false;
            if (request.status !== 200) {
                updateText = "Update failed";
                return;
            }

            var data = JSON.parse(request.responseText);
            if (!data.current) return;

            temperatureC = data.current.temperature_2m;
            apparentC = data.current.apparent_temperature;
            humidityPercent = data.current.relative_humidity_2m;
            windKmh = data.current.wind_speed_10m;
            pressureHpa = data.current.surface_pressure;
            dewPointC = data.current.dew_point_2m;
            visibilityKm = data.current.visibility / 1000.0;
            weatherCode = data.current.weather_code;

            dailyData = [];
            if (data.daily && data.daily.time) {
                var maxDays = Math.min(Plasmoid.configuration.forecastDays, data.daily.time.length);
                for (var i = 0; i < maxDays; ++i) {
                    dailyData.push({
                        day: Qt.formatDate(new Date(data.daily.time[i]), "ddd"),
                        maxC: data.daily.temperature_2m_max[i],
                        minC: data.daily.temperature_2m_min[i],
                        code: data.daily.weather_code[i]
                    });
                }
            }
            updateText = "Updated " + Qt.formatTime(new Date(), "HH:mm");
        };

        request.open("GET", endpoint);
        request.send();
    }

    function scrollLines() {
        var raw = Plasmoid.configuration.scrollboxItems;
        if (!raw || raw.length === 0) return ["Humidity", "Wind", "Pressure"];
        return raw.split(";");
    }

    function scrollLineText(labelName) {
        var key = labelName.trim().toLowerCase();
        if (key === "humidity") return "Humidity: " + (isNaN(humidityPercent) ? "--" : Math.round(humidityPercent) + "%");
        if (key === "wind") return "Wind: " + windValue(windKmh);
        if (key === "pressure") return "Pressure: " + pressureValue(pressureHpa);
        if (key === "dew point") return "Dew Point: " + tempValue(dewPointC);
        if (key === "visibility") return "Visibility: " + (isNaN(visibilityKm) ? "--" : visibilityKm.toFixed(1) + " km");
        return labelName + ": --";
    }

    Component.onCompleted: refreshNow()

    Connections {
        target: Plasmoid.configuration
        function onLatitudeChanged() { refreshNow(); }
        function onLongitudeChanged() { refreshNow(); }
        function onTimezoneChanged() { refreshNow(); }
        function onForecastDaysChanged() { refreshNow(); }
    }

    Timer {
        interval: Math.max(5, Plasmoid.configuration.refreshIntervalMinutes) * 60 * 1000
        running: Plasmoid.configuration.autoRefresh
        repeat: true
        onTriggered: refreshNow()
    }

    Timer {
        interval: 3000
        running: Plasmoid.configuration.showScrollbox && Plasmoid.configuration.animateTransitions
        repeat: true
        onTriggered: {
            var lines = scrollLines();
            scrollIndex = lines.length === 0 ? 0 : (scrollIndex + 1) % lines.length;
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: Qt.rgba(0.22, 0.16, 0.10, Math.max(0.2, Math.min(1, Plasmoid.configuration.panelOpacityPercent / 100)))
        border.color: Qt.rgba(0.80, 0.72, 0.58, 0.9)
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 6

            Label {
                Layout.fillWidth: true
                text: Plasmoid.configuration.locationName
                horizontalAlignment: Text.AlignHCenter
                color: "white"
                font.bold: true
            }

            Rectangle {
                visible: Plasmoid.configuration.showScrollbox
                Layout.fillWidth: true
                Layout.preferredHeight: 24 * Math.max(1, Plasmoid.configuration.scrollboxLines)
                color: Qt.rgba(0.12, 0.12, 0.12, 0.45)
                border.color: Qt.rgba(0.80, 0.72, 0.58, 0.7)

                Column {
                    anchors.fill: parent
                    anchors.margins: 4
                    Repeater {
                        model: Math.max(1, Plasmoid.configuration.scrollboxLines)
                        delegate: Label {
                            required property int index
                            text: {
                                var lines = root.scrollLines();
                                return lines.length === 0 ? "" : root.scrollLineText(lines[(root.scrollIndex + index) % lines.length]);
                            }
                            color: "white"
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6

                Rectangle {
                    Layout.preferredWidth: Math.max(140, root.width * 0.28)
                    Layout.fillHeight: true
                    color: Qt.rgba(0.25, 0.19, 0.13, 0.45)
                    border.color: Qt.rgba(0.80, 0.72, 0.58, 0.65)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4
                        Label { text: Qt.formatTime(new Date(), "HH:mm"); color: "white"; font.bold: true }
                        Kirigami.Icon {
                            source: weatherCodeToIcon(weatherCode)
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 72
                            Layout.preferredHeight: 72
                        }
                        Label { text: weatherCodeToText(weatherCode); color: "white"; Layout.alignment: Qt.AlignHCenter }
                        Item { Layout.fillHeight: true }
                        Label { text: loading ? "Updating..." : updateText; color: "#d7d7d7"; font.pixelSize: 10 }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(92, root.height * 0.35)
                        color: Qt.rgba(0.25, 0.19, 0.13, 0.45)
                        border.color: Qt.rgba(0.80, 0.72, 0.58, 0.65)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 10

                            Label {
                                text: tempValue(temperatureC)
                                color: "white"
                                font.pixelSize: Math.max(28, Math.min(54, root.width * 0.11))
                                font.bold: true
                            }

                            Column {
                                spacing: 3
                                Label { text: "Wind: " + windValue(windKmh); color: "white" }
                                Label { text: "Feels like: " + tempValue(apparentC); color: "white" }
                                Label { text: "Humidity: " + (isNaN(humidityPercent) ? "--" : Math.round(humidityPercent) + "%"); color: "white" }
                                Label { text: "Pressure: " + pressureValue(pressureHpa); color: "white" }
                            }
                        }
                    }

                    Flow {
                        id: forecastFlow
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        Repeater {
                            model: dailyData
                            delegate: Rectangle {
                                required property var modelData
                                width: Math.max(88, (forecastFlow.width - (forecastFlow.spacing * 4)) / 5)
                                height: Math.max(90, forecastFlow.height / 2 - 4)
                                color: Qt.rgba(0.25, 0.19, 0.13, 0.45)
                                border.color: Qt.rgba(0.80, 0.72, 0.58, 0.65)

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    spacing: 1
                                    Label { text: modelData.day; color: "white"; font.bold: true }
                                    Label { text: tempValue(modelData.maxC) + " / " + tempValue(modelData.minC); color: "#e8e8e8" }
                                    Kirigami.Icon { source: weatherCodeToIcon(modelData.code); width: 24; height: 24 }
                                    Label {
                                        text: weatherCodeToText(modelData.code)
                                        color: "#f0f0f0"
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
