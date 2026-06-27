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
