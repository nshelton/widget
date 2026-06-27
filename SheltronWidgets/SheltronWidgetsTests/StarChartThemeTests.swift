import XCTest

final class StarChartThemeTests: XCTestCase {
    func test_codable_round_trip_preserves_all_fields() throws {
        var theme = StarChartTheme()
        theme.background = RGBAColor(0.1, 0.2, 0.3, 0.9)
        theme.stars = RGBAColor(0.8, 0.85, 1.0, 1.0)
        theme.constellation = RGBAColor(0.5, 0.5, 0.5, 0.4)
        theme.grid = RGBAColor(0.2, 0.2, 0.2, 0.3)
        theme.text = RGBAColor(1, 1, 1, 0.7)
        theme.ecliptic = RGBAColor(0.9, 0.6, 0.2, 0.5)
        theme.sun = RGBAColor(1, 0.85, 0.3, 1)
        theme.moon = RGBAColor(0.8, 0.82, 0.9, 1)
        theme.showDebugTimestamp = true

        let data = try JSONEncoder().encode(theme)
        let decoded = try JSONDecoder().decode(StarChartTheme.self, from: data)

        XCTAssertEqual(decoded, theme)
    }

    func test_decoding_old_json_keeps_known_fields_and_defaults_new_ones() throws {
        // JSON saved before ecliptic / sun / moon existed.
        let json = Data("""
        {"background":{"r":0.1,"g":0.2,"b":0.3,"a":1},
         "stars":{"r":1,"g":1,"b":1,"a":1},
         "constellation":{"r":1,"g":1,"b":1,"a":0.1},
         "grid":{"r":1,"g":1,"b":1,"a":0.1},
         "text":{"r":1,"g":1,"b":1,"a":0.5},
         "showDebugTimestamp":true}
        """.utf8)

        let decoded = try JSONDecoder().decode(StarChartTheme.self, from: json)

        XCTAssertEqual(decoded.background, RGBAColor(0.1, 0.2, 0.3, 1))
        XCTAssertTrue(decoded.showDebugTimestamp)
        XCTAssertEqual(decoded.ecliptic, StarChartTheme().ecliptic)
        XCTAssertEqual(decoded.sun, StarChartTheme().sun)
        XCTAssertEqual(decoded.moon, StarChartTheme().moon)
    }
}
