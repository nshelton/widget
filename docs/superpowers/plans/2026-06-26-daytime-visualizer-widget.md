# Daytime Visualizer Widget Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A medium iOS home-screen widget that draws the day's sun-elevation arc and hourly temperature curve on a true-black canvas, with sunrise/sunset markers and a live "now" line.

**Architecture:** One Xcode project with a container app and a Widget Extension. A pure-Swift `SolarMath` module computes sun elevation + sunrise/sunset (no network). `ForecastService` (WeatherKit) supplies hourly temps and `LocationProvider` (CoreLocation) supplies coordinates + city. A `TimelineProvider` assembles one `DayModel` per day and emits 15-minute entries so the pink "now" line advances without burning refresh budget. `DayChartView` renders everything with SwiftUI `Canvas`.

**Tech Stack:** Swift, SwiftUI, WidgetKit, WeatherKit, CoreLocation, XCTest, Xcode.

## Global Constraints

- Platform: iOS 17+ (WidgetKit + SwiftUI `Canvas`)
- Background: true black `#000000` (`Color.black`)
- Font: monospace throughout (`.system(.body, design: .monospaced)` sizing variants)
- Accent: amber/orange for curves; single pink vertical "now" line
- Primary widget family: `.systemMedium` only (v1)
- Temperature unit: Fahrenheit
- Our forecast type is named `ForecastService` (NOT `WeatherService` — collides with `WeatherKit.WeatherService`)
- Xcode 26 uses synchronized folders: a `.swift` file placed in a target's folder is compiled automatically. `SolarMath`/`DayModel` live only in the extension folder; the test target accesses them via `@testable import DaytimeWidgetExtension` (no dual target membership needed)
- Simulator destination: `platform=iOS Simulator,name=iPhone 17`
- No App Group needed: the widget computes/fetches everything itself
- Apple Developer Program account with WeatherKit capability enabled (user has it)

---

### Task 1: Project, targets, capabilities, and git

**Files:**
- Create: `DaytimeWidgets.xcodeproj` (via Xcode)
- Create: `DaytimeWidgets/` (app target sources)
- Create: `DaytimeWidgetExtension/` (widget extension target sources)
- Create: `DaytimeWidgetsTests/` (unit test target)
- Create: `.gitignore`

**Interfaces:**
- Consumes: nothing
- Produces: a buildable project with three targets and a shared file-membership convention (model/math files belong to extension + test targets).

- [ ] **Step 1: Initialize git**

```bash
cd /Users/nshelton/iostest
git init
```

- [ ] **Step 2: Create the app project in Xcode**

In Xcode: File → New → Project → iOS → App.
- Product Name: `DaytimeWidgets`
- Interface: SwiftUI, Language: Swift
- Check **Include Tests**
- Save into `/Users/nshelton/iostest`

- [ ] **Step 3: Add the Widget Extension target**

File → New → Target → Widget Extension.
- Product Name: `DaytimeWidgetExtension`
- **Uncheck** "Include Live Activity" and "Include Configuration App Intent" (static widget, no configuration in v1)
- Activate the scheme when prompted.

- [ ] **Step 4: Enable WeatherKit**

- In the Apple Developer portal, enable the **WeatherKit** capability for the app's App ID.
- In Xcode, select the **app target** → Signing & Capabilities → `+ Capability` → **WeatherKit**.
- Repeat for the **DaytimeWidgetExtension** target (the extension is what calls WeatherKit).

- [ ] **Step 5: Add location usage string**

In the **app target** Info settings, add:
- Key: `NSLocationWhenInUseUsageDescription`
- Value: `Used to show the sun and weather for your current location.`

- [ ] **Step 6: Create `.gitignore`**

```
build/
DerivedData/
*.xcuserstate
xcuserdata/
.DS_Store
```

- [ ] **Step 7: Verify the project builds**

Run:
```bash
xcodebuild -scheme DaytimeWidgetExtension -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "chore: scaffold DaytimeWidgets app, widget extension, and tests"
```

---

### Task 2: SolarMath (pure solar position + sunrise/sunset)

**Files:**
- Create: `DaytimeWidgetExtension/SolarMath.swift` (target membership: extension **and** `DaytimeWidgetsTests`)
- Test: `DaytimeWidgetsTests/SolarMathTests.swift`

