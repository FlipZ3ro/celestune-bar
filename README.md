# Celestune Bar for Omarchy

A unified Omarchy bar widget containing a calendar, weather summary and
forecast, and MPRIS media controls. Celestune Bar is built natively for
Omarchy and uses Omarchy's existing weather and media facilities.

![Celestune preview](preview.png)

## Features

- Current weather and a three-day forecast.
- Monthly calendar with today highlighting.
- MPRIS album art, track details, playback controls, seek, and volume.
- Compact bar label combining time, weather, and the active track.
- Theme-aware styling using Omarchy Shell colors and spacing.

## Requirements

- Omarchy Shell with its built-in weather and media services.
- An MPRIS-compatible player for media information and controls.

Celestune Bar requires no additional system packages or privileged access.

## Installation

```bash
omarchy plugin add https://github.com/FlipZ3ro/celestune-bar.git --enable
```

Celestune Bar is placed in the center section by default. You can reposition
it through Omarchy's bar configuration.

### Recommended Setup

To use Celestune Bar as your primary clock and prevent duplicate clock displays:

```bash
omarchy plugin disable omarchy.clock
```

To pin Celestune Bar to the exact physical center of the status bar (preventing it from shifting when neighboring widgets such as indicators expand on hover), set `centerAnchor` in `~/.config/omarchy/shell.json`:

```json
"bar": {
  "centerAnchor": "celestune-bar"
}
```

## Controls

- Left click: open or close the dashboard.
- Middle click: play or pause media.
- Right click: cycle clock format (persists selection to `shell.json`).
- Scroll: previous or next track.

## Removal

```bash
omarchy plugin remove celestune-bar
```

## License

Celestune Bar is licensed under the GNU General Public License v3.0 only.
