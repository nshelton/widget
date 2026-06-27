import Foundation

enum CelestialMath {
    private static func rad(_ d: Double) -> Double { d * .pi / 180 }
    private static func deg(_ r: Double) -> Double { r * 180 / .pi }

    /// Greenwich Mean Sidereal Time in hours for a given date.
    static func gmst(_ date: Date) -> Double {
        let jd = date.timeIntervalSince1970 / 86400.0 + 2440587.5
        let t = (jd - 2451545.0) / 36525.0
        var gmst = 280.46061837
            + 360.98564736629 * (jd - 2451545.0)
            + 0.000387933 * t * t
            - t * t * t / 38710000.0
        gmst = gmst.truncatingRemainder(dividingBy: 360)
        if gmst < 0 { gmst += 360 }
        return gmst / 15.0 // convert degrees to hours
    }

    /// Local Sidereal Time in hours.
    static func lst(_ date: Date, longitude: Double) -> Double {
        var lst = gmst(date) + longitude / 15.0
        lst = lst.truncatingRemainder(dividingBy: 24)
        if lst < 0 { lst += 24 }
        return lst
    }

    /// Convert equatorial (RA hours, Dec degrees) to horizontal (altitude, azimuth degrees).
    /// Azimuth: 0=N, 90=E, 180=S, 270=W.
    static func equatorialToHorizontal(
        ra: Double, dec: Double,
        latitude: Double, longitude: Double,
        date: Date
    ) -> (altitude: Double, azimuth: Double) {
        let localST = lst(date, longitude: longitude)
        var ha = (localST - ra) * 15.0 // hour angle in degrees
        ha = ha.truncatingRemainder(dividingBy: 360)
        if ha < 0 { ha += 360 }

        let sinAlt = sin(rad(dec)) * sin(rad(latitude))
            + cos(rad(dec)) * cos(rad(latitude)) * cos(rad(ha))
        let altitude = deg(asin(max(-1, min(1, sinAlt))))

        let cosA = (sin(rad(dec)) - sin(rad(altitude)) * sin(rad(latitude)))
            / (cos(rad(altitude)) * cos(rad(latitude)))
        var azimuth = deg(acos(max(-1, min(1, cosA))))
        if sin(rad(ha)) > 0 { azimuth = 360 - azimuth }

        return (altitude, azimuth)
    }

    /// Stereographic projection from (altitude, azimuth) to (x, y) in [-1, 1].
    /// Projects the visible hemisphere (alt >= 0) onto a unit disk.
    /// Center = zenith, edge = horizon.
    static func stereographicProject(altitude: Double, azimuth: Double) -> (x: Double, y: Double)? {
        guard altitude >= 0 else { return nil }
        let r = cos(rad(altitude)) / (1.0 + sin(rad(altitude)))
        let x = r * sin(rad(azimuth))
        let y = -r * cos(rad(azimuth)) // negative so north is up
        return (x, y)
    }
}
