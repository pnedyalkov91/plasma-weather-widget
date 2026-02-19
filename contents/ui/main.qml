import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    implicitWidth: 520
    implicitHeight: 280
    switchWidth: 520
    switchHeight: 280

    property bool loading: false
    property real temperatureC: NaN
    property real apparentC: NaN
    property real windKmh: NaN
    property real pressureHpa: NaN
    property real humidityPercent: NaN
    property real visibilityKm: NaN
    property real dewPointC: NaN
    property string sunriseTimeText: "--"
    property string sunsetTimeText: "--"
    property int weatherCode: -1
    property var dailyData: []
    property int scrollIndex: 0
    property int panelScrollIndex: 0
    property string updateText: ""
    readonly property bool hasSelectedTown: (Plasmoid.configuration.locationName || "").trim().length > 0
    readonly property string bundledOpenWeatherApiKey: "8003225e8825db83758c237068447229"
    readonly property string bundledWeatherApiKey: "601ba4ac57404ec29ff120510261802"

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    function openLocationSettings() {
        var action = Plasmoid.internalAction("configure");
        if (action) {
            action.trigger();
        }
    }

    function openPopupFromPanel() {
        if (!root.expanded) {
            root.expanded = true;
        }
    }

    compactRepresentation: Item {
        implicitWidth: 320
        implicitHeight: Math.max(22, Kirigami.Units.gridUnit + 4)

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: root.openPopupFromPanel()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 6

            Kirigami.Icon {
                visible: !hasSelectedTown || Plasmoid.configuration.panelShowWeatherIcon
                source: weatherCodeToIcon(weatherCode)
                Layout.preferredWidth: Math.max(14, parent.height - 6)
                Layout.preferredHeight: Math.max(14, parent.height - 6)
            }

            Label {
                Layout.fillWidth: true
                elide: Text.ElideRight
                color: Kirigami.Theme.textColor
                text: {
                    if (!hasSelectedTown) {
                        return "";
                    }
                    var city = (Plasmoid.configuration.locationName || "").split(",")[0].trim();
                    var info = root.panelLineText();
                    return city + (info.length > 0 ? ", " + info : "");
                }
            }
        }

    }

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
        if (code < 0) return "weather-none-available";
        if (code === 0) return "weather-clear";
        if (code === 1 || code === 2) return "weather-few-clouds";
        if (code === 3) return "weather-overcast";
        if (code === 45 || code === 48) return "weather-fog";
        if (code === 61 || code === 63 || code === 65) return "weather-showers";
        if (code === 71 || code === 73 || code === 75) return "weather-snow";
        if (code === 95 || code === 96 || code === 99) return "weather-storm";
        return "weather-few-clouds";
    }

    function openWeatherCodeToWmo(code) {
        if (code >= 200 && code < 300) return 95;
        if (code >= 300 && code < 600) return 63;
        if (code >= 600 && code < 700) return 73;
        if (code >= 700 && code < 800) return 45;
        if (code === 800) return 0;
        if (code === 801 || code === 802) return 2;
        if (code === 803 || code === 804) return 3;
        return 2;
    }

    function metNoSymbolToWmo(symbolCode) {
        if (!symbolCode) return 2;
        if (symbolCode.indexOf("thunder") >= 0) return 95;
        if (symbolCode.indexOf("snow") >= 0 || symbolCode.indexOf("sleet") >= 0) return 73;
        if (symbolCode.indexOf("rain") >= 0 || symbolCode.indexOf("drizzle") >= 0) return 63;
        if (symbolCode.indexOf("fog") >= 0) return 45;
        if (symbolCode.indexOf("clearsky") >= 0) return 0;
        if (symbolCode.indexOf("cloudy") >= 0) return 3;
        return 2;
    }

    function weatherApiCodeToWmo(code) {
        if (code >= 1273) return 95;
        if (code >= 1114 && code <= 1237) return 73;
        if ((code >= 1063 && code <= 1201) || (code >= 1240 && code <= 1246)) return 63;
        if (code === 1000) return 0;
        if (code === 1003) return 2;
        if (code === 1006 || code === 1009) return 3;
        if (code === 1030 || code === 1135 || code === 1147) return 45;
        return 2;
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

    function formatUnixClock(seconds) {
        if (!seconds || isNaN(seconds)) return "--";
        return Qt.formatTime(new Date(seconds * 1000), "HH:mm");
    }

    function panelInfoItems() {
        var items = [];
        if (Plasmoid.configuration.panelShowTemperature) items.push("Temp " + tempValue(temperatureC));
        if (Plasmoid.configuration.panelShowSunTimes) items.push("☀ " + sunriseTimeText + " / " + sunsetTimeText);
        if (Plasmoid.configuration.panelShowWind) items.push("Wind " + windValue(windKmh));
        if (Plasmoid.configuration.panelShowFeelsLike) items.push("Feels " + tempValue(apparentC));
        if (Plasmoid.configuration.panelShowHumidity) items.push("Humidity " + (isNaN(humidityPercent) ? "--" : Math.round(humidityPercent) + "%"));
        if (Plasmoid.configuration.panelShowPressure) items.push("Pressure " + pressureValue(pressureHpa));
        return items;
    }

    function panelLineText() {
        var items = panelInfoItems();
        if (items.length === 0) {
            return "";
        }
        if (Plasmoid.configuration.panelInfoMode === "single") {
            return items.join(" • ");
        }
        var index = panelScrollIndex % items.length;
        return items[index];
    }

    function refreshNow() {
        if (!hasSelectedTown) {
            loading = false;
            updateText = "";
            temperatureC = NaN;
            apparentC = NaN;
            windKmh = NaN;
            pressureHpa = NaN;
            humidityPercent = NaN;
            visibilityKm = NaN;
            dewPointC = NaN;
            sunriseTimeText = "--";
            sunsetTimeText = "--";
            weatherCode = -1;
            dailyData = [];
            return;
        }

        loading = true;

        var selectedProvider = Plasmoid.configuration.weatherProvider || "adaptive";
        var providerChain = [];
        if (selectedProvider === "adaptive") {
            providerChain = ["openMeteo", "openWeather", "weatherApi", "metno"];
        } else {
            providerChain = [selectedProvider];
        }

        function tryProvider(index) {
            if (index >= providerChain.length) {
                loading = false;
                updateText = "All providers failed";
                return;
            }

            var provider = providerChain[index];

            if (provider === "openWeather") {
                var owReq = new XMLHttpRequest();
                var owEndpoint = "https://api.openweathermap.org/data/2.5/weather?lat=" + Plasmoid.configuration.latitude
                    + "&lon=" + Plasmoid.configuration.longitude
                    + "&units=metric&appid=" + encodeURIComponent(bundledOpenWeatherApiKey);

                owReq.onreadystatechange = function() {
                    if (owReq.readyState !== XMLHttpRequest.DONE) return;
                    if (owReq.status !== 200) {
                        tryProvider(index + 1);
                        return;
                    }

                    var data = JSON.parse(owReq.responseText);
                    if (!data.main) {
                        tryProvider(index + 1);
                        return;
                    }

                    temperatureC = data.main.temp;
                    apparentC = data.main.feels_like;
                    humidityPercent = data.main.humidity;
                    pressureHpa = data.main.pressure;
                    windKmh = data.wind && data.wind.speed !== undefined ? data.wind.speed * 3.6 : NaN;
                    dewPointC = NaN;
                    visibilityKm = data.visibility !== undefined ? (data.visibility / 1000.0) : NaN;
                    weatherCode = (data.weather && data.weather.length > 0) ? openWeatherCodeToWmo(data.weather[0].id) : 2;
                    sunriseTimeText = data.sys && data.sys.sunrise ? formatUnixClock(data.sys.sunrise) : "--";
                    sunsetTimeText = data.sys && data.sys.sunset ? formatUnixClock(data.sys.sunset) : "--";
                    dailyData = [];
                    loading = false;
                    updateText = "Updated " + Qt.formatTime(new Date(), "HH:mm") + " (OpenWeather)";
                };

                owReq.open("GET", owEndpoint);
                owReq.send();
                return;
            }

            if (provider === "weatherApi") {
                var waReq = new XMLHttpRequest();
                var waEndpoint = "https://api.weatherapi.com/v1/forecast.json?key=" + encodeURIComponent(bundledWeatherApiKey)
                    + "&q=" + encodeURIComponent(Plasmoid.configuration.latitude + "," + Plasmoid.configuration.longitude)
                    + "&days=" + Math.max(3, Plasmoid.configuration.forecastDays)
                    + "&aqi=no&alerts=no";

                waReq.onreadystatechange = function() {
                    if (waReq.readyState !== XMLHttpRequest.DONE) return;
                    if (waReq.status !== 200) {
                        tryProvider(index + 1);
                        return;
                    }

                    var data = JSON.parse(waReq.responseText);
                    if (!data.current) {
                        tryProvider(index + 1);
                        return;
                    }

                    temperatureC = data.current.temp_c;
                    apparentC = data.current.feelslike_c;
                    humidityPercent = data.current.humidity;
                    pressureHpa = data.current.pressure_mb;
                    windKmh = data.current.wind_kph;
                    dewPointC = NaN;
                    visibilityKm = data.current.vis_km;
                    weatherCode = data.current.condition ? weatherApiCodeToWmo(data.current.condition.code) : 2;
                    if (data.forecast && data.forecast.forecastday && data.forecast.forecastday.length > 0) {
                        sunriseTimeText = data.forecast.forecastday[0].astro && data.forecast.forecastday[0].astro.sunrise
                            ? data.forecast.forecastday[0].astro.sunrise : "--";
                        sunsetTimeText = data.forecast.forecastday[0].astro && data.forecast.forecastday[0].astro.sunset
                            ? data.forecast.forecastday[0].astro.sunset : "--";
                    } else {
                        sunriseTimeText = "--";
                        sunsetTimeText = "--";
                    }

                    dailyData = [];
                    if (data.forecast && data.forecast.forecastday) {
                        var maxDays = Math.min(Plasmoid.configuration.forecastDays, data.forecast.forecastday.length);
                        for (var i = 0; i < maxDays; ++i) {
                            var f = data.forecast.forecastday[i];
                            dailyData.push({
                                day: Qt.formatDate(new Date(f.date), "ddd"),
                                maxC: f.day.maxtemp_c,
                                minC: f.day.mintemp_c,
                                code: weatherApiCodeToWmo(f.day.condition.code)
                            });
                        }
                    }

                    loading = false;
                    updateText = "Updated " + Qt.formatTime(new Date(), "HH:mm") + " (WeatherAPI.com)";
                };

                waReq.open("GET", waEndpoint);
                waReq.send();
                return;
            }

            if (provider === "metno") {
                var metReq = new XMLHttpRequest();
                var metEndpoint = "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat="
                    + encodeURIComponent(Plasmoid.configuration.latitude)
                    + "&lon="
                    + encodeURIComponent(Plasmoid.configuration.longitude);

                metReq.onreadystatechange = function() {
                    if (metReq.readyState !== XMLHttpRequest.DONE) return;
                    if (metReq.status !== 200) {
                        tryProvider(index + 1);
                        return;
                    }

                    var data = JSON.parse(metReq.responseText);
                    if (!data.properties || !data.properties.timeseries || data.properties.timeseries.length === 0) {
                        tryProvider(index + 1);
                        return;
                    }

                    var ts = data.properties.timeseries[0];
                    var details = ts.data && ts.data.instant ? ts.data.instant.details : null;
                    if (!details) {
                        tryProvider(index + 1);
                        return;
                    }

                    temperatureC = details.air_temperature;
                    apparentC = details.air_temperature;
                    humidityPercent = details.relative_humidity;
                    pressureHpa = details.air_pressure_at_sea_level;
                    windKmh = details.wind_speed !== undefined ? details.wind_speed * 3.6 : NaN;
                    dewPointC = details.dew_point_temperature;
                    visibilityKm = NaN;

                    var symbol = ts.data && ts.data.next_1_hours && ts.data.next_1_hours.summary
                        ? ts.data.next_1_hours.summary.symbol_code
                        : "";
                    weatherCode = metNoSymbolToWmo(symbol);
                    sunriseTimeText = "--";
                    sunsetTimeText = "--";
                    dailyData = [];
                    loading = false;
                    updateText = "Updated " + Qt.formatTime(new Date(), "HH:mm") + " (met.no)";
                };

                metReq.open("GET", metEndpoint);
                metReq.send();
                return;
            }

            var request = new XMLHttpRequest();
            var timezoneValue = (Plasmoid.configuration.timezone || "").trim();
            var endpoint = "https://api.open-meteo.com/v1/forecast?latitude=" + Plasmoid.configuration.latitude
                + "&longitude=" + Plasmoid.configuration.longitude
                + "&timezone=" + encodeURIComponent(timezoneValue.length > 0 ? timezoneValue : "auto")
                + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,surface_pressure,dew_point_2m,visibility"
                + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset";

            request.onreadystatechange = function() {
                if (request.readyState !== XMLHttpRequest.DONE) return;
                if (request.status !== 200) {
                    tryProvider(index + 1);
                    return;
                }

                var data = JSON.parse(request.responseText);
                if (!data.current) {
                    tryProvider(index + 1);
                    return;
                }

                temperatureC = data.current.temperature_2m;
                apparentC = data.current.apparent_temperature;
                humidityPercent = data.current.relative_humidity_2m;
                windKmh = data.current.wind_speed_10m;
                pressureHpa = data.current.surface_pressure;
                dewPointC = data.current.dew_point_2m;
                visibilityKm = data.current.visibility / 1000.0;
                weatherCode = data.current.weather_code;
                sunriseTimeText = data.daily && data.daily.sunrise && data.daily.sunrise.length > 0
                    ? Qt.formatTime(new Date(data.daily.sunrise[0]), "HH:mm") : "--";
                sunsetTimeText = data.daily && data.daily.sunset && data.daily.sunset.length > 0
                    ? Qt.formatTime(new Date(data.daily.sunset[0]), "HH:mm") : "--";

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
                loading = false;
                updateText = "Updated " + Qt.formatTime(new Date(), "HH:mm") + " (Open-Meteo)";
            };

            request.open("GET", endpoint);
            request.send();
        }

        tryProvider(0);
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
        function onLocationNameChanged() { refreshNow(); }
        function onLatitudeChanged() { refreshNow(); }
        function onLongitudeChanged() { refreshNow(); }
        function onTimezoneChanged() { refreshNow(); }
        function onWeatherProviderChanged() { refreshNow(); }
        function onForecastDaysChanged() { refreshNow(); }
    }

    Timer {
        interval: Math.max(5, Plasmoid.configuration.refreshIntervalMinutes) * 60 * 1000
        running: Plasmoid.configuration.autoRefresh
        repeat: true
        onTriggered: refreshNow()
    }

    Timer {
        interval: Math.max(1, Plasmoid.configuration.panelScrollSeconds) * 1000
        running: Plasmoid.configuration.panelInfoMode === "scroll"
        repeat: true
        onTriggered: {
            panelScrollIndex += 1;
        }
    }

    Timer {
        interval: 3000
        running: Plasmoid.configuration.showScrollbox && Plasmoid.configuration.animateTransitions
        repeat: true
        onTriggered: {
            var lines = scrollLines();
            if (lines.length > 0) {
                scrollIndex = (scrollIndex + 1) % lines.length;
            }
        }
    }

    fullRepresentation: Rectangle {
        implicitWidth: 520
        implicitHeight: 280
        anchors.fill: parent
        radius: 4
        color: Plasmoid.configuration.transparentBackground
            ? "transparent"
            : Qt.rgba(0.22, 0.16, 0.10, Math.max(0.0, Math.min(1, Plasmoid.configuration.panelOpacityPercent / 100)))
        border.color: Plasmoid.configuration.transparentBackground ? "transparent" : Qt.rgba(0.80, 0.72, 0.58, 0.9)
        border.width: Plasmoid.configuration.transparentBackground ? 0 : 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 6

            Label {
                Layout.fillWidth: true
                text: hasSelectedTown ? Plasmoid.configuration.locationName : ""
                horizontalAlignment: Text.AlignHCenter
                color: "white"
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, 320)
                    spacing: 10
                    visible: !hasSelectedTown

                    Kirigami.Icon {
                        Layout.alignment: Qt.AlignHCenter
                        source: "mark-location"
                        width: 80
                        height: 80
                        color: "white"
                    }

                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        color: "white"
                        font.bold: true
                        text: "Please set your location"
                    }

                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Set Location..."
                        icon.name: "settings-configure"
                        onClicked: root.openLocationSettings()
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 6
                    visible: hasSelectedTown

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
    }
}
