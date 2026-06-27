import UIKit
import CoreLocation

enum StarChartRenderer {
    /// Render a star chart for the given location and time.
    /// Returns a full-screen image suitable for use as a lock screen wallpaper.
    static func render(
        location: CLLocation,
        date: Date,
        size: CGSize = CGSize(width: 1290, height: 2796) // iPhone 15 Pro Max
    ) -> UIImage {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let ctx = context.cgContext
            let cx = size.width / 2
            let cy = size.height * 0.46
            let radius = min(size.width, size.height) * 0.42

            drawBackground(ctx: ctx, size: size)
            drawGridLines(ctx: ctx, cx: cx, cy: cy, radius: radius, lat: lat, lon: lon, date: date)
            drawConstellationLines(ctx: ctx, cx: cx, cy: cy, radius: radius, lat: lat, lon: lon, date: date)
            drawStars(ctx: ctx, cx: cx, cy: cy, radius: radius, lat: lat, lon: lon, date: date)
            drawCardinalLabels(ctx: ctx, cx: cx, cy: cy, radius: radius)
            drawInfoText(ctx: ctx, size: size, lat: lat, lon: lon, date: date)
        }
    }

    private static func drawBackground(ctx: CGContext, size: CGSize) {
        let colors = [
            UIColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1).cgColor,
            UIColor(red: 0.04, green: 0.04, blue: 0.14, alpha: 1).cgColor,
            UIColor(red: 0.02, green: 0.02, blue: 0.06, alpha: 1).cgColor,
        ]
        let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: [0, 0.5, 1]
        )!
        ctx.drawLinearGradient(gradient,
            start: CGPoint(x: size.width / 2, y: 0),
            end: CGPoint(x: size.width / 2, y: size.height),
            options: [])
    }

    private static func drawGridLines(ctx: CGContext, cx: CGFloat, cy: CGFloat, radius: CGFloat,
                                       lat: Double, lon: Double, date: Date) {
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.06).cgColor)
        ctx.setLineWidth(0.8)

        // Altitude circles at 30° and 60°
        for alt in stride(from: 30.0, through: 60.0, by: 30.0) {
            let r = CGFloat(cos(alt * .pi / 180) / (1.0 + sin(alt * .pi / 180))) * radius
            ctx.strokeEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        }

        // Horizon circle
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.12).cgColor)
        ctx.setLineWidth(1.0)
        ctx.strokeEllipse(in: CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2))
    }

    private static func projectStar(_ star: CatalogStar, cx: CGFloat, cy: CGFloat, radius: CGFloat,
                                     lat: Double, lon: Double, date: Date) -> CGPoint? {
        let hor = CelestialMath.equatorialToHorizontal(
            ra: star.ra, dec: star.dec,
            latitude: lat, longitude: lon, date: date
        )
        guard let proj = CelestialMath.stereographicProject(altitude: hor.altitude, azimuth: hor.azimuth) else {
            return nil
        }
        return CGPoint(x: cx + CGFloat(proj.x) * radius, y: cy + CGFloat(proj.y) * radius)
    }

    private static func drawConstellationLines(ctx: CGContext, cx: CGFloat, cy: CGFloat, radius: CGFloat,
                                                lat: Double, lon: Double, date: Date) {
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.12).cgColor)
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
                                   lat: Double, lon: Double, date: Date) {
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
                let glowColor = UIColor.white.withAlphaComponent(alpha * 0.15).cgColor
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
            let color: UIColor
            if star.magnitude < 0 {
                color = UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: alpha)
            } else if star.magnitude < 1 {
                color = UIColor(red: 0.9, green: 0.92, blue: 1.0, alpha: alpha)
            } else {
                color = UIColor.white.withAlphaComponent(alpha)
            }
            ctx.setFillColor(color.cgColor)
            ctx.fillEllipse(in: CGRect(x: pt.x - dotRadius, y: pt.y - dotRadius,
                                     width: dotRadius * 2, height: dotRadius * 2))

            // Name label for brightest named stars
            if let name = star.name, star.magnitude < 1.2 {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 13, weight: .light),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.5),
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

    private static func drawCardinalLabels(ctx: CGContext, cx: CGFloat, cy: CGFloat, radius: CGFloat) {
        let labels: [(String, CGFloat)] = [("N", 0), ("E", 90), ("S", 180), ("W", 270)]
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.4),
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

    private static func drawInfoText(ctx: CGContext, size: CGSize, lat: Double, lon: Double, date: Date) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, yyyy  h:mm a"

        let timeStr = formatter.string(from: date)
        let coordStr = String(format: "%.2f°%@  %.2f°%@",
                              abs(lat), lat >= 0 ? "N" : "S",
                              abs(lon), lon >= 0 ? "E" : "W")

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 13, weight: .light),
            .foregroundColor: UIColor.white.withAlphaComponent(0.35),
        ]
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .light),
            .foregroundColor: UIColor.white.withAlphaComponent(0.5),
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
}
