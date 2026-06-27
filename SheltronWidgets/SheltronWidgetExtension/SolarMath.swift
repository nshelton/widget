import Foundation

enum SolarMath {
    private static func rad(_ d: Double) -> Double { d * .pi / 180 }
    private static func deg(_ r: Double) -> Double { r * 180 / .pi }

    private static func julianDay(_ date: Date) -> Double {
        date.timeIntervalSince1970 / 86400.0 + 2440587.5
    }

    /// Declination (deg) and equation of time (minutes) for a Julian Day.
    private static func params(_ jd: Double) -> (decl: Double, eqTime: Double) {
        let jc = (jd - 2451545.0) / 36525.0
        let l0 = (280.46646 + jc * (36000.76983 + jc * 0.0003032)).truncatingRemainder(dividingBy: 360)
        let m = 357.52911 + jc * (35999.05029 - 0.0001537 * jc)
        let e = 0.016708634 - jc * (0.000042037 + 0.0000001267 * jc)
        let c = sin(rad(m)) * (1.914602 - jc * (0.004817 + 0.000014 * jc))
              + sin(rad(2 * m)) * (0.019993 - 0.000101 * jc)
              + sin(rad(3 * m)) * 0.000289
        let trueLong = l0 + c
        let lambda = trueLong - 0.00569 - 0.00478 * sin(rad(125.04 - 1934.136 * jc))
        let e0 = 23 + (26 + (21.448 - jc * (46.815 + jc * (0.00059 - jc * 0.001813))) / 60) / 60
        let eCorr = e0 + 0.00256 * cos(rad(125.04 - 1934.136 * jc))
        let decl = deg(asin(sin(rad(eCorr)) * sin(rad(lambda))))
        let y = pow(tan(rad(eCorr / 2)), 2)
        let eqTime = 4 * deg(
            y * sin(2 * rad(l0))
            - 2 * e * sin(rad(m))
            + 4 * e * y * sin(rad(m)) * cos(2 * rad(l0))
            - 0.5 * y * y * sin(4 * rad(l0))
            - 1.25 * e * e * sin(2 * rad(m))
        )
        return (decl, eqTime)
    }

    static func sunElevation(date: Date, latitude: Double, longitude: Double) -> Double {
        let jd = julianDay(date)
        let p = params(jd)
        let minutesUTC = (jd + 0.5).truncatingRemainder(dividingBy: 1) * 1440
        var trueSolarTime = (minutesUTC + p.eqTime + 4 * longitude).truncatingRemainder(dividingBy: 1440)
        if trueSolarTime < 0 { trueSolarTime += 1440 }
        var hourAngle = trueSolarTime / 4 - 180
        if hourAngle < -180 { hourAngle += 360 }
        let cosZenith = sin(rad(latitude)) * sin(rad(p.decl))
            + cos(rad(latitude)) * cos(rad(p.decl)) * cos(rad(hourAngle))
        let zenith = deg(acos(max(-1, min(1, cosZenith))))
        return 90 - zenith
    }

    static func sunEvents(date: Date, latitude: Double, longitude: Double) -> (sunrise: Date?, sunset: Date?) {
        // Compute at local solar noon for stable declination/eqTime.
        let noonJD = julianDay(date)
        let p = params(noonJD)
        let cosH = cos(rad(90.0)) / (cos(rad(latitude)) * cos(rad(p.decl)))
                 - tan(rad(latitude)) * tan(rad(p.decl))
        guard cosH >= -1, cosH <= 1 else { return (nil, nil) } // polar day/night
        let haSunrise = deg(acos(cosH))
        let solarNoonUTCmin = 720 - 4 * longitude - p.eqTime
        let utcMidnight = Calendar.utc.startOfDay(for: date)
        func dateAt(_ minutes: Double) -> Date { utcMidnight.addingTimeInterval(minutes * 60) }
        return (dateAt(solarNoonUTCmin - 4 * haSunrise),
                dateAt(solarNoonUTCmin + 4 * haSunrise))
    }

    static func elevationSamples(date: Date, latitude: Double, longitude: Double, interval: TimeInterval) -> [(date: Date, elevation: Double)] {
        let localStart = Calendar.current.startOfDay(for: date)
        var out: [(Date, Double)] = []
        var t = localStart
        let end = localStart.addingTimeInterval(86400)
        while t <= end {
            out.append((t, sunElevation(date: t, latitude: latitude, longitude: longitude)))
            t = t.addingTimeInterval(interval)
        }
        return out
    }
}

extension Calendar {
    static let utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }()
}
