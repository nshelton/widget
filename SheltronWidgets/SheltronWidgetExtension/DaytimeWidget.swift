import WidgetKit
import SwiftUI
import CoreLocation

struct DaytimeProvider: TimelineProvider {
    func placeholder(in context: Context) -> DayEntry {
        DayEntry(date: DayModel.sample.dayStart.addingTimeInterval(18 * 3600), model: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
        Task {
            let now = Date()
            completion(DayEntry(date: now, model: await DayModelBuilder.build(now: now)))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        Task {
            let now = Date()
            let model = await DayModelBuilder.build(now: now)
            let dayEnd = model.dayStart.addingTimeInterval(86400)
            var entries: [DayEntry] = []
            var t = now
            while t < dayEnd {
                entries.append(DayEntry(date: t, model: model))
                t = t.addingTimeInterval(15 * 60)
            }
            if entries.isEmpty { entries = [DayEntry(date: now, model: model)] }
            // Reload at midday to refresh the forecast, then again at the day boundary for new solar curves.
            let midday = model.dayStart.addingTimeInterval(12 * 3600)
            let next = now < midday ? midday : dayEnd
            completion(Timeline(entries: entries, policy: .after(next)))
        }
    }
}

struct DaytimeWidget: Widget {
    let kind = "DaytimeWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DaytimeProvider()) { entry in
            Group {
                if entry.model.locationDenied {
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