**Interfaces:**
- Consumes: nothing
- Produces:
  - `enum SolarMath`
  - `static func sunElevation(date: Date, latitude: Double, longitude: Double) -> Double` (degrees; negative = below horizon)
  - `static func sunEvents(date: Date, latitude: Double, longitude: Double) -> (sunrise: Date?, sunset: Date?)` (absolute Dates; nil on polar day/night)
  - `static func elevationSamples(date: Date, latitude: Double, longitude: Double, interval: TimeInterval) -> [(date: Date, elevation: Double)]`

- [ ] **Step 1: Write the failing test**

`DaytimeWidgetsTests/SolarMathTests.swift`:

```swift
import XCTest
@testable import DaytimeWidgetExtension

final class SolarMathTests: XCTestCase {
    // Los Angeles
    let lat = 34.0522, lon = -118.2437

    private func laDate(_ h: Int, _ m: Int) -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 6; c.day = 26; c.hour = h; c.minute = m
        c.timeZone = TimeZone(identifier: "America/Los_Angeles")
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    func test_sunrise_and_sunset_match_LA_on_2026_06_26() {
        let day = laDate(12, 0)
        let events = SolarMath.sunEvents(date: day, latitude: lat, longitude: lon)
        let sunrise = try! XCTUnwrap(events.sunrise)
        let sunset = try! XCTUnwrap(events.sunset)
        // Expected ~05:48 and ~20:04 local
        XCTAssertEqual(sunrise.timeIntervalSince(laDate(5, 48)), 0, accuracy: 120)
        XCTAssertEqual(sunset.timeIntervalSince(laDate(20, 4)), 0, accuracy: 120)
    }

    func test_elevation_is_negative_at_local_midnight_and_high_at_noon() {
        XCTAssertLessThan(SolarMath.sunElevation(date: laDate(0, 0), latitude: lat, longitude: lon), 0)
        XCTAssertGreaterThan(SolarMath.sunElevation(date: laDate(13, 0), latitude: lat, longitude: lon), 70)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
xcodebuild test -scheme DaytimeWidgets -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DaytimeWidgetsTests/SolarMathTests
```
Expected: FAIL — `cannot find 'SolarMath' in scope`.

- [ ] **Step 3: Write minimal implementation**

`DaytimeWidgetExtension/SolarMath.swift` (NOAA solar position equations):

