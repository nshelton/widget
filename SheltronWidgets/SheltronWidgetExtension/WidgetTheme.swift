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

// The configurable colors for one look.
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

    // The widget + chart read this — it resolves to the selected palette.
    static func load() -> WidgetTheme { PaletteStore.load().selected }
}

// Preset looks.
extension WidgetTheme {
    static let daytime = WidgetTheme()

    static let sunset = WidgetTheme(
        background: RGBAColor(0.06, 0.01, 0.06, 1),
        sunLine:    RGBAColor(1.0, 0.52, 0.20),
        dayFill:    RGBAColor(1.0, 0.45, 0.15, 0.35),
        nightFill:  RGBAColor(0.42, 0.20, 0.62, 0.35),
        tempLine:   RGBAColor(1.0, 0.30, 0.46),
        nowLine:    RGBAColor(1.0, 0.85, 0.40),
        horizon:    RGBAColor(1.0, 0.80, 0.70, 0.30),
        text:       RGBAColor(1.0, 0.90, 0.84, 0.70)
    )

    static let matrix = WidgetTheme(
        background: RGBAColor(0, 0, 0, 1),
        sunLine:    RGBAColor(0.20, 1.0, 0.35),
        dayFill:    RGBAColor(0.20, 1.0, 0.35, 0.22),
        nightFill:  RGBAColor(0.10, 0.50, 0.20, 0.30),
        tempLine:   RGBAColor(0.55, 1.0, 0.45),
        nowLine:    RGBAColor(0.75, 1.0, 0.20),
        horizon:    RGBAColor(0.20, 1.0, 0.35, 0.30),
        text:       RGBAColor(0.45, 1.0, 0.45, 0.70)
    )

    static let mono = WidgetTheme(
        background: RGBAColor(0, 0, 0, 1),
        sunLine:    RGBAColor(1, 1, 1, 0.90),
        dayFill:    RGBAColor(1, 1, 1, 0.16),
        nightFill:  RGBAColor(0.6, 0.6, 0.6, 0.22),
        tempLine:   RGBAColor(1, 1, 1, 0.95),
        nowLine:    RGBAColor(1, 1, 1, 1.0),
        horizon:    RGBAColor(1, 1, 1, 0.30),
        text:       RGBAColor(1, 1, 1, 0.60)
    )
}

struct Palette: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var theme: WidgetTheme
}

// The on-device collection of palettes + which one is active.
struct PaletteStore: Codable, Equatable {
    var palettes: [Palette]
    var selectedID: UUID

    var selectedIndex: Int { palettes.firstIndex { $0.id == selectedID } ?? 0 }
    var selected: WidgetTheme { palettes.indices.contains(selectedIndex) ? palettes[selectedIndex].theme : WidgetTheme() }

    static let key = "paletteStore"

    static func makeDefault() -> PaletteStore {
        func id(_ s: String) -> UUID { UUID(uuidString: s)! }
        let presets = [
            Palette(id: id("00000000-0000-0000-0000-000000000001"), name: "Daytime", theme: .daytime),
            Palette(id: id("00000000-0000-0000-0000-000000000002"), name: "Sunset", theme: .sunset),
            Palette(id: id("00000000-0000-0000-0000-000000000003"), name: "Matrix", theme: .matrix),
            Palette(id: id("00000000-0000-0000-0000-000000000004"), name: "Mono", theme: .mono),
        ]
        return PaletteStore(palettes: presets, selectedID: presets[0].id)
    }

    static func load() -> PaletteStore {
        guard let data = UserDefaults(suiteName: WidgetTheme.suiteName)?.data(forKey: key),
              let store = try? JSONDecoder().decode(PaletteStore.self, from: data),
              !store.palettes.isEmpty
        else { return makeDefault() }
        return store
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults(suiteName: WidgetTheme.suiteName)?.set(data, forKey: PaletteStore.key)
    }
}
