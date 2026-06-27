import UIKit
import CoreLocation

enum StarChartRenderer {
    /// Render a star chart for the given location and time.
    /// Returns a full-screen image suitable for use as a lock screen wallpaper.
    static func render(
        location: CLLocation,
        date: Date,
        size: CGSize = CGSize(width: 1290, height: 2796), // iPhone 15 Pro Max
        theme: StarChartTheme = .load()
    ) -> UIImage {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let ctx = context.cgContext
            let cx = size.width / 2
            let cy = size.height * 0.46
            let radius = min(size.width, size.height) * 0.42

            drawBackground(ctx: ctx, size: size, theme: theme)
            drawGridLines(ctx: ctx, cx: cx, cy: cy, radius: radius, theme: theme)
            drawEcliptic(ctx: ctx, cx: cx, cy: cy, radius: radius, lat: lat, lon: lon, date: date, theme: theme)
            drawConstellationLines(ctx: ctx, cx: cx, cy: cy, radius: radius, lat: lat, lon: lon, date: date, theme: theme)
            drawStars(ctx: ctx, cx: cx, cy: cy, radius: radius, lat: lat, lon: lon, date: date, theme: theme)
            drawSun(ctx: ctx, cx: cx, cy: cy, radius: radius, lat: lat, lon: lon, date: date, theme: theme)
            drawMoon(ctx: ctx, cx: cx, cy: cy, radius: radius, lat: lat, lon: lon, date: date, theme: theme)
            drawCardinalLabels(ctx: ctx, cx: cx, cy: cy, radius: radius, theme: theme)
            drawInfoText(ctx: ctx, size: size, lat: lat, lon: lon, date: date, theme: theme)
            if theme.showDebugTimestamp {
                drawDebugTimestamp(ctx: ctx, size: size, date: date)
            }
        }
    }

    private static func ui(_ c: RGBAColor, alpha mult: Double = 1) -> UIColor {
        UIColor(red: c.r, green: c.g, blue: c.b, alpha: c.a * mult)
    }

    private static func drawBackground(ctx: CGContext, size: CGSize, theme: StarChartTheme) {
        let c = theme.background
        let top = UIColor(red: c.r, green: c.g, blue: c.b, alpha: 1).cgColor
        let mid = UIColor(red: min(c.r * 1.4 + 0.01, 1),
                          green: min(c.g * 1.4 + 0.01, 1),
                          blue: min(c.b * 1.4 + 0.04, 1), alpha: 1).cgColor
        let bottom = UIColor(red: c.r * 0.7, green: c.g * 0.7, blue: c.b * 0.7, alpha: 1).cgColor
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [top, mid, bottom] as CFArray,
            locations: [0, 0.5, 1]
        )!
        ctx.drawLinearGradient(gradient,
            start: CGPoint(x: size.width / 2, y: 0),
            end: CGPoint(x: size.width / 2, y: size.height),
            options: [])
    }

    private static func drawGridLines(ctx: CGContext, cx: CGFloat, cy: CGFloat, radius: CGFloat,
                                       theme: StarChartTheme) {
        // Altitude circles at 30° and 60° (fainter than the horizon)
        ctx.setStrokeColor(ui(theme.grid, alpha: 0.5).cgColor)
        ctx.setLineWidth(0.8)
        for alt in stride(from: 30.0, through: 60.0, by: 30.0) {
            let r = CGFloat(cos(alt * .pi / 180) / (1.0 + sin(alt * .pi / 180))) * radius
            ctx.strokeEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        }

        // Horizon circle
        ctx.setStrokeColor(ui(theme.grid).cgColor)
        ctx.setLineWidth(1.0)
        ctx.strokeEllipse(in: CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2))
    }

    private static func projectEquatorial(ra: Double, dec: Double, cx: CGFloat, cy: CGFloat, radius: CGFloat,
                                          lat: Double, lon: Double, date: Date) -> CGPoint? {
        let hor = CelestialMath.equatorialToHorizontal(
            ra: ra, dec: dec, latitude: lat, longitude: lon, date: date
        )
        guard let proj = CelestialMath.stereographicProject(altitude: hor.altitude, azimuth: hor.azimuth) else {
            return nil
        }
        return CGPoint(x: cx + CGFloat(proj.x) * radius, y: cy + CGFloat(proj.y) * radius)
    }

    private static func projectStar(_ star: CatalogStar, cx: CGFloat, cy: CGFloat, radius: CGFloat,
                                     lat: Double, lon: Double, date: Date) -> CGPoint? {
        projectEquatorial(ra: star.ra, dec: star.dec, cx: cx, cy: cy, radius: radius, lat: lat, lon: lon, date: date)
    }

    private static func drawEcliptic(ctx: CGContext, cx: CGFloat, cy: CGFloat, radius: CGFloat,
                                     lat: Double, lon: Double, date: Date, theme: StarChartTheme) {
        ctx.setStrokeColor(ui(theme.ecliptic).cgColor)
        ctx.setLineWidth(1.5)

        var started = false
        var eclLon = 0.0
        while eclLon <= 360.0 {
            let eq = CelestialMath.eclipticToEquatorial(lon: eclLon, lat: 0, date: date)
            if let pt = projectEquatorial(ra: eq.ra, dec: eq.dec, cx: cx, cy: cy, radius: radius,
                                          lat: lat, lon: lon, date: date) {
                if started { ctx.addLine(to: pt) } else { ctx.move(to: pt); started = true }
            } else {
                started = false  // below horizon: break the path
            }
            eclLon += 2
        }
        ctx.strokePath()
    }

    private static func drawSun(ctx: CGContext, cx: CGFloat, cy: CGFloat, radius: CGFloat,
                                lat: Double, lon: Double, date: Date, theme: StarChartTheme) {
        let eq = CelestialMath.sunEquatorial(date)
        guard let pt = projectEquatorial(ra: eq.ra, dec: eq.dec, cx: cx, cy: cy, radius: radius,
                                         lat: lat, lon: lon, date: date) else { return }
        let r: CGFloat = 22

        // glow
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [ui(theme.sun, alpha: 0.6).cgColor, UIColor.clear.cgColor] as CFArray,
            locations: [0, 1]
        )!
        ctx.saveGState()
        ctx.drawRadialGradient(gradient, startCenter: pt, startRadius: 0,
                               endCenter: pt, endRadius: r * 3, options: [])
        ctx.restoreGState()

        ctx.setFillColor(ui(theme.sun).cgColor)
        ctx.fillEllipse(in: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2))
        drawLabel("Sun", at: pt, offset: r + 6, color: ui(theme.sun))
    }

    private static func drawMoon(ctx: CGContext, cx: CGFloat, cy: CGFloat, radius: CGFloat,
                                 lat: Double, lon: Double, date: Date, theme: StarChartTheme) {
        let eq = CelestialMath.moonEquatorial(date)
        guard let pt = projectEquatorial(ra: eq.ra, dec: eq.dec, cx: cx, cy: cy, radius: radius,
                                         lat: lat, lon: lon, date: date) else { return }
        let r: CGFloat = 18
        let illum = CelestialMath.moonIllumination(date)

        // Dark disc base
        ctx.setFillColor(ui(theme.moon, alpha: 0.18).cgColor)
        ctx.fillEllipse(in: CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2))

        // Lit portion bounded by the terminator ellipse
        let sign: CGFloat = illum.waxing ? 1 : -1
        let tx = CGFloat(1 - 2 * illum.fraction) * r
        var pts: [CGPoint] = []
        let n = 40
        for k in 0...n { // bright limb (semicircle on the lit side)
            let a = -CGFloat.pi / 2 + CGFloat.pi * CGFloat(k) / CGFloat(n)
            pts.append(CGPoint(x: pt.x + sign * r * cos(a), y: pt.y + r * sin(a)))
        }
        for k in 0...n { // terminator (half-ellipse) back to the top
            let a = CGFloat.pi / 2 - CGFloat.pi * CGFloat(k) / CGFloat(n)
            pts.append(CGPoint(x: pt.x + sign * tx * cos(a), y: pt.y + r * sin(a)))
        }
        ctx.beginPath()
        ctx.addLines(between: pts)
        ctx.closePath()
        ctx.setFillColor(ui(theme.moon).cgColor)
        ctx.fillPath()

        drawLabel("Moon", at: pt, offset: r + 6, color: ui(theme.moon))
    }

    private static func drawLabel(_ text: String, at pt: CGPoint, offset: CGFloat, color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15, weight: .medium),
            .foregroundColor: color,
        ]
        let s = NSString(string: text)
        let sz = s.size(withAttributes: attrs)
        s.draw(at: CGPoint(x: pt.x + offset, y: pt.y - sz.height / 2), withAttributes: attrs)
    }

    private static func drawConstellationLines(ctx: CGContext, cx: CGFloat, cy: CGFloat, radius: CGFloat,
                                                lat: Double, lon: Double, date: Date, theme: StarChartTheme) {
        ctx.setStrokeColor(ui(theme.constellation).cgColor)
        ctx.setLineWidth(0.8)

        let stars = StarCatalog.stars
        for line in StarCatalog.constellationLines {
            guard line.from < stars.count, line.to < stars.count else { continue }
            guard let p1 = projectStar(stars[line.from], cx: cx, cy: cy, radius: radius, lat: lat, lon: lon, date: date),
                  let p2 = projectStar(stars[line.to], cx: cx, cy: cy, radius: radius, lat: lat, lon: lon, date: date)
            else { continue }
            ctx.move(to: p1)
            ctx.addLine(to: p2)
            ctx.strokePath()
        }
    }

    private static func drawStars(ctx: CGContext, cx: CGFloat, cy: CGFloat, radius: CGFloat,
                                   lat: Double, lon: Double, date: Date, theme: StarChartTheme) {
        let stars = StarCatalog.stars

        for star in stars {
            guard let pt = projectStar(star, cx: cx, cy: cy, radius: radius, lat: lat, lon: lon, date: date) else {
                continue
            }

            let dotRadius = starRadius(magnitude: star.magnitude)
            let alpha = starAlpha(magnitude: star.magnitude)

            // Glow for bright stars
            if star.magnitude < 1.5 {
                let glowRadius = dotRadius * 4
                let glowColor = ui(theme.stars, alpha: Double(alpha) * 0.15).cgColor
                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: [glowColor, UIColor.clear.cgColor] as CFArray,
                    locations: [0, 1]
                )!
                ctx.saveGState()
                ctx.drawRadialGradient(gradient,
                    startCenter: pt, startRadius: 0,
                    endCenter: pt, endRadius: glowRadius,
                    options: [])
                ctx.restoreGState()
            }

            // Star dot
            ctx.setFillColor(ui(theme.stars, alpha: Double(alpha)).cgColor)
            ctx.fillEllipse(in: CGRect(x: pt.x - dotRadius, y: pt.y - dotRadius,
                                       width: dotRadius * 2, height: dotRadius * 2))

            // Name label for brightest named stars
            if let name = star.name, star.magnitude < 1.2 {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13, weight: .light),
                    .foregroundColor: ui(theme.text),
                ]
                let str = NSString(string: name)
                let labelSize = str.size(withAttributes: attrs)
                str.draw(at: CGPoint(x: pt.x + dotRadius + 4, y: pt.y - labelSize.height / 2), withAttributes: attrs)
            }
        }
    }

    private static func starRadius(magnitude: Double) -> CGFloat {
        CGFloat(max(1.2, 5.0 - magnitude * 0.9))
    }

    private static func starAlpha(magnitude: Double) -> CGFloat {
        CGFloat(max(0.35, min(1.0, 1.0 - (magnitude - (-1.5)) / 6.0)))
    }

    private static func drawCardinalLabels(ctx: CGContext, cx: CGFloat, cy: CGFloat, radius: CGFloat,
                                            theme: StarChartTheme) {
        let labels: [(String, CGFloat)] = [("N", 0), ("E", 90), ("S", 180), ("W", 270)]
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: ui(theme.text),
        ]

        for (label, azDeg) in labels {
            let azRad = azDeg * .pi / 180
            let r = radius + 24
            let x = cx + r * sin(azRad)
            let y = cy - r * cos(azRad)
            let str = NSString(string: label)
            let size = str.size(withAttributes: attrs)
            str.draw(at: CGPoint(x: x - size.width / 2, y: y - size.height / 2), withAttributes: attrs)
        }
    }

    private static func drawInfoText(ctx: CGContext, size: CGSize, lat: Double, lon: Double, date: Date,
                                      theme: StarChartTheme) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, yyyy  h:mm a"

        let timeStr = formatter.string(from: date)
        let coordStr = String(format: "%.2f°%@  %.2f°%@",
                              abs(lat), lat >= 0 ? "N" : "S",
                              abs(lon), lon >= 0 ? "E" : "W")

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 13, weight: .light),
            .foregroundColor: ui(theme.text, alpha: 0.7),
        ]
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .light),
            .foregroundColor: ui(theme.text),
            .kern: 3.0 as NSNumber,
        ]

        let y = size.height - 140
        NSString(string: "STAR CHART").draw(
            at: CGPoint(x: size.width / 2 - 50, y: y), withAttributes: titleAttrs)
        NSString(string: timeStr).draw(
            at: CGPoint(x: size.width / 2 - 100, y: y + 30), withAttributes: attrs)
        NSString(string: coordStr).draw(
            at: CGPoint(x: size.width / 2 - 80, y: y + 50), withAttributes: attrs)
    }

    private static func drawDebugTimestamp(ctx: CGContext, size: CGSize, date: Date) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm:ss"

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 96, weight: .bold),
            .foregroundColor: UIColor.white.withAlphaComponent(0.85),
        ]
        let str = NSString(string: formatter.string(from: date))
        let textSize = str.size(withAttributes: attrs)
        str.draw(at: CGPoint(x: (size.width - textSize.width) / 2, y: size.height * 0.66),
                 withAttributes: attrs)
    }
}