```swift
import Foundation

enum SolarMath {
    private static func rad(_ d: Double) -> Double { d * .pi / 180 }
    private static func deg(_ r: Double) -> Double { r * 180 / .pi }

    private static func julianDay(_ date: Date) -> Double {
        date.timeIntervalSince1970 / 86400.0 + 2440587.5
    }

    /// Declination (deg) and equation of time (minutes) for a Julian Day.
    private static func params(_ jd: Double) -> (decl: Double, eqTime: Double) {
        let jc = (jd - 2451545.0) / 36525.0
        let l0 = (280.46646 + jc * (36000.76983 + jc * 0.0003032)).truncatingRemainder(dividingBy: 360)
        let m = 357.52911 + jc * (35999.05029 - 0.0001537 * jc)
        let e = 0.016708634 - jc * (0.000042037 + 0.0000001267 * jc)
        let c = sin(rad(m)) * (1.914602 - jc * (0.004817 + 0.000014 * jc))
              + sin(rad(2 * m)) * (0.019993 - 0.000101 * jc)
              + sin(rad(3 * m)) * 0.000289
        let trueLong = l0 + c
        let lambda = trueLong - 0.00569 - 0.00478 * sin(rad(125.04 - 1934.136 * jc))
        let e0 = 23 + (26 + (21.448 - jc * (46.815 + jc * (0.00059 - jc * 0.001813))) / 60) / 60
        let eCorr = e0 + 0.00256 * cos(rad(125.04 - 1934.136 * jc))
        let decl = deg(asin(sin(rad(eCorr)) * sin(rad(lambda))))
        let y = pow(tan(rad(eCorr / 2)), 2)
        let eqTime = 4 * deg(
            y * sin(2 * rad(l0))
            - 2 * e * sin(rad(m))
            + 4 * e * y * sin(rad(m)) * cos(2 * rad(l0))
            - 0.5 * y * y * sin(4 * rad(l0))
            - 1.25 * e * e * sin(2 * rad(m))
        )
        return (decl, eqTime)
    }

    static func sunElevation(date: Date, latitude: Double, longitude: Double) -> Double {
        let jd = julianDay(date)
        let p = params(jd)
        let minutesUTC = (jd + 0.5).truncatingRemainder(dividingBy: 1) * 1440
        var trueSolarTime = (minutesUTC + p.eqTime + 4 * longitude).truncatingRemainder(dividingBy: 1440)
        if trueSolarTime < 0 { trueSolarTime += 1440 }
        var hourAngle = trueSolarTime / 4 - 180
        if hourAngle < -180 { hourAngle += 360 }
        let cosZenith = sin(rad(latitude)) * sin(rad(p.decl))
            + cos(rad(latitude)) * cos(rad(p.decl)) * cos(rad(hourAngle))
        let zenith = deg(acos(max(-1, min(1, cosZenith))))
        return 90 - zenith
    }

    static func sunEvents(date: Date, latitude: Double, longitude: Double) -> (sunrise: Date?, sunset: Date?) {
        // Compute at local solar noon for stable declination/eqTime.
        let noonJD = julianDay(date)
        let p = params(noonJD)
        let cosH = cos(rad(90.833)) / (cos(rad(latitude)) * cos(rad(p.decl)))
                 - tan(rad(latitude)) * tan(rad(p.decl))
        guard cosH >= -1, cosH <= 1 else { return (nil, nil) } // polar day/night
        let haSunrise = deg(acos(cosH))
        let solarNoonUTCmin = 720 - 4 * longitude - p.eqTime
        let utcMidnight = Calendar.utc.startOfDay(for: date)
        func dateAt(_ minutes: Double) -> Date { utcMidnight.addingTimeInterval(minutes * 60) }
        return (dateAt(solarNoonUTCmin - 4 * haSunrise),
                dateAt(solarNoonUTCmin + 4 * haSunrise))
    }

    static func elevationSamples(date: Date, latitude: Double, longitude: Double, interval: TimeInterval) -> [(date: Date, elevation: Double)] {
        let localStart = Calendar.current.startOfDay(for: date)
        var out: [(Date, Double)] = []
        var t = localStart
        let end = localStart.addingTimeInterval(86400)
        while t <= end {
            out.append((t, sunElevation(date: t, latitude: latitude, longitude: longitude)))
            t = t.addingTimeInterval(interval)
        }
        return out
    }
}

extension Calendar {
    static let utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }()
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
xcodebuild test -scheme DaytimeWidgets -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:DaytimeWidgetsTests/SolarMathTests
```
Expected: PASS (both tests).

- [ ] **Step 5: Commit**

```bash
git add DaytimeWidgetExtension/SolarMath.swift DaytimeWidgetsTests/SolarMathTests.swift
git commit -m "feat: add SolarMath solar-position and sunrise/sunset calculations"
```

---

### Task 3: DayModel, DayEntry, and a preview fixture

**Files:**
- Create: `DaytimeWidgetExtension/DayModel.swift` (target membership: extension + tests)

**Interfaces:**
- Consumes: `SolarMath`
- Produces:
  - `struct DayModel` with `city: String?`, `hourlyTemps: [(date: Date, temp: Double)]`, `elevationSamples: [(date: Date, elevation: Double)]`, `sunrise: Date?`, `sunset: Date?`, `tempMin: Double?`, `tempMax: Double?`, `dayStart: Date`
  - `struct DayEntry: TimelineEntry` with `date: Date` (= "now") and `model: DayModel`
  - `static var DayModel.sample: DayModel` (for previews/tests)

- [ ] **Step 1: Write the implementation**

`DaytimeWidgetExtension/DayModel.swift`:

```swift
import WidgetKit
import Foundation

struct DayModel {
    let city: String?
    let hourlyTemps: [(date: Date, temp: Double)]
    let elevationSamples: [(date: Date, elevation: Double)]
    let sunrise: Date?
    let sunset: Date?
    let tempMin: Double?
    let tempMax: Double?
    let dayStart: Date
}

struct DayEntry: TimelineEntry {
    let date: Date   // display time == "now"
    let model: DayModel
}

extension DayModel {
    /// Deterministic fixture: LA-ish, sinusoidal temps, real solar curve.
    static var sample: DayModel {
        let lat = 34.0522, lon = -118.2437
        var comps = DateComponents()
        comps.year = 2026; comps.month = 6; comps.day = 26
        comps.timeZone = TimeZone(identifier: "America/Los_Angeles")
        let dayStart = Calendar.current.startOfDay(for: Calendar(identifier: .gregorian).date(from: comps)!)
        let elev = SolarMath.elevationSamples(date: dayStart, latitude: lat, longitude: lon, interval: 600)
        let events = SolarMath.sunEvents(date: dayStart, latitude: lat, longitude: lon)
        let temps: [(date: Date, temp: Double)] = (0...24).map { h in
            let t = dayStart.addingTimeInterval(Double(h) * 3600)
            let temp = 68 + 9 * sin((Double(h) - 9) / 24 * 2 * .pi) // peak ~3pm-ish
            return (t, temp)
        }
        let values = temps.map { $0.temp }
        return DayModel(
            city: "Los Angeles, CA",
            hourlyTemps: temps,
            elevationSamples: elev,
            sunrise: events.sunrise,
            sunset: events.sunset,
            tempMin: values.min(),
            tempMax: values.max(),
            dayStart: dayStart
        )
    }
}
```

