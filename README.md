# Plasma Weather City List Widget

KDE Plasma 6 weather widget inspired by:
- **CWP KDE4 plasmoid style** (classic boxed forecast layout), and
- **XFCE weather plugin settings model** (Location / Units / Appearance / Scrollbox).

## Major changes in this version

- Removed city selector from the widget surface.
- Location is now configured from Settings (like XFCE):
  - location name,
  - latitude,
  - longitude,
  - altitude,
  - timezone,
  - plus geocoding search from settings.
- Added XFCE-style settings tabs:
  - **Location**
  - **Units**
  - **Appearance**
  - **Scrollbox**
- Restyled widget to a CWP-like classic panel with:
  - top scrollbox lines,
  - left current conditions block,
  - right large temperature block,
  - multi-day forecast tiles.

## API

Uses Open-Meteo forecast + geocoding APIs (no API key required).

## Install / update

```bash
kpackagetool6 --type Plasma/Applet --remove org.example.plasma.weathercitylist || true
kpackagetool6 --type Plasma/Applet --install .
rm -rf ~/.cache/plasmashell/qmlcache
plasmashell --replace
```

## Troubleshooting

If Settings only shows generic pages (Keyboard Shortcuts/About) and not weather options, reinstall this version so `contents/config/config.qml` is picked up:

```bash
kpackagetool6 --type Plasma/Applet --remove org.example.plasma.weathercitylist || true
kpackagetool6 --type Plasma/Applet --install .
rm -rf ~/.cache/plasmashell/qmlcache
plasmashell --replace
```
