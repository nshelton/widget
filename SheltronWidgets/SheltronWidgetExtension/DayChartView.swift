import SwiftUI
import WidgetKit

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
