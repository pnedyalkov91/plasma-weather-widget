import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property var cities: [
        { "name": "London", "country": "UK", "lat": 51.5072, "lon": -0.1276 },
        { "name": "Berlin", "country": "Germany", "lat": 52.52, "lon": 13.405 },
        { "name": "Paris", "country": "France", "lat": 48.8566, "lon": 2.3522 },
        { "name": "Rome", "country": "Italy", "lat": 41.9028, "lon": 12.4964 },
        { "name": "Tokyo", "country": "Japan", "lat": 35.6762, "lon": 139.6503 },
        { "name": "New York", "country": "USA", "lat": 40.7128, "lon": -74.006 }
    ]

    property var selectedCityData: ({ "name": "London", "country": "UK", "lat": 51.5072, "lon": -0.1276 })
    property string weatherText: "Loading…"
    property string temperatureText: "--°C"
    property string windText: "-- km/h"
    property string updateText: ""
    property bool loading: false

    function weatherCodeToText(code) {
        if (code === 0) return "Clear sky";
        if (code === 1 || code === 2) return "Partly cloudy";
        if (code === 3) return "Overcast";
        if (code === 45 || code === 48) return "Fog";
        if (code === 51 || code === 53 || code === 55) return "Drizzle";
        if (code === 61 || code === 63 || code === 65) return "Rain";
        if (code === 71 || code === 73 || code === 75) return "Snow";
        if (code === 80 || code === 81 || code === 82) return "Rain showers";
        if (code === 95 || code === 96 || code === 99) return "Thunderstorm";
        return "Unknown conditions";
    }

    function parseCityString(cityString) {
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
            "country": "Custom",
            "lat": parsedLat,
            "lon": parsedLon
        };
    }

    function cityToConfigValue(city) {
        return city.name + "|" + city.lat + "|" + city.lon;
    }

    function fetchWeather() {
        if (!selectedCityData) {
            return;
        }

        loading = true;
        var request = new XMLHttpRequest();
        var endpoint = "https://api.open-meteo.com/v1/forecast?latitude="
            + selectedCityData.lat
            + "&longitude="
            + selectedCityData.lon
            + "&current=temperature_2m,weather_code,wind_speed_10m"
            + "&timezone=auto";

        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE) {
                return;
            }

            loading = false;
            if (request.status !== 200) {
                weatherText = "Unable to fetch weather";
                return;
            }

            var data = JSON.parse(request.responseText);
            if (!data.current) {
                weatherText = "No weather data";
                return;
            }

            temperatureText = Math.round(data.current.temperature_2m) + "°C";
            windText = Math.round(data.current.wind_speed_10m) + " km/h";
            weatherText = weatherCodeToText(data.current.weather_code);
            updateText = "Updated " + new Date().toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
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
        fetchWeather();
    }

    function initializeSelectedCity() {
        var parsed = parseCityString(Plasmoid.configuration.selectedCity);
        if (parsed) {
            selectedCityData = parsed;

            var exists = false;
            for (var i = 0; i < cities.length; ++i) {
                if (cities[i].name === parsed.name
                        && cities[i].lat === parsed.lat
                        && cities[i].lon === parsed.lon) {
                    exists = true;
                    break;
                }
            }

            if (!exists) {
                var customCities = cities.slice();
                customCities.unshift(parsed);
                cities = customCities;
            }
        }
        fetchWeather();
    }

    Component.onCompleted: initializeSelectedCity()

    Timer {
        interval: Math.max(5, Plasmoid.configuration.refreshIntervalMinutes) * 60 * 1000
        running: true
        repeat: true
        onTriggered: fetchWeather()
    }

    Plasmoid.compactRepresentation: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: "weather-clear"
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
        }

        Label {
            text: loading ? "…" : temperatureText
            font.bold: true
        }
    }

    Plasmoid.fullRepresentation: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

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

        Label {
            text: selectedCityData.name + " · " + selectedCityData.country
            font.bold: true
            Layout.fillWidth: true
        }

        Label {
            text: temperatureText
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 2
            Layout.fillWidth: true
        }

        Label {
            text: weatherText
            Layout.fillWidth: true
        }

        Label {
            text: "Wind: " + windText
            Layout.fillWidth: true
        }

        Label {
            text: updateText
            opacity: 0.7
            Layout.fillWidth: true
        }

        Button {
            text: "Refresh now"
            onClicked: fetchWeather()
        }
    }
}
