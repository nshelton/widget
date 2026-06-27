import Foundation

// The configurable colors for the star chart wallpaper. Separate from WidgetTheme.
// Reuses RGBAColor (defined in WidgetTheme.swift). Persisted in the shared App Group.
struct StarChartTheme: Codable, Equatable {
    var background    = RGBAColor(0.03, 0.03, 0.10, 1)  // gradient base
    var stars         = RGBAColor(0.95, 0.95, 1.0, 1)   // dot + glow
    var constellation = RGBAColor(1, 1, 1, 0.12)        // constellation lines
    var grid          = RGBAColor(1, 1, 1, 0.12)        // altitude circles + horizon
    var text          = RGBAColor(1, 1, 1, 0.5)         // labels + info text
    var ecliptic      = RGBAColor(0.95, 0.65, 0.25, 0.5) // ecliptic line
    var sun           = RGBAColor(1.0, 0.82, 0.30, 1)   // sun disc + glow
    var moon          = RGBAColor(0.85, 0.87, 0.95, 1)  // moon disc
    var showDebugTimestamp = false

    init() {}

    // Tolerant decode: missing keys (e.g. older saved JSON) fall back to defaults
    // instead of failing, so adding slots never discards a saved palette.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = StarChartTheme()
        background = try c.decodeIfPresent(RGBAColor.self, forKey: .background) ?? d.background
        stars = try c.decodeIfPresent(RGBAColor.self, forKey: .stars) ?? d.stars
        constellation = try c.decodeIfPresent(RGBAColor.self, forKey: .constellation) ?? d.constellation
        grid = try c.decodeIfPresent(RGBAColor.self, forKey: .grid) ?? d.grid
        text = try c.decodeIfPresent(RGBAColor.self, forKey: .text) ?? d.text
        ecliptic = try c.decodeIfPresent(RGBAColor.self, forKey: .ecliptic) ?? d.ecliptic
        sun = try c.decodeIfPresent(RGBAColor.self, forKey: .sun) ?? d.sun
        moon = try c.decodeIfPresent(RGBAColor.self, forKey: .moon) ?? d.moon
        showDebugTimestamp = try c.decodeIfPresent(Bool.self, forKey: .showDebugTimestamp) ?? d.showDebugTimestamp
    }

    static let key = "starChartTheme"

    static func load() -> StarChartTheme {
        guard let data = UserDefaults(suiteName: WidgetTheme.suiteName)?.data(forKey: key),
              let theme = try? JSONDecoder().decode(StarChartTheme.self, from: data)
        else { return StarChartTheme() }
        return theme
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults(suiteName: WidgetTheme.suiteName)?.set(data, forKey: StarChartTheme.key)
    }
}
