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
