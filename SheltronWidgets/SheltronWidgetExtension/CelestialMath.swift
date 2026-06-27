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

    // MARK: - Ecliptic, Sun, Moon

    private static func julianDay(_ date: Date) -> Double {
        date.timeIntervalSince1970 / 86400.0 + 2440587.5
    }

    private static func norm360(_ x: Double) -> Double {
        var v = x.truncatingRemainder(dividingBy: 360)
        if v < 0 { v += 360 }
        return v
    }

    /// Mean obliquity of the ecliptic in degrees.
    static func obliquity(_ date: Date) -> Double {
        let t = (julianDay(date) - 2451545.0) / 36525.0
        return 23.4392911 - 0.0130042 * t
    }

    /// Convert ecliptic (lon, lat degrees) to equatorial (RA hours, Dec degrees).
    static func eclipticToEquatorial(lon: Double, lat: Double, date: Date) -> (ra: Double, dec: Double) {
        let e = rad(obliquity(date))
        let l = rad(lon), b = rad(lat)
        let sinDec = sin(b) * cos(e) + cos(b) * sin(e) * sin(l)
        let dec = asin(max(-1, min(1, sinDec)))
        var ra = deg(atan2(sin(l) * cos(e) - tan(b) * sin(e), cos(l)))
        if ra < 0 { ra += 360 }
        return (ra / 15.0, deg(dec))
    }

    /// Sun's apparent ecliptic longitude in degrees (low precision).
    static func sunEclipticLongitude(_ date: Date) -> Double {
        let n = julianDay(date) - 2451545.0
        let L = norm360(280.460 + 0.9856474 * n)
        let g = rad(norm360(357.528 + 0.9856003 * n))
        return norm360(L + 1.915 * sin(g) + 0.020 * sin(2 * g))
    }

    static func sunEquatorial(_ date: Date) -> (ra: Double, dec: Double) {
        eclipticToEquatorial(lon: sunEclipticLongitude(date), lat: 0, date: date)
    }

    /// Moon's geocentric ecliptic position (lon, lat degrees), low precision (~few arcmin).
    static func moonEclipticPosition(_ date: Date) -> (lon: Double, lat: Double) {
        let d = julianDay(date) - 2451543.5

        let Nd = norm360(125.1228 - 0.0529538083 * d)  // ascending node
        let inc = rad(5.1454)                          // inclination
        let wd = norm360(318.0634 + 0.1643573223 * d)  // arg of perigee
        let e = 0.054900
        let Md = norm360(115.3654 + 13.0649929509 * d) // mean anomaly

        // Eccentric anomaly (degrees), Newton iteration
        var E = Md + deg(e) * sin(rad(Md)) * (1 + e * cos(rad(Md)))
        for _ in 0..<3 {
            E = E - (E - deg(e) * sin(rad(E)) - Md) / (1 - e * cos(rad(E)))
        }

        let xv = cos(rad(E)) - e
        let yv = sqrt(1 - e * e) * sin(rad(E))
        let v = deg(atan2(yv, xv))                     // true anomaly
        let r = sqrt(xv * xv + yv * yv) * 60.2666      // distance (Earth radii)

        let N = rad(Nd), vw = rad(v + wd)
        let xec = r * (cos(N) * cos(vw) - sin(N) * sin(vw) * cos(inc))
        let yec = r * (sin(N) * cos(vw) + cos(N) * sin(vw) * cos(inc))
        let zec = r * sin(vw) * sin(inc)

        var lon = norm360(deg(atan2(yec, xec)))
        var lat = deg(atan2(zec, sqrt(xec * xec + yec * yec)))

        // Main periodic perturbations (Schlyter)
        let ws = 282.9404 + 4.70935e-5 * d
        let Ms = norm360(356.0470 + 0.9856002585 * d)  // sun mean anomaly
        let Ls = norm360(ws + Ms)                      // sun mean longitude
        let Lm = norm360(Nd + wd + Md)                 // moon mean longitude
        let D = norm360(Lm - Ls)                       // mean elongation
        let F = norm360(Lm - Nd)                       // argument of latitude

        lon += -1.274 * sin(rad(Md - 2 * D))
            +   0.658 * sin(rad(2 * D))
            -   0.186 * sin(rad(Ms))
            -   0.059 * sin(rad(2 * Md - 2 * D))
            -   0.057 * sin(rad(Md - 2 * D + Ms))
            +   0.053 * sin(rad(Md + 2 * D))
            +   0.046 * sin(rad(2 * D - Ms))
            +   0.041 * sin(rad(Md - Ms))
            -   0.035 * sin(rad(D))
            -   0.031 * sin(rad(Md + Ms))
            -   0.015 * sin(rad(2 * F - 2 * D))
            +   0.011 * sin(rad(Md - 4 * D))

        lat += -0.173 * sin(rad(F - 2 * D))
            -   0.055 * sin(rad(Md - F - 2 * D))
            -   0.046 * sin(rad(Md + F - 2 * D))
            +   0.033 * sin(rad(F + 2 * D))
            +   0.017 * sin(rad(2 * Md + F))

        return (norm360(lon), lat)
    }

    static func moonEquatorial(_ date: Date) -> (ra: Double, dec: Double) {
        let p = moonEclipticPosition(date)
        return eclipticToEquatorial(lon: p.lon, lat: p.lat, date: date)
    }

    /// Illuminated fraction [0,1] and whether the Moon is waxing (lit limb leads).
    static func moonIllumination(_ date: Date) -> (fraction: Double, waxing: Bool) {
        let diff = norm360(moonEclipticPosition(date).lon - sunEclipticLongitude(date))
        let fraction = (1 - cos(rad(diff))) / 2
        return (fraction, diff < 180)
    }
}
