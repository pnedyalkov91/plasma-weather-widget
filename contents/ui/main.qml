import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    implicitWidth: 460
    implicitHeight: 340

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
        if (code === 0) return "Clear";
        if (code === 1 || code === 2) return "Partly Cloudy";
        if (code === 3) return "Overcast";
        if (code === 45 || code === 48) return "Fog";
        if (code === 51 || code === 53 || code === 55) return "Drizzle";
        if (code === 61 || code === 63 || code === 65) return "Rain";
        if (code === 71 || code === 73 || code === 75) return "Snow";
        if (code === 80 || code === 81 || code === 82) return "Showers";
        if (code === 95 || code === 96 || code === 99) return "Thunderstorm";
        return "Unknown";
    }

    function weatherCodeToIcon(code) {
        if (code === 0) return "weather-clear";
        if (code === 1 || code === 2) return "weather-few-clouds";
        if (code === 3) return "weather-overcast";
        if (code === 45 || code === 48) return "weather-fog";
        if (code === 51 || code === 53 || code === 55) return "weather-showers-scattered";
        if (code === 61 || code === 63 || code === 65) return "weather-showers";
        if (code === 71 || code === 73 || code === 75) return "weather-snow";
        if (code === 80 || code === 81 || code === 82) return "weather-showers";
        if (code === 95 || code === 96 || code === 99) return "weather-storm";
        return "weather-severe-alert";
    }

    function tempValue(celsius) {
        if (isNaN(celsius)) return "--";
        var value = Plasmoid.configuration.temperatureUnit === "F" ? (celsius * 9 / 5 + 32) : celsius;
        if (Plasmoid.configuration.roundValues) value = Math.round(value);
        else value = Number(value).toFixed(1);
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
                        day: Qt.formatDate(new Date(data.daily.time[i]), "dd MMM"),
                        maxC: data.daily.temperature_2m_max[i],
                        minC: data.daily.temperature_2m_min[i],
                        code: data.daily.weather_code[i]
                    });
                }
            }

            updateText = "Updated " + new Date().toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
        };

        request.open("GET", endpoint);
        request.send();
    }

    function scrollLines() {
        var raw = Plasmoid.configuration.scrollboxItems;
        if (!raw || raw.length === 0) {
            return ["Humidity", "Wind", "Dew Point", "Visibility", "Pressure"];
        }
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
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#7f5a2d" }
            GradientStop { position: 1.0; color: "#3f3226" }
        }
        border.color: "#8e7c68"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 5

            Rectangle {
                visible: Plasmoid.configuration.showScrollbox
                Layout.fillWidth: true
                Layout.preferredHeight: 26 * Math.max(1, Plasmoid.configuration.scrollboxLines)
                color: "#2f2f2f"
                border.color: "#9a8d7c"

                Column {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4

                    Repeater {
                        model: Math.max(1, Plasmoid.configuration.scrollboxLines)
                        Label {
                            color: "white"
                            text: {
                                var lines = root.scrollLines();
                                if (lines.length === 0) return "";
                                return root.scrollLineText(lines[(root.scrollIndex + index) % lines.length]);
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#594736"
                border.color: "#9a8d7c"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 6

                    Rectangle {
                        Layout.preferredWidth: 160
                        Layout.fillHeight: true
                        color: "#4a3b2d"
                        border.color: "#8e7c68"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 5

                            Label { text: Qt.formatTime(new Date(), "HH:mm"); color: "white"; font.bold: true }
                            Kirigami.Icon {
                                source: weatherCodeToIcon(weatherCode)
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 72
                                Layout.preferredHeight: 72
                            }
                            Label { text: weatherCodeToText(weatherCode); color: "white"; Layout.alignment: Qt.AlignHCenter }
                            Label {
                                text: Plasmoid.configuration.locationName
                                color: "white"
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                                font.bold: true
                            }
                            Item { Layout.fillHeight: true }
                            Label { text: loading ? "Updating..." : updateText; color: "#d7d7d7"; font.pixelSize: 10 }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 118
                            color: "#4a3b2d"
                            border.color: "#8e7c68"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 10

                                Label {
                                    text: tempValue(temperatureC)
                                    color: "white"
                                    font.pixelSize: 44
                                    font.bold: true
                                }

                                Column {
                                    spacing: 4
                                    Label { text: "Wind: " + windValue(windKmh); color: "white" }
                                    Label { text: "Feels like: " + tempValue(apparentC); color: "white" }
                                    Label { text: "Humidity: " + (isNaN(humidityPercent) ? "--" : Math.round(humidityPercent) + "%"); color: "white" }
                                    Label { text: "Pressure: " + pressureValue(pressureHpa); color: "white" }
                                }
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 3
                            rowSpacing: 4
                            columnSpacing: 4

                            Repeater {
                                model: dailyData
                                delegate: Rectangle {
                                    required property var modelData
                                    color: "#4a3b2d"
                                    border.color: "#8e7c68"
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        spacing: 2

                                        Label { text: modelData.day; color: "white"; font.bold: true }
                                        Kirigami.Icon {
                                            source: weatherCodeToIcon(modelData.code)
                                            width: 28
                                            height: 28
                                        }
                                        Label { text: tempValue(modelData.maxC) + " / " + tempValue(modelData.minC); color: "white" }
                                        Label { text: weatherCodeToText(modelData.code); color: "#f0f0f0"; font.pixelSize: 10 }
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
