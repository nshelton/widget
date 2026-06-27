# Star Chart: ecliptic, Sun, and Moon

Date: 2026-06-27

## Goal

Draw three new elements on the star chart:

1. The **ecliptic** — the Sun's annual path across the sky, as a line.
2. The **Sun** — its current position, as a glowing disc (visible only in daytime charts).
3. The **Moon** — its current position, drawn as a **phase-lit disc**.

All three are culled below the horizon exactly like the stars (the stereographic
projection already returns `nil` for `altitude < 0`). The Sun therefore appears only when
it is up; the ecliptic and Moon show only their above-horizon arcs. This is correct, not a
bug.

## Architecture

Position math is pure and lives in `CelestialMath` (app target, `SheltronWidgets/`),
beside the existing `equatorialToHorizontal` / `stereographicProject`. The renderer
consumes it. Colors come from `StarChartTheme` (App Group), consistent with the existing
slots.

### 1. `CelestialMath` — new pure functions

All angles in degrees unless noted; RA returned in hours to match `equatorialToHorizontal`.

- `eclipticToEquatorial(lon, lat, date) -> (ra, dec)`
  Mean obliquity ε for the date. Standard transform:
  `dec = asin(sinβ·cosε + cosβ·sinε·sinλ)`,
  `ra  = atan2(sinλ·cosε − tanβ·sinε, cosλ)` (normalized to 0–24h).
  This is the primitive the Sun and Moon both use.

- `sunEclipticLongitude(date) -> Double`
  Low-precision solar series (Meeus ch. 25):
  `L = 280.460 + 0.9856474·n`, `g = 357.528 + 0.9856003·n` (n = JD − 2451545.0),
  `λ = L + 1.915·sin g + 0.020·sin 2g`. Latitude β ≈ 0.
  `sunEquatorial(date)` wraps it via `eclipticToEquatorial(λ, 0, date)`.

- `moonEquatorial(date) -> (ra, dec)`
  Low-precision lunar position (longitude/latitude from the main periodic terms; a few
  arc-minutes), then `eclipticToEquatorial`.

- `moonIllumination(date) -> (fraction, waxing)`
  `fraction` = illuminated fraction in [0,1] from the Sun–Moon elongation;
  `waxing` = Bool for which limb is lit (drives the terminator side).

### 2. `StarChartTheme` — three new slots

Add `ecliptic`, `sun`, `moon` (`RGBAColor`) with defaults: dim amber ecliptic, warm Sun,
pale grey-white Moon.

Because the struct already persists to the App Group, add a **tolerant `init(from:)`**
that does `decodeIfPresent(...) ?? <default>` for every field. Old saved JSON (without the
new keys) decodes and keeps its existing colors instead of being discarded by
`load()`'s `try?` fallback. Encoding stays synthesized.

### 3. `StarChartRenderer` — draw order

`background → grid → ecliptic → constellations → stars → Sun → Moon → cardinal labels →
info text → debug timestamp`.

- **Ecliptic:** sample λ = 0…360° (≈2° step) at β = 0, project each point, stroke a
  polyline in `theme.ecliptic`; break the path wherever a point is below the horizon
  (projection returns `nil`).
- **Sun:** project `sunEquatorial`; if visible, a filled disc with a radial glow in
  `theme.sun`, plus a "Sun" label.
- **Moon:** project `moonEquatorial`; if visible, a disc shaded to its phase — dark base
  in a dimmed `theme.moon`, lit region bounded by the terminator ellipse (semi-axis from
  `fraction`, side from `waxing`) filled in `theme.moon`, plus a "Moon" label.

### 4. Editor

Three more `ColorPicker` rows in `StarChartSettingsView`: Ecliptic, Sun, Moon.

## Tests (TDD)

- `eclipticToEquatorial`: λ=0 → (RA 0h, Dec 0°); λ=90 → (RA 6h, Dec +23.44°);
  λ=180 → (RA 12h, Dec 0°). Tolerances ~0.01h / 0.05°.
- `sunEclipticLongitude`: at J2000 (JD 2451545.0) ≈ 280.4° (±0.5°).
- Moon: `moonIllumination().fraction` is always in [0,1]; ≈0 near a known new moon
  (loose tolerance, given low precision).
- Extend the `StarChartTheme` round-trip test to the three new slots; add a decode test
  proving old JSON (missing the new keys) keeps its other colors.

## Out of scope (YAGNI)

- No planets, no precession of star positions, no atmospheric refraction (consistent with
  the existing geometric-horizon choice).
