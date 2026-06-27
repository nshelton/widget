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
