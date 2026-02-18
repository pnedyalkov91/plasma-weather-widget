# Plasma Weather Widget (CWP-style)

KDE Plasma 6 weather widget inspired by classic CWP visuals and XFCE weather settings.

## Highlights

- Resizable layout with forecast tiles that remain visible when the widget size changes.
- Transparent panel with configurable opacity.
- CWP-inspired structure with location title, optional scrollbox, current conditions, and forecast tiles.
- Settings pages are exposed as side categories:
  - Location
  - Units
  - Appearance
  - Scrollbox

## Location UI refactor

- The Location page now follows XFCE-style structure with a guidance panel and aligned fields.
- Added a **Change...** button that opens a dedicated **Search location** dialog.
- Search dialog lets you query cities and apply the selected result (name, coordinates, timezone, elevation).

## Install / update

```bash
kpackagetool6 --type Plasma/Applet --remove org.example.plasma.weathercitylist || true
kpackagetool6 --type Plasma/Applet --install .
rm -rf ~/.cache/plasmashell/qmlcache
plasmashell --replace
```

## Recent fixes

- Improved auto-detect reliability and UX: auto mode now updates timezone/elevation metadata and keeps form layout stable (no shifted fields).
- Implemented auto-detect mode updates: when enabled, coordinates are fetched from GeoClue2 (`QtPositioning`) and location name/timezone are reverse-geocoded automatically.
- Fixed Location page load error by replacing unsupported `leftPadding` usage with layout margins for Plasma/Qt compatibility.
- Added Location mode toggle: **Automatically detect location** vs **Use manual location**; manual controls and **Change...** are disabled/hidden in auto mode.
- Made the city search input field explicitly visible in dark themes.
- Added clear row highlight for selected city in search results.
- Disabled **OK** in the search dialog until a city is selected (Cancel remains available).
- Fixed city selection highlighting in the search results list.
- Restored dialog button order/icons (OK then Cancel) and made OK clearly enabled only after selection.
