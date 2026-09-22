# Celestune Bar for Omarchy

A unified Omarchy bar widget containing a calendar, weather summary and
forecast, and MPRIS media controls. Celestune Bar is built natively for
Omarchy: weather uses Omarchy's weather panel, while media is read directly
from Quickshell's MPRIS service.

![Celestune preview](preview.png)

## Features

- Current weather and a three-day forecast.
- Device location through GeoClue with accuracy checks and manual-city fallback.
- Monthly calendar with today highlighting.
- MPRIS album art, track details, playback controls, seek, and volume.
- Compact bar label combining time, weather, and the active track.
- Theme-aware styling using Omarchy Shell colors and spacing.

## Requirements

- Omarchy Shell with its built-in weather panel.
- GeoClue for device-location Auto mode (`omarchy pkg add geoclue`).
- An MPRIS-compatible player for media information and controls.

Manual weather locations work without GeoClue. Celestune Bar requires no
privileged access while running.

## Installation

```bash
omarchy plugin add https://github.com/FlipZ3ro/celestune-bar.git --enable
```

Celestune Bar is placed in the center section by default. You can reposition
it through Omarchy's bar configuration.

### Recommended setup

Disable Omarchy's default clock to avoid showing two clocks:

```bash
omarchy plugin disable omarchy.clock
```

To keep Celestune Bar pinned to the physical center when nearby widgets
change width, set `centerAnchor` in `~/.config/omarchy/shell.json`:

```json
"bar": {
  "centerAnchor": "celestune-bar"
}
```

## Controls

- Left click: open or close the dashboard.
- Click the weather location or map marker: edit the city directly in the
  dashboard. Use `AUTO` for GeoClue device-location detection; inaccurate IP
  fallbacks are rejected so they cannot replace a correct manual city.
- Middle click: play or pause media.
- Right click: cycle the clock format and save the selection.
- Scroll: previous or next track.

Weather can still be refreshed with the refresh button inside the dashboard.

## Removal

```bash
omarchy plugin remove celestune-bar
```

## Contributors

- [Pierorivera1](https://github.com/Pierorivera1) — persistent clock formats and setup documentation.
- [VideoPants](https://github.com/VideoPants) — direct MPRIS support for Omarchy 4.

## License

Celestune Bar is licensed under the GNU General Public License v3.0 only.
