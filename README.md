# Plasma Weather Widget (CWP-style)

KDE Plasma 6 weather widget inspired by classic CWP visuals and XFCE weather settings.

## Highlights

- Resizable layout with forecast tiles that remain visible when the widget size changes.
- Transparent panel with configurable opacity.
- CWP-inspired structure:
  - location title,
  - optional scrollbox,
  - left current-conditions panel,
  - right large temperature + details,
  - forecast day tiles.
- Settings pages are now exposed as **side tabs/categories** in Plasma config:
  - Location
  - Units
  - Appearance
  - Scrollbox

## Location selection

Location is selected from **Settings → Location**:
- search by city,
- or manually set location name + latitude + longitude + timezone.

## Install / update

```bash
kpackagetool6 --type Plasma/Applet --remove org.example.plasma.weathercitylist || true
kpackagetool6 --type Plasma/Applet --install .
rm -rf ~/.cache/plasmashell/qmlcache
plasmashell --replace
```
