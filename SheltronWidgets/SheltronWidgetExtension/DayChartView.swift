import SwiftUI
import WidgetKit

struct DayChartView: View {
    let model: DayModel
    let now: Date

    private let amber = Color(red: 1.0, green: 0.76, blue: 0.32)
    private let pink = Color(red: 1.0, green: 0.36, blue: 0.54)
    private let nightBlue = Color(red: 0.48, green: 0.66, blue: 1.0)
    private let faint = Color.white.opacity(0.45)

    private static let hourFormatter: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "ha"; return f
    }()
    private static let eventFormatter: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "h:mma"; return f
    }()

    private static let stampFormatter: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "h:mma"; return f
    }()

    private func clockLabel(_ date: Date) -> String { Self.hourFormatter.string(from: date).lowercased() }
    private func eventLabel(_ date: Date) -> String { Self.eventFormatter.string(from: date).lowercased().replacingOccurrences(of: ":00", with: "") }
    private func stamp(_ date: Date) -> String { Self.stampFormatter.string(from: date).lowercased() }

    var body: some View {
        Canvas { ctx, size in
            let plot = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            let dayEnd = model.dayStart.addingTimeInterval(86400)

            func x(_ d: Date) -> CGFloat {
                let f = d.timeIntervalSince(model.dayStart) / 86400
                return plot.minX + CGFloat(max(0, min(1, f))) * plot.width
            }
            // Small vertical inset so peaks/troughs don't clip at the very edge.
            func yTemp(_ t: Double) -> CGFloat {
                guard let lo = model.tempMin, let hi = model.tempMax, hi > lo else { return plot.midY }
                let f = (t - lo) / (hi - lo)
                let top = plot.minY + 4, bottom = plot.maxY - 4
                return bottom - CGFloat(max(0, min(1, f))) * (bottom - top)
            }
            // Full-range elevation mapping: whole day's [minElev, maxElev] across the plot, so
            // the curve rises above and dips below the horizon (0°) at true proportions.
            let elevs = model.elevationSamples.map { $0.elevation }
            let maxElev = max(1, elevs.max() ?? 1)
            let minElev = min(-1, elevs.min() ?? -1)
            let elevRange = maxElev - minElev
            let elevPad: CGFloat = 4
            let elevTop = plot.minY + elevPad
            let elevBottom = plot.maxY - elevPad
            func yElev(_ e: Double) -> CGFloat {
                elevBottom - CGFloat((e - minElev) / elevRange) * (elevBottom - elevTop)
            }
            let yHorizon = yElev(0)

            // Sun-elevation curve: filled day above horizon (amber), filled night below (cool),
            // split by clipping the curve↔horizon polygon at the horizon line.
            let elevPts = model.elevationSamples.map { CGPoint(x: x($0.date), y: yElev($0.elevation)) }
            var poly = Path()
            poly.move(to: CGPoint(x: plot.minX, y: yHorizon))
            for p in elevPts { poly.addLine(to: p) }
            poly.addLine(to: CGPoint(x: plot.maxX, y: yHorizon))
            poly.closeSubpath()

            var dayLayer = ctx
            dayLayer.clip(to: Path(CGRect(x: plot.minX, y: plot.minY, width: plot.width, height: yHorizon - plot.minY)))
            dayLayer.fill(poly, with: .color(amber.opacity(0.32)))

            var nightLayer = ctx
            nightLayer.clip(to: Path(CGRect(x: plot.minX, y: yHorizon, width: plot.width, height: plot.maxY - yHorizon)))
            nightLayer.fill(poly, with: .color(nightBlue.opacity(0.30)))

            // Horizon line (0° elevation)
            var horizon = Path()
            horizon.move(to: CGPoint(x: plot.minX, y: yHorizon))
            horizon.addLine(to: CGPoint(x: plot.maxX, y: yHorizon))
            ctx.stroke(horizon, with: .color(.white.opacity(0.28)), lineWidth: 1)

            // Full elevation curve stroke
            var arc = Path()
            for (i, p) in elevPts.enumerated() { i == 0 ? arc.move(to: p) : arc.addLine(to: p) }
            ctx.stroke(arc, with: .color(amber.opacity(0.9)), lineWidth: 1.8)

            // Hourly temperature line
            if model.hourlyTemps.count > 1 {
                var line = Path()
                for (i, h) in model.hourlyTemps.enumerated() {
                    let p = CGPoint(x: x(h.date), y: yTemp(h.temp))
                    i == 0 ? line.move(to: p) : line.addLine(to: p)
                }
                ctx.stroke(line, with: .color(amber), lineWidth: 2.4)
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
                ctx.stroke(nl, with: .color(pink), lineWidth: 1.8)
                if let curTemp = interpolatedTemp(at: now) {
                    let dot = CGRect(x: x(now) - 3.5, y: yTemp(curTemp) - 3.5, width: 7, height: 7)
                    ctx.fill(Path(ellipseIn: dot), with: .color(pink))
                }
            }

            // Axis labels: temps (left corners) and interior hour ticks (bottom)
            if let hi = model.tempMax {
                ctx.draw(Text("\(Int(hi.rounded()))°").font(.system(size: 13, design: .monospaced)).foregroundColor(.white.opacity(0.7)),
                         at: CGPoint(x: 3, y: plot.minY + 1), anchor: .topLeading)
            }
            if let lo = model.tempMin {
                ctx.draw(Text("\(Int(lo.rounded()))°").font(.system(size: 13, design: .monospaced)).foregroundColor(.white.opacity(0.7)),
                         at: CGPoint(x: 3, y: plot.maxY - 1), anchor: .bottomLeading)
            }
            for hour in [6, 12, 18] {
                let d = model.dayStart.addingTimeInterval(Double(hour) * 3600)
                ctx.draw(Text(clockLabel(d)).font(.system(size: 9, design: .monospaced)).foregroundColor(faint),
                         at: CGPoint(x: x(d), y: plot.maxY - 2), anchor: .bottom)
            }
        }
        .overlay(alignment: .topTrailing) {
            Text(stamp(model.generatedAt))
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white.opacity(0.35))
                .padding(.trailing, 4).padding(.top, 2)
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
