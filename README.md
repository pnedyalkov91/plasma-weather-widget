# Plasma Weather City List Widget

A KDE Plasma 6 widget inspired by xfce4-weather-plugin, redesigned with a modern weather card look and richer settings.

## What is implemented

- City selector with built-in cities + custom cities.
- Styled weather card UI inspired by modern weather widgets.
- Current conditions from Open-Meteo:
  - temperature,
  - feels-like,
  - humidity,
  - wind,
  - pressure,
  - weather condition code/icon,
  - today's min/max summary.
- XFCE-like settings categories (Location, Layout, Units, Refresh).

## Settings now available

- **Location**
  - primary city (`Name|Latitude|Longitude`),
  - extra custom cities (semicolon-separated list).
- **Layout**
  - show/hide feels-like, humidity, wind, pressure, daily min/max.
- **Units**
  - temperature (°C/°F),
  - wind (km/h, mph, m/s, kn),
  - pressure (hPa, mmHg, inHg),
  - clock format (system/12h/24h).
- **Refresh**
  - auto-refresh toggle,
  - interval in minutes.

## Install / update locally

```bash
kpackagetool6 --type Plasma/Applet --remove org.example.plasma.weathercitylist || true
kpackagetool6 --type Plasma/Applet --install .
rm -rf ~/.cache/plasmashell/qmlcache
plasmashell --replace
```

Then add **City List Weather** from Plasma widgets.

## Notes

- Data source: Open-Meteo API (no API key required).
- This is a practical port-style implementation inspired by XFCE behavior and options.
