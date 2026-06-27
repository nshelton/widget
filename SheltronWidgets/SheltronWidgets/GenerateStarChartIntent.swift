import AppIntents
import UIKit
import CoreLocation
import UniformTypeIdentifiers

struct GenerateStarChartIntent: AppIntent {
    static var title: LocalizedStringResource = "Generate Star Chart Wallpaper"
    static var description = IntentDescription(
        "Generates a star chart image for your current location and time, suitable for use as a lock screen wallpaper.",
        categoryName: "Star Chart"
    )
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        let location: CLLocation
        do {
            let place = try await LocationProvider().current()
            location = place.location
        } catch {
            location = DayModelBuilder.fallback
        }

        let image = StarChartRenderer.render(location: location, date: Date())

        guard let data = image.pngData() else {
            throw StarChartError.renderFailed
        }

        let file = IntentFile(data: data, filename: "starchart.png", type: .png)
        return .result(value: file)
    }

    enum StarChartError: Error, CustomLocalizedStringResourceConvertible {
        case renderFailed

        var localizedStringResource: LocalizedStringResource {
            switch self {
            case .renderFailed: return "Failed to render star chart image."
            }
        }
    }
}

struct StarChartShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GenerateStarChartIntent(),
            phrases: [
                "Generate star chart with \(.applicationName)",
                "Create star chart wallpaper with \(.applicationName)",
                "Update star chart with \(.applicationName)",
            ],
            shortTitle: "Star Chart",
            systemImageName: "star.fill"
        )
    }
}
