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
kpackagetool6 --type Plasma/Applet --install .
plasmashell --replace
```

Then add **City List Weather** from Plasma widgets.

## Notes

- Uses Open-Meteo's free API, no API key required.
- This is a starter port-style widget, not a full feature parity implementation of xfce4-weather-plugin yet.
