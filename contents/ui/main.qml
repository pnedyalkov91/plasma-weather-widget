import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    implicitWidth: 340
    implicitHeight: 280

    property var builtinCities: [
        { "name": "London", "country": "UK", "lat": 51.5072, "lon": -0.1276 },
        { "name": "Berlin", "country": "Germany", "lat": 52.52, "lon": 13.405 },
        { "name": "Paris", "country": "France", "lat": 48.8566, "lon": 2.3522 },
        { "name": "Rome", "country": "Italy", "lat": 41.9028, "lon": 12.4964 },
        { "name": "Tokyo", "country": "Japan", "lat": 35.6762, "lon": 139.6503 },
        { "name": "New York", "country": "USA", "lat": 40.7128, "lon": -74.006 },
        { "name": "Sofia", "country": "Bulgaria", "lat": 42.6977, "lon": 23.3219 }
    ]

    property var cities: []
    property var selectedCityData: ({ "name": "London", "country": "UK", "lat": 51.5072, "lon": -0.1276 })
    property bool loading: false

    property real temperatureC: NaN
    property real apparentC: NaN
    property real windKmh: NaN
    property real pressureHpa: NaN
    property real humidityPercent: NaN
    property int weatherCode: -1
    property real maxTempC: NaN
    property real minTempC: NaN
    property string updateText: ""

    function parseCityString(cityString) {
        if (!cityString || cityString.length === 0) {
            return null;
        }

        var parts = cityString.split("|");
        if (parts.length < 3) {
            return null;
        }

        var parsedLat = parseFloat(parts[1]);
        var parsedLon = parseFloat(parts[2]);
        if (isNaN(parsedLat) || isNaN(parsedLon)) {
            return null;
        }

        return {
            "name": parts[0],
            "country": parts.length > 3 ? parts[3] : "Custom",
            "lat": parsedLat,
            "lon": parsedLon
        };
    }

    function cityToConfigValue(city) {
        return city.name + "|" + city.lat + "|" + city.lon;
    }

    function parseCustomCities() {
        var parsedCities = [];
        var raw = Plasmoid.configuration.customCityList;
        if (!raw) {
            return parsedCities;
        }

        var entries = raw.split(";");
        for (var i = 0; i < entries.length; ++i) {
            var parsed = parseCityString(entries[i].trim());
            if (parsed) {
                parsedCities.push(parsed);
            }
        }
        return parsedCities;
    }

    function rebuildCityModel() {
        var combined = builtinCities.slice();
        var custom = parseCustomCities();
        for (var i = 0; i < custom.length; ++i) {
            combined.unshift(custom[i]);
        }

        var selected = parseCityString(Plasmoid.configuration.selectedCity);
        if (selected) {
            var exists = false;
            for (var j = 0; j < combined.length; ++j) {
                if (combined[j].name === selected.name
                        && combined[j].lat === selected.lat
                        && combined[j].lon === selected.lon) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                combined.unshift(selected);
            }
            selectedCityData = selected;
        }

        cities = combined;
    }

    function weatherCodeToText(code) {
        if (code === 0) return "Clear sky";
        if (code === 1 || code === 2) return "Partly cloudy";
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

    function formatTemp(celsius) {
        if (isNaN(celsius)) {
            return "--";
        }
        if (Plasmoid.configuration.temperatureUnit === "F") {
            return Math.round((celsius * 9 / 5) + 32) + "°F";
        }
        return Math.round(celsius) + "°C";
    }

    function formatWind(kmh) {
        if (isNaN(kmh)) {
            return "--";
        }

        var unit = Plasmoid.configuration.windSpeedUnit;
        if (unit === "mph") return (kmh * 0.621371).toFixed(1) + " mph";
        if (unit === "ms") return (kmh / 3.6).toFixed(1) + " m/s";
        if (unit === "kn") return (kmh * 0.539957).toFixed(1) + " kn";
        return Math.round(kmh) + " km/h";
    }

    function formatPressure(hpa) {
        if (isNaN(hpa)) {
            return "--";
        }

        var unit = Plasmoid.configuration.pressureUnit;
        if (unit === "mmHg") return (hpa * 0.750062).toFixed(0) + " mmHg";
        if (unit === "inHg") return (hpa * 0.02953).toFixed(2) + " inHg";
        return Math.round(hpa) + " hPa";
    }

    function formatTime(dateObj) {
        if (Plasmoid.configuration.timeFormat === "12h") {
            return Qt.formatTime(dateObj, "h:mm AP");
        }
        if (Plasmoid.configuration.timeFormat === "24h") {
            return Qt.formatTime(dateObj, "HH:mm");
        }
        return dateObj.toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
    }

    function refreshNow() {
        if (!selectedCityData) {
            return;
        }

        loading = true;
        var request = new XMLHttpRequest();
        var endpoint = "https://api.open-meteo.com/v1/forecast?latitude=" + selectedCityData.lat
            + "&longitude=" + selectedCityData.lon
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,surface_pressure"
            + "&daily=temperature_2m_max,temperature_2m_min"
            + "&timezone=auto";

        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE) {
                return;
            }

            loading = false;
            if (request.status !== 200) {
                updateText = "Unable to fetch weather";
                return;
            }

            var data = JSON.parse(request.responseText);
            if (!data.current) {
                updateText = "Weather data unavailable";
                return;
            }

            temperatureC = data.current.temperature_2m;
            apparentC = data.current.apparent_temperature;
            humidityPercent = data.current.relative_humidity_2m;
            weatherCode = data.current.weather_code;
            windKmh = data.current.wind_speed_10m;
            pressureHpa = data.current.surface_pressure;

            if (data.daily && data.daily.temperature_2m_max && data.daily.temperature_2m_min) {
                maxTempC = data.daily.temperature_2m_max[0];
                minTempC = data.daily.temperature_2m_min[0];
            }

            updateText = "Updated " + formatTime(new Date());
        };

        request.open("GET", endpoint);
        request.send();
    }

    function applySelectedCity(city) {
        if (!city) {
            return;
        }
        selectedCityData = city;
        Plasmoid.configuration.selectedCity = cityToConfigValue(city);
        refreshNow();
    }

    Component.onCompleted: {
        rebuildCityModel();
        refreshNow();
    }

    Connections {
        target: Plasmoid.configuration
        function onSelectedCityChanged() { rebuildCityModel(); refreshNow(); }
        function onCustomCityListChanged() { rebuildCityModel(); }
    }

    Timer {
        interval: Math.max(5, Plasmoid.configuration.refreshIntervalMinutes) * 60 * 1000
        running: Plasmoid.configuration.autoRefresh
        repeat: true
        onTriggered: refreshNow()
    }

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: Qt.rgba(0.14, 0.18, 0.29, 0.92)
        border.color: Qt.rgba(0.70, 0.78, 1.0, 0.25)


        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                ComboBox {
                    id: citySelector
                    Layout.fillWidth: true
                    model: cities
                    textRole: "name"

                    Component.onCompleted: {
                        for (var i = 0; i < cities.length; ++i) {
                            if (cities[i].name === selectedCityData.name
                                    && cities[i].lat === selectedCityData.lat
                                    && cities[i].lon === selectedCityData.lon) {
                                currentIndex = i;
                                break;
                            }
                        }
                    }

                    onActivated: function(index) {
                        applySelectedCity(cities[index]);
                    }
                }

                ToolButton {
                    text: "⟳"
                    onClicked: refreshNow()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Kirigami.Icon {
                    source: weatherCodeToIcon(weatherCode)
                    Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                    Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: formatTemp(temperatureC)
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 2.3
                        font.bold: true
                    }
                    Label {
                        text: weatherCodeToText(weatherCode)
                        opacity: 0.9
                    }
                    Label {
                        text: selectedCityData.name + " · " + selectedCityData.country
                        opacity: 0.75
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 16
                rowSpacing: 6

                Label {
                    visible: Plasmoid.configuration.showFeelsLike
                    text: "Feels like"
                    opacity: 0.8
                }
                Label {
                    visible: Plasmoid.configuration.showFeelsLike
                    text: formatTemp(apparentC)
                }

                Label {
                    visible: Plasmoid.configuration.showHumidity
                    text: "Humidity"
                    opacity: 0.8
                }
                Label {
                    visible: Plasmoid.configuration.showHumidity
                    text: isNaN(humidityPercent) ? "--" : Math.round(humidityPercent) + "%"
                }

                Label {
                    visible: Plasmoid.configuration.showWind
                    text: "Wind"
                    opacity: 0.8
                }
                Label {
                    visible: Plasmoid.configuration.showWind
                    text: formatWind(windKmh)
                }

                Label {
                    visible: Plasmoid.configuration.showPressure
                    text: "Pressure"
                    opacity: 0.8
                }
                Label {
                    visible: Plasmoid.configuration.showPressure
                    text: formatPressure(pressureHpa)
                }
            }

            Label {
                visible: Plasmoid.configuration.showDailyForecast
                Layout.fillWidth: true
                text: (isNaN(minTempC) || isNaN(maxTempC))
                    ? ""
                    : "Today: " + formatTemp(minTempC) + " / " + formatTemp(maxTempC)
                opacity: 0.9
            }

            Item { Layout.fillHeight: true }

            Label {
                Layout.fillWidth: true
                text: loading ? "Updating…" : updateText
                horizontalAlignment: Text.AlignRight
                opacity: 0.65
            }
        }
    }
}
