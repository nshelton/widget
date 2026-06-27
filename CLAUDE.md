# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

An iOS 17+ home-screen **widget** ("Today", medium size) that renders the day on a SwiftUI `Canvas`: a full-range sun-elevation arc (above and below a horizon line), the hourly temperature curve, sunrise/sunset markers, and a live pink "now" line. The container **app** is a host + control surface (location permission, a live preview of the exact widget canvas, and a palette editor).

The Xcode project lives one level down at `SheltronWidgets/SheltronWidgets.xcodeproj` — **run all `xcodebuild` from `SheltronWidgets/`**, not the repo root.

## Commands

Build/test scheme is the **app** scheme `SheltronWidgets` (it embeds the extension and the test target). Simulator: `iPhone 17`.

```bash
cd SheltronWidgets

# Build (simulator) — fast compile check
xcodebuild -scheme SheltronWidgets -destination 'platform=iOS Simulator,name=iPhone 17' build

# Run the SolarMath unit tests (the only real logic tests)
xcodebuild test -scheme SheltronWidgets -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:SheltronWidgetsTests/SolarMathTests
```

### Deploy to a physical device (the repeatable loop)

The device build system often can't resolve the device by `id=`; build `generic/platform=iOS` and install with `devicectl`. Device UDID is discovered via `xcrun devicectl list devices`.

```bash
cd SheltronWidgets
xcodebuild -scheme SheltronWidgets -configuration Debug -destination generic/platform=iOS \
  -derivedDataPath /tmp/sheltron-dd -allowProvisioningUpdates build

xcrun devicectl device install app --device <DEVICE-UUID> \
  /tmp/sheltron-dd/Build/Products/Debug-iphoneos/SheltronWidgets.app
xcrun devicectl device process launch --device <DEVICE-UUID> --terminate-existing sheltron.SheltronWidgets
```

WeatherKit and location return nothing on the **simulator** — temperatures and real location only work on device.

## Architecture

**Single source of truth for data:** `DayModelBuilder.build(now:)` assembles a `DayModel` from `LocationProvider` (CoreLocation) + `ForecastService` (WeatherKit) + `SolarMath`. **Both** the widget's `TimelineProvider` (`DaytimeProvider`) and the app's live preview call it, so the two renders are identical by construction. Don't duplicate this logic.

**`SolarMath`** is pure (no network): NOAA solar-position equations for elevation + sunrise/sunset. It uses the **geometric** horizon (`90.0°`, no atmospheric refraction) on purpose — that matches the reference values the design was built against. It's the one component with unit tests.

**Timeline strategy:** `getTimeline` builds one `DayModel` per reload and emits entries every 15 min until midnight, so the "now" line advances across the chart without spending the widget refresh budget. It reloads at midday (refresh forecast) then at the day boundary (new solar curve).

**Rendering:** `DayChartView` is a SwiftUI `Canvas`, drawn **full-bleed** (`plot` = the whole canvas). The widget config uses `.contentMarginsDisabled()` so the black background and chart reach the edges.

**Theming / palettes:** `WidgetTheme` is the 8 configurable colors (`RGBAColor`, Codable). `PaletteStore` is the on-device list of named palettes + `selectedID`, persisted as JSON in the **App Group** `UserDefaults` (suite `group.sheltron.SheltronWidgets`). `WidgetTheme.load()` resolves to `PaletteStore.load().selected`, so the widget always paints the active palette. `SettingsView` (app) edits the selected palette; any change saves the store and calls `WidgetCenter.shared.reloadAllTimelines()`. The app↔widget share data **only** through this App Group — there's no other channel.

## Targets, modules, and file sharing (important)

- App target/scheme: `SheltronWidgets` (display name is **"Today"** via `CFBundleDisplayName`; bundle id `sheltron.SheltronWidgets`).
- Widget extension target/scheme/**module**: `SheltronWidgetExtensionExtension` (Xcode doubled the suffix). Bundle id `sheltron.SheltronWidgets.SheltronWidgetExtension`.
- The project uses **Xcode 26 synchronized folders**: a `.swift` file placed in a target's folder is compiled automatically — do not hand-edit the `.xcodeproj` to add files.
- Shared logic (`SolarMath`, `DayModel`, `DayChartView`, `LocationProvider`, `ForecastService`, `DayModelBuilder`, `WidgetTheme`) physically lives in `SheltronWidgetExtension/` but is compiled into the **app** and **test** targets via `PBXFileSystemSynchronizedBuildFileExceptionSet` membership exceptions in `project.pbxproj`. **To share a new file with the app/test target, add its name to that target's exception set's `membershipExceptions` list** (or check the target's box in Xcode's File Inspector). Tests reach `SolarMath` through direct membership, not `@testable import`.

## Capabilities / external setup (cannot be fully done from the CLI)

- Paid Apple Developer Program; team `2TSY42VQ29`; automatic signing.
- **WeatherKit**: capability + entitlement on both App IDs. After first enabling it, the token service can fail with `Failed to generate jwt token … Code=2` for minutes–hours until it propagates; this is not a code bug. Code already degrades gracefully (sun arc renders, temps omitted).
- **Location**: `NSLocationWhenInUseUsageDescription` is set as an `INFOPLIST_KEY_*` build setting on the app target. The **app** requests When-In-Use (a widget extension can't show the prompt). Treat `.notDetermined` as transient — only `.denied`/`.restricted` should surface the "Enable location" placeholder.
- **App Group** `group.sheltron.SheltronWidgets` on both targets (the palette store).

## Gotchas

- Run the **app** scheme on device, not the extension scheme (the extension scheme needs an `_XCWidgetKind` env var to launch).
- Widget **configuration** changes (e.g. `contentMarginsDisabled`, supported families) don't apply to an already-placed widget — remove and re-add it on the home screen.
- iOS 26 "Liquid Glass": the outer system frame around a home-screen widget is **not** removable via WidgetKit; `containerBackground` only fills the interior.
- The SourceKit indexer reports "Cannot find type …" for the cross-target shared files when viewing them standalone — these are false positives; trust the `xcodebuild` result.

## Process docs

Design spec and the (executed) implementation plan live in `docs/superpowers/`. The original 7-task build was driven via the subagent-driven-development workflow; the ledger is in `.superpowers/sdd/progress.md`.