- [ ] **Step 2: Verify it builds**

Run:
```bash
xcodebuild -scheme DaytimeWidgetExtension -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add DaytimeWidgetExtension/DayModel.swift
git commit -m "feat: add DayModel, DayEntry, and preview fixture"
```

---

### Task 4: DayChartView (Canvas rendering)

**Files:**
- Create: `DaytimeWidgetExtension/DayChartView.swift`

**Interfaces:**
- Consumes: `DayModel`
- Produces: `struct DayChartView: View { init(model: DayModel, now: Date) }`

- [ ] **Step 1: Write the implementation**

`DaytimeWidgetExtension/DayChartView.swift`:

```swift
import SwiftUI

struct DayChartView: View {
    let model: DayModel
    let now: Date

    private let amber = Color(red: 1.0, green: 0.62, blue: 0.16)
    private let pink = Color(red: 1.0, green: 0.30, blue: 0.42)
    private let faint = Color.white.opacity(0.28)

    private func clockLabel(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "ha"
        return f.string(from: date).lowercased()
    }
    private func eventLabel(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mma"
        return f.string(from: date).lowercased().replacingOccurrences(of: ":00", with: "")
    }

    var body: some View {
        Canvas { ctx, size in
            let plot = CGRect(x: 34, y: 14, width: size.width - 44, height: size.height - 34)
            let dayEnd = model.dayStart.addingTimeInterval(86400)

            func x(_ d: Date) -> CGFloat {
                let f = d.timeIntervalSince(model.dayStart) / 86400
                return plot.minX + CGFloat(max(0, min(1, f))) * plot.width
            }
            func yTemp(_ t: Double) -> CGFloat {
                guard let lo = model.tempMin, let hi = model.tempMax, hi > lo else { return plot.midY }
                let f = (t - lo) / (hi - lo)
                return plot.maxY - CGFloat(max(0, min(1, f))) * plot.height
            }
            let maxElev = max(1, model.elevationSamples.map { $0.elevation }.max() ?? 1)
            func yElev(_ e: Double) -> CGFloat {
                plot.maxY - CGFloat(max(0, e) / maxElev) * plot.height
            }

            // Sun-elevation filled arc
            var arc = Path()
            arc.move(to: CGPoint(x: plot.minX, y: plot.maxY))
            for s in model.elevationSamples { arc.addLine(to: CGPoint(x: x(s.date), y: yElev(s.elevation))) }
            arc.addLine(to: CGPoint(x: plot.maxX, y: plot.maxY))
            arc.closeSubpath()
            ctx.fill(arc, with: .color(amber.opacity(0.18)))
            ctx.stroke(arc, with: .color(amber.opacity(0.55)), lineWidth: 1.5)

            // Hourly temperature line
            if model.hourlyTemps.count > 1 {
                var line = Path()
                for (i, h) in model.hourlyTemps.enumerated() {
                    let p = CGPoint(x: x(h.date), y: yTemp(h.temp))
                    i == 0 ? line.move(to: p) : line.addLine(to: p)
                }
                ctx.stroke(line, with: .color(amber), lineWidth: 2)
            }

            // Dashed reference line at current temp
            if let curTemp = interpolatedTemp(at: now) {
                var dash = Path()
                dash.move(to: CGPoint(x: plot.minX, y: yTemp(curTemp)))
                dash.addLine(to: CGPoint(x: plot.maxX, y: yTemp(curTemp)))
                ctx.stroke(dash, with: .color(faint), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
            }

            // Sunrise / sunset verticals + labels
            for (event, label, up) in [(model.sunrise, "↑ ", true), (model.sunset, " ↓", false)] {
                guard let e = event, e >= model.dayStart, e < dayEnd else { continue }
                var v = Path()
                v.move(to: CGPoint(x: x(e), y: plot.minY))
                v.addLine(to: CGPoint(x: x(e), y: plot.maxY))
                ctx.stroke(v, with: .color(faint), lineWidth: 1)
                let text = up ? label + eventLabel(e) : eventLabel(e) + label
                ctx.draw(Text(text).font(.system(size: 9, design: .monospaced)).foregroundColor(faint),
                         at: CGPoint(x: x(e) + (up ? 2 : -2), y: plot.minY + 4),
                         anchor: up ? .topLeading : .topTrailing)
            }

            // Now line + dot
            if now >= model.dayStart, now < dayEnd {
                var nl = Path()
                nl.move(to: CGPoint(x: x(now), y: plot.minY - 4))
                nl.addLine(to: CGPoint(x: x(now), y: plot.maxY))
                ctx.stroke(nl, with: .color(pink), lineWidth: 1.5)
                if let curTemp = interpolatedTemp(at: now) {
                    let dot = CGRect(x: x(now) - 3.5, y: yTemp(curTemp) - 3.5, width: 7, height: 7)
                    ctx.fill(Path(ellipseIn: dot), with: .color(pink))
                }
            }

            // Axis labels: temps (left) and hours (bottom)
            if let hi = model.tempMax {
                ctx.draw(Text("\(Int(hi.rounded()))°").font(.system(size: 13, design: .monospaced)).foregroundColor(.white.opacity(0.5)),
                         at: CGPoint(x: 4, y: plot.minY), anchor: .topLeading)
            }
            if let lo = model.tempMin {
                ctx.draw(Text("\(Int(lo.rounded()))°").font(.system(size: 13, design: .monospaced)).foregroundColor(.white.opacity(0.5)),
                         at: CGPoint(x: 4, y: plot.maxY), anchor: .bottomLeading)
            }
            for hour in [0, 6, 12, 18] {
                let d = model.dayStart.addingTimeInterval(Double(hour) * 3600)
                ctx.draw(Text(clockLabel(d)).font(.system(size: 9, design: .monospaced)).foregroundColor(faint),
                         at: CGPoint(x: x(d), y: plot.maxY + 4), anchor: .top)
            }
        }
        .overlay(alignment: .bottomLeading) {
            Text("Today · \(model.city ?? "—")")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
                .padding(.leading, 4).padding(.bottom, 2)
        }
        .padding(8)
        .background(Color.black)
    }

    private func interpolatedTemp(at date: Date) -> Double? {
        let pts = model.hourlyTemps
        guard let first = pts.first, let last = pts.last else { return nil }
        if date <= first.date { return first.temp }
        if date >= last.date { return last.temp }
        for i in 1..<pts.count where pts[i].date >= date {
            let a = pts[i - 1], b = pts[i]
            let f = date.timeIntervalSince(a.date) / b.date.timeIntervalSince(a.date)
            return a.temp + (b.temp - a.temp) * f
        }
        return last.temp
    }
}

#Preview(as: .systemMedium) {
    DayChartWidgetPreviewHost()
} timeline: {
    DayEntry(date: DayModel.sample.dayStart.addingTimeInterval(18 * 3600), model: .sample)
}

// Minimal preview host so #Preview can render the view standalone.
private struct DayChartWidgetPreviewHost: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "preview", provider: PreviewProvider()) { entry in
            DayChartView(model: entry.model, now: entry.date).containerBackground(.black, for: .widget)
        }
    }
    struct PreviewProvider: TimelineProvider {
        func placeholder(in c: Context) -> DayEntry { DayEntry(date: DayModel.sample.dayStart, model: .sample) }
        func getSnapshot(in c: Context, completion: @escaping (DayEntry) -> Void) { completion(placeholder(in: c)) }
        func getTimeline(in c: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
            completion(Timeline(entries: [placeholder(in: c)], policy: .never))
        }
    }
}
```

