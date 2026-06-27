import XCTest

final class CelestialMathTests: XCTestCase {
    private func j2000() -> Date {
        // JD 2451545.0 = 2000-01-01 12:00:00 UTC
        Date(timeIntervalSince1970: (2451545.0 - 2440587.5) * 86400.0)
    }

    func test_ecliptic_to_equatorial_at_vernal_point() {
        let (ra, dec) = CelestialMath.eclipticToEquatorial(lon: 0, lat: 0, date: j2000())
        XCTAssertEqual(ra, 0, accuracy: 0.01)
        XCTAssertEqual(dec, 0, accuracy: 0.05)
    }

    func test_ecliptic_to_equatorial_at_summer_solstice_point() {
        let (ra, dec) = CelestialMath.eclipticToEquatorial(lon: 90, lat: 0, date: j2000())
        XCTAssertEqual(ra, 6, accuracy: 0.01)        // 6h
        XCTAssertEqual(dec, 23.44, accuracy: 0.05)   // obliquity
    }

    func test_ecliptic_to_equatorial_at_autumnal_point() {
        let (ra, dec) = CelestialMath.eclipticToEquatorial(lon: 180, lat: 0, date: j2000())
        XCTAssertEqual(ra, 12, accuracy: 0.01)       // 12h
        XCTAssertEqual(dec, 0, accuracy: 0.05)
    }

    func test_sun_ecliptic_longitude_at_j2000() {
        // The Sun's apparent ecliptic longitude at J2000 is ~280.4°.
        let lon = CelestialMath.sunEclipticLongitude(j2000())
        XCTAssertEqual(lon, 280.4, accuracy: 0.5)
    }

    func test_moon_illuminated_fraction_in_range() {
        let f = CelestialMath.moonIllumination(j2000()).fraction
        XCTAssertGreaterThanOrEqual(f, 0)
        XCTAssertLessThanOrEqual(f, 1)
    }

    func test_moon_is_nearly_new_at_known_new_moon() {
        // New moon: 2000-01-06 18:14 UTC
        let newMoon = Date(timeIntervalSince1970: 947182440)
        let f = CelestialMath.moonIllumination(newMoon).fraction
        XCTAssertLessThan(f, 0.10)
    }
}
