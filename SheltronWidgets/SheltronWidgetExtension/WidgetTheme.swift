import SwiftUI
import UIKit

// Codable RGBA so SwiftUI Colors can persist to the shared App Group.
struct RGBAColor: Codable, Equatable {
    var r: Double, g: Double, b: Double, a: Double

    init(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) {
        self.r = r; self.g = g; self.b = b; self.a = a
    }
    init(_ color: Color) {
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 0
        UIColor(color).getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
        r = Double(rr); g = Double(gg); b = Double(bb); a = Double(aa)
    }
    var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: a) }
}

// All configurable widget colors. Defaults = the current brighter palette.
struct WidgetTheme: Codable, Equatable {
    var background = RGBAColor(0, 0, 0, 1)
    var sunLine    = RGBAColor(1.0, 0.76, 0.32)
    var dayFill    = RGBAColor(1.0, 0.76, 0.32, 0.32)
    var nightFill  = RGBAColor(0.48, 0.66, 1.0, 0.30)
    var tempLine   = RGBAColor(1.0, 0.76, 0.32)
    var nowLine    = RGBAColor(1.0, 0.36, 0.54)
    var horizon    = RGBAColor(1, 1, 1, 0.28)
    var text       = RGBAColor(1, 1, 1, 0.65)

    static let suiteName = "group.sheltron.SheltronWidgets"
    static let key = "widgetTheme"

    static func load() -> WidgetTheme {
        guard let data = UserDefaults(suiteName: suiteName)?.data(forKey: key),
              let theme = try? JSONDecoder().decode(WidgetTheme.self, from: data)
        else { return WidgetTheme() }
        return theme
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults(suiteName: WidgetTheme.suiteName)?.set(data, forKey: WidgetTheme.key)
    }
}