- [ ] **Step 2: Verify in Xcode Preview**

Open `DayChartView.swift` in Xcode, run the `#Preview`. Expected: a true-black medium widget showing the amber sun arc, amber temp line, sunrise/sunset markers (`↑ 5:48a`, `8:04p ↓`), a pink now-line with a dot near the 6pm region, `77°`/`60°`-style labels, and the `Today · Los Angeles, CA` footer.

- [ ] **Step 3: Verify it builds**

Run:
```bash
xcodebuild -scheme DaytimeWidgetExtension -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add DaytimeWidgetExtension/DayChartView.swift
git commit -m "feat: render day chart with Canvas (sun arc, temp curve, now-line)"
```

---

### Task 5: LocationProvider (CoreLocation one-shot + city)

**Files:**
- Create: `DaytimeWidgetExtension/LocationProvider.swift`

**Interfaces:**
- Consumes: nothing
- Produces:
  - `struct LocatedPlace { let location: CLLocation; let city: String? }`
  - `final class LocationProvider` with `func current() async throws -> LocatedPlace`
  - `enum LocationError: Error { case denied }`

- [ ] **Step 1: Write the implementation**

`DaytimeWidgetExtension/LocationProvider.swift`:

```swift
import CoreLocation

struct LocatedPlace { let location: CLLocation; let city: String? }
enum LocationError: Error { case denied }

final class LocationProvider: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var cont: CheckedContinuation<CLLocation, Error>?

    func current() async throws -> LocatedPlace {
        let status = manager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            throw LocationError.denied
        }
        let loc: CLLocation
        if let last = manager.location {
            loc = last
        } else {
            loc = try await withCheckedThrowingContinuation { c in
                self.cont = c
                manager.delegate = self
                manager.requestLocation()
            }
        }
        let city = try? await reverseGeocode(loc)
        return LocatedPlace(location: loc, city: city)
    }

    private func reverseGeocode(_ loc: CLLocation) async throws -> String? {
        let marks = try await CLGeocoder().reverseGeocodeLocation(loc)
        guard let p = marks.first else { return nil }
        let city = p.locality ?? p.administrativeArea
        if let city, let state = p.administrativeArea, city != state { return "\(city), \(state)" }
        return city
    }

    func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        if let l = locs.last { cont?.resume(returning: l); cont = nil }
    }
    func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {
        cont?.resume(throwing: error); cont = nil
    }
}
```

