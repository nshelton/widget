import XCTest

final class StarChartThemeTests: XCTestCase {
    func test_codable_round_trip_preserves_all_fields() throws {
        var theme = StarChartTheme()
        theme.background = RGBAColor(0.1, 0.2, 0.3, 0.9)
        theme.stars = RGBAColor(0.8, 0.85, 1.0, 1.0)
        theme.constellation = RGBAColor(0.5, 0.5, 0.5, 0.4)
        theme.grid = RGBAColor(0.2, 0.2, 0.2, 0.3)
        theme.text = RGBAColor(1, 1, 1, 0.7)
        theme.showDebugTimestamp = true

        let data = try JSONEncoder().encode(theme)
        let decoded = try JSONDecoder().decode(StarChartTheme.self, from: data)

        XCTAssertEqual(decoded, theme)
    }
}
