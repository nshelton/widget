import XCTest
@testable import SheltronWidgetExtensionExtension

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