- [ ] **Step 2: Verify it builds**

Run:
```bash
xcodebuild -scheme DaytimeWidgetExtension -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add DaytimeWidgetExtension/LocationProvider.swift
git commit -m "feat: add LocationProvider (one-shot location + reverse-geocoded city)"
```

---

### Task 6: ForecastService (WeatherKit hourly temps)

**Files:**
- Create: `DaytimeWidgetExtension/ForecastService.swift`

**Interfaces:**
- Consumes: nothing (takes a `CLLocation`)
- Produces:
  - `struct ForecastService` with `func hourlyTemps(for location: CLLocation, on day: Date) async throws -> [(date: Date, temp: Double)]`

- [ ] **Step 1: Write the implementation**

`DaytimeWidgetExtension/ForecastService.swift`:

```swift
import WeatherKit
import CoreLocation

struct ForecastService {
    func hourlyTemps(for location: CLLocation, on day: Date) async throws -> [(date: Date, temp: Double)] {
        let hourly = try await WeatherKit.WeatherService.shared.weather(for: location, including: .hourly)
        let start = Calendar.current.startOfDay(for: day)
        let end = start.addingTimeInterval(86400)
        return hourly.forecast
            .filter { $0.date >= start && $0.date < end }
            .map { (date: $0.date, temp: $0.temperature.converted(to: .fahrenheit).value) }
    }
}
```

- [ ] **Step 2: Verify it builds**

Run:
```bash
xcodebuild -scheme DaytimeWidgetExtension -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add DaytimeWidgetExtension/ForecastService.swift
git commit -m "feat: add ForecastService (WeatherKit hourly temperatures)"
```

---

### Task 7: DaytimeWidget (TimelineProvider wiring + entry cadence)

**Files:**
- Modify: the widget extension's generated entry file → replace with `DaytimeWidgetExtension/DaytimeWidget.swift`
- Modify: the extension's `@main` bundle to register `DaytimeWidget`

**Interfaces:**
- Consumes: `SolarMath`, `DayModel`, `DayEntry`, `DayChartView`, `LocationProvider`, `ForecastService`
- Produces: `struct DaytimeWidget: Widget` (kind `"DaytimeWidget"`, `.systemMedium`)

- [ ] **Step 1: Write the implementation**

`DaytimeWidgetExtension/DaytimeWidget.swift`:

