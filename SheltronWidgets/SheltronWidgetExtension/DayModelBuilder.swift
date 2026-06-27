import Foundation
import CoreLocation

// Shared model-building used by BOTH the widget timeline provider and the app's
// live preview, so they render from identical data + logic.
enum DayModelBuilder {
    static let fallback = CLLocation(latitude: 34.0522, longitude: -118.2437)

    static func build(now: Date) async -> DayModel {
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
