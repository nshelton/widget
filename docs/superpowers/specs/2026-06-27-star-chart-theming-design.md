# Star Chart: theming, manual wallpaper trigger, debug timestamp

Date: 2026-06-27

## Goal

Three additions to the existing star-chart wallpaper feature:

1. A **custom, editable color theme** for the star chart (separate from the Today widget's palette).
2. An **in-app trigger** that sets the lock-screen wallpaper (within iOS limits).
3. A **debug timestamp** overlay showing when the image was generated.

## Constraint: setting the wallpaper

iOS has **no public API** for an app or App Intent to set the wallpaper. The only
programmatic path is the Shortcuts **"Set Wallpaper"** action. Therefore the in-app
"trigger" cannot set the wallpaper itself — it deep-links to a user-created Shortcut
(`shortcuts://run-shortcut?name=…`) that runs `GenerateStarChartIntent` and then
`Set Wallpaper`. The app only *triggers* that Shortcut.

## Architecture

The App Group `group.sheltron.SheltronWidgets` remains the single source of truth and
the only app↔intent channel, consistent with the existing widget theming. The renderer
stays a pure function; callers load state and pass it in.

### 1. `StarChartTheme` — new file `SheltronWidgets/StarChartTheme.swift`

Reuses the existing shared `RGBAColor` (defined in `WidgetTheme.swift`, already compiled
into the app target). Five purpose-built color slots plus the debug flag, persisted as JSON
in the App Group under key `"starChartTheme"`.

```swift
struct StarChartTheme: Codable, Equatable {
    var background    = RGBAColor(0.03, 0.03, 0.10, 1)  // gradient base
    var stars         = RGBAColor(0.95, 0.95, 1.0, 1)   // dot + glow
    var constellation = RGBAColor(1, 1, 1, 0.12)        // constellation lines
    var grid          = RGBAColor(1, 1, 1, 0.12)        // altitude circles + horizon
    var text          = RGBAColor(1, 1, 1, 0.5)         // labels + info text
    var showDebugTimestamp = false

    static let key = "starChartTheme"
    static func load() -> StarChartTheme   // App Group suite; default if absent
    func save()                            // App Group suite
}
```

Defaults are seeded from the current hard-coded colors. One struct, one key, one
load/save — the debug flag rides along rather than getting its own key.

File lives in `SheltronWidgets/` (app target only; the widget extension does not render
the star chart). No `project.pbxproj` membership changes needed because `RGBAColor` is
already shared into the app target.

### 2. `StarChartRenderer` — edit

`render(...)` gains `theme: StarChartTheme = .load()`. All hard-coded `UIColor`s are
replaced by theme slots:

- **background gradient** derived from `theme.background` (base + a slightly lightened
  mid stop + the base again at the bottom, preserving the current subtle look).
- **altitude circles + horizon** from `theme.grid` (inner circles at a fraction of its
  alpha, horizon at full).
- **constellation lines** from `theme.constellation`.
- **star dots + glow** from `theme.stars`; per-magnitude alpha scaling is preserved.
- **cardinal labels + info text** from `theme.text`.

When `theme.showDebugTimestamp` is true, draw the generation time **large, horizontally
centered, in the lower-middle** of the image (≈ `size.height * 0.66`, ≈ 96 pt) formatted
`HH:mm:ss`, so a fresh render is obvious at a glance.

### 3. `GenerateStarChartIntent` — edit

`perform()` calls `StarChartTheme.load()` and passes it into the renderer. Shortcut and
automation runs therefore honor the saved palette and debug flag automatically.

### 4. App UI

- **`StarChartSection` (edit):**
  - a **debug timestamp `Toggle`** bound to the saved theme's `showDebugTimestamp`.
  - a **"Set Wallpaper Now"** button that opens `shortcuts://run-shortcut?name=<name>`.
  - a small editable **shortcut-name field** (`@AppStorage("wallpaperShortcutName")`,
    default `"Star Chart Wallpaper"`) so the button matches the user's Shortcut name.
  - a button to open the new color editor sheet.
  - editing theme or toggling debug re-renders the in-app preview.

- **`StarChartSettingsView` (new file `SheltronWidgets/StarChartSettingsView.swift`):**
  a sheet with five `ColorPicker` rows editing the `StarChartTheme`, mirroring the
  existing `SettingsView` pattern. Saving writes to the App Group.

- **`AutoUpdateSetupView` (edit):** update the steps to instruct the user to **name** the
  Shortcut to match the field, and mention the in-app "Set Wallpaper Now" button.

## Data flow

```
App editor / toggle ──save()──▶ App Group ("starChartTheme")
                                   │
        ┌──────────────────────────┼───────────────────────────┐
        ▼                          ▼                            ▼
StarChartSection preview   GenerateStarChartIntent      (Shortcut runs intent)
  render(theme)              render(theme: .load())        → Set Wallpaper
```

The app's "Set Wallpaper Now" button only triggers the named Shortcut; it never touches
the wallpaper directly.

## Testing

- Add a Codable round-trip unit test for `StarChartTheme` (pure JSON encode/decode, no
  App Group dependency).
- Rendering is verified by building and eyeballing the in-app preview (consistent with
  the existing approach — no snapshot tests today).

## Out of scope (YAGNI)

- No multi-palette store, presets, or rename/delete for the star chart (unlike the Today
  widget). One editable theme only.
- No programmatic wallpaper setting beyond the Shortcuts hand-off (not possible on iOS).