```swift
import WidgetKit
import SwiftUI
import CoreLocation

struct DaytimeProvider: TimelineProvider {
    private let fallback = CLLocation(latitude: 34.0522, longitude: -118.2437)

    func placeholder(in context: Context) -> DayEntry {
        DayEntry(date: DayModel.sample.dayStart.addingTimeInterval(18 * 3600), model: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
        Task { completion(await buildEntry(now: Date())) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        Task {
            let now = Date()
            let model = await buildModel(now: now)
            let dayEnd = model.dayStart.addingTimeInterval(86400)
            var entries: [DayEntry] = []
            var t = now
            while t < dayEnd {
                entries.append(DayEntry(date: t, model: model))
                t = t.addingTimeInterval(15 * 60)
            }
            if entries.isEmpty { entries = [DayEntry(date: now, model: model)] }
            // Reload at next midnight (curves change) — also refreshes the forecast.
            completion(Timeline(entries: entries, policy: .after(dayEnd)))
        }
    }

    private func buildEntry(now: Date) async -> DayEntry {
        DayEntry(date: now, model: await buildModel(now: now))
    }

    private func buildModel(now: Date) async -> DayModel {
        let dayStart = Calendar.current.startOfDay(for: now)
        var place: LocatedPlace?
        do { place = try await LocationProvider().current() } catch { place = nil }
        let location = place?.location ?? fallback

        let elevation = SolarMath.elevationSamples(date: dayStart, latitude: location.coordinate.latitude,
                                                   longitude: location.coordinate.longitude, interval: 600)
        let events = SolarMath.sunEvents(date: dayStart, latitude: location.coordinate.latitude,
                                         longitude: location.coordinate.longitude)

        var temps: [(date: Date, temp: Double)] = []
        if place != nil {
            temps = (try? await ForecastService().hourlyTemps(for: location, on: dayStart)) ?? []
        }
        let values = temps.map { $0.temp }

        return DayModel(
            city: place?.city,
            hourlyTemps: temps,
            elevationSamples: elevation,
            sunrise: events.sunrise,
            sunset: events.sunset,
            tempMin: values.min(),
            tempMax: values.max(),
            dayStart: dayStart
        )
    }
}

struct DaytimeWidget: Widget {
    let kind = "DaytimeWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DaytimeProvider()) { entry in
            Group {
                if entry.model.city == nil && entry.model.hourlyTemps.isEmpty && entry.model.sunrise == nil {
                    Text("Enable location")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    DayChartView(model: entry.model, now: entry.date)
                }
            }
            .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Daytime")
        .description("Sun arc and temperature across the day.")
        .supportedFamilies([.systemMedium])
    }
}
```

Note: when location is denied we still have the sun arc (no network needed), so the "Enable location" placeholder only shows in the rare all-empty case. This matches the spec's graceful degradation.

- [ ] **Step 2: Register the widget in the bundle**

In the extension's `@main` bundle file (e.g. `DaytimeWidgetExtensionBundle.swift`), ensure the body lists `DaytimeWidget()`:

```swift
import WidgetKit
import SwiftUI

@main
struct DaytimeWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        DaytimeWidget()
    }
}
```

Delete the Xcode-generated sample widget/provider/entry files that are now replaced.

- [ ] **Step 3: Run on a simulator and add the widget**

Run:
```bash
xcodebuild -scheme DaytimeWidgetExtension -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Then run the app target on the simulator, go to the Home Screen, long-press → add the **Daytime** medium widget.
Expected: the chart renders (simulator uses the LA fallback when location/WeatherKit are unavailable; the sun arc + markers always show).

- [ ] **Step 4: Verify on a physical device**

Run the app on your iPhone (real WeatherKit + location). Add the medium widget.
Expected: real city, real hourly temps, sun arc, sunrise/sunset, and the pink now-line at the current time. Confirm the now-line advances over ~15–30 min.

- [ ] **Step 5: Commit**

```bash
git add DaytimeWidgetExtension/DaytimeWidget.swift DaytimeWidgetExtension/DaytimeWidgetExtensionBundle.swift
git commit -m "feat: wire DaytimeWidget timeline provider with 15-min now-line cadence"
```

---

## Notes / Known Follow-ups (out of scope for v1)

- The simulator generally can't serve WeatherKit/location; verify temps on a real device.
- WeatherKit's first call after enabling the capability can take a few minutes to start returning data while the service provisions.
- Future widgets in the set (recorder-data viz, text launcher) reuse this project and get their own specs.
