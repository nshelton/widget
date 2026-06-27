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
            // Reload at midday to refresh the forecast, then again at the day boundary for new solar curves.
            let midday = model.dayStart.addingTimeInterval(12 * 3600)
            let next = now < midday ? midday : dayEnd
            completion(Timeline(entries: entries, policy: .after(next)))
        }
    }

    private func buildEntry(now: Date) async -> DayEntry {
        DayEntry(date: now, model: await buildModel(now: now))
    }

    private func buildModel(now: Date) async -> DayModel {
        let dayStart = Calendar.current.startOfDay(for: now)
        var place: LocatedPlace?
        var denied = false
        do { place = try await LocationProvider().current() }
        catch LocationError.denied { denied = true; place = nil }
        catch { place = nil }
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
            dayStart: dayStart,
            locationDenied: denied
        )
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
