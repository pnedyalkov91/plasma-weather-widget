# Plasma Weather City List Widget

A KDE Plasma widget inspired by the XFCE weather plugin workflow, with a simple city selector and live weather from [Open-Meteo](https://open-meteo.com/).

## Features

- Predefined city list with quick switching.
- Configurable custom city (Name|Latitude|Longitude format).
- Current temperature, weather condition, and wind speed.
- Automatic refresh interval (configurable).

## Install locally

From this repository root:

```bash
# 1) Remove old installed copy (if present)
kpackagetool6 --type Plasma/Applet --remove org.example.plasma.weathercitylist || true

# 2) Install this version
kpackagetool6 --type Plasma/Applet --install .

# 3) Optional: clear compiled QML cache if Plasma keeps stale code
rm -rf ~/.cache/plasmashell/qmlcache

# 4) Restart shell
plasmashell --replace
```

Then add **City List Weather** from Plasma widgets.

## Notes

- Uses Open-Meteo's free API, no API key required.
- This is a starter port-style widget, not a full feature parity implementation of xfce4-weather-plugin yet.
- If you still see an error mentioning `fullRepresentation`, your system is loading an older installed copy, not this repository's `contents/ui/main.qml`.
