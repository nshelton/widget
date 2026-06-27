import Foundation

// The configurable colors for the star chart wallpaper. Separate from WidgetTheme.
// Reuses RGBAColor (defined in WidgetTheme.swift). Persisted in the shared App Group.
struct StarChartTheme: Codable, Equatable {
    var background    = RGBAColor(0.03, 0.03, 0.10, 1)  // gradient base
    var stars         = RGBAColor(0.95, 0.95, 1.0, 1)   // dot + glow
    var constellation = RGBAColor(1, 1, 1, 0.12)        // constellation lines
    var grid          = RGBAColor(1, 1, 1, 0.12)        // altitude circles + horizon
    var text          = RGBAColor(1, 1, 1, 0.5)         // labels + info text
    var showDebugTimestamp = false

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
