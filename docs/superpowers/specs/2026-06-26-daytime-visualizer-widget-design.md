# Daytime Visualizer Widget — Design

**Date:** 2026-06-26
**Status:** Approved (design)
**Target:** iOS medium home-screen widget (v1)

## Overview

A minimal, glanceable home-screen widget that renders the current day as a chart:
the sun's elevation arc and the hourly temperature curve over a full day, with
sunrise/sunset markers and a live "now" indicator. Visual language is monospace
type on a true-black background with an amber accent and a single pink now-line.

This is the first of a planned set of widgets that will eventually comprise a
minimal home screen. Subsequent widgets (personal-recorder data viz, minimal text
app launcher) get their own spec/build cycles.

## Visual Reference

Matches the provided reference image's chart card:

- True black (`#000000`) background, monospace font throughout, amber/orange accent
- X-axis = full day: `12a → 6a → 12p → 6p → 12a`
- Y-axis labeled by temperature range: max temp top (e.g. `77°`), min bottom (e.g. `60°`)
- Two overlaid curves:
  - **Smooth filled amber arc** = sun elevation (peaks at solar noon)
  - **Angular amber line** = hourly temperature (peaks/holds into afternoon)
- Dashed horizontal reference line at the current temperature
- Faint sunrise/sunset verticals with labels `↑ 5:48a` and `8:04p ↓`
- Single pink vertical "now" line with a dot on the temperature curve
- Footer: `Today · {city}`

## Scope (v1)

- **In:** medium widget, chart card only (sun-elevation arc, hourly temp curve,
  sunrise/sunset markers, now-line, min/max temp labels, city footer)
- **Out (later):** clock card, conditions card, large size, moon phase / astronomical
  extras, other widgets in the set

## Architecture

One Xcode project, two targets:

- **`DaytimeWidgets`** — minimal container app (host required by WidgetKit; carries
  entitlements and permission usage strings)
- **`DaytimeWidgetExtension`** — the widget extension

### Files

- `SolarMath.swift` — pure deterministic functions:
  - `sunElevation(date, lat, lon) -> Double`
  - `sunEvents(date, lat, lon) -> (sunrise: Date, sunset: Date)`
  - elevation sampler returning the day's elevation curve
  - No network; fully unit-testable.
- `LocationProvider.swift` — CoreLocation one-shot coordinates + reverse-geocoded
  city name.
- `WeatherService.swift` — WeatherKit fetch of today's hourly temperatures.
- `DayModel.swift` — plain struct the view renders:
  `date, city, hourlyTemps[], elevationSamples[], sunrise, sunset, tempMin, tempMax, now`
- `DayChartView.swift` — SwiftUI `Canvas` that draws the chart.
- `DaytimeWidget.swift` — `Widget` definition + `TimelineProvider`.

## Data Flow (per timeline reload)

1. `LocationProvider` → coordinates + city
2. `WeatherService` → today's hourly temperatures (angular curve + min/max)
3. `SolarMath` → sun-elevation curve + sunrise/sunset (smooth arc + markers)
4. Assemble one `DayModel` (curves are static for the day)
5. **Emit a timeline of entries every ~15 min from now → midnight**, each sharing
   the same curves but advancing `now`. One reload feeds many future frames, so the
   pink now-line advances across the chart without spending refresh budget.
6. Schedule next reload at the next day boundary, plus one midday reload to refresh
   the forecast.

## Rendering (`Canvas`)

- True black background, monospace font, amber accent, single pink now-line + dot
- Smooth filled amber arc = sun elevation, clamped at the horizon (night = flat baseline)
- Angular amber line = hourly temperature, scaled to `[tempMin, tempMax]` → the
  `60°` / `77°` y-labels
- Dashed horizontal reference line at the current temperature
- X-ticks `12a / 6a / 12p / 6p`, faint sunrise/sunset verticals with labels
- Pink now-line with dot sitting on the temperature curve
- Footer `Today · {city}`

## Edge Handling (minimal)

- No location permission → placeholder "Enable location"
- WeatherKit failure → still render the sun arc + markers (solar math needs no
  network); temperature curve, min/max labels, and reference line omitted
- Polar / all-night day → elevation clamps cleanly to the horizon baseline

## Testing

- `SolarMath` unit-tested against known Los Angeles sunrise/sunset for a fixed date
  (assert within ~1 minute). This is the only component with non-trivial logic.

## Dependencies / Setup

- Apple Developer Program (user has it) — required for WeatherKit entitlement
- WeatherKit capability enabled for the App ID
- Location usage permission ("when in use") for `LocationProvider`
