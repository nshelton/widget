import SwiftUI
import AppIntents
import CoreLocation

struct StarChartSection: View {
    @State private var previewImage: UIImage?
    @State private var generating = false
    @State private var showSetupSheet = false
    @State private var showColorEditor = false
    @State private var theme = StarChartTheme.load()
    @AppStorage("wallpaperShortcutName") private var shortcutName = "Star Chart Wallpaper"

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill").foregroundStyle(.white.opacity(0.8))
                Text("Star Chart Wallpaper").font(.headline)
            }

            if let previewImage {
                Image(uiImage: previewImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.white.opacity(0.08)))
            }

            Button {
                generatePreview()
            } label: {
                Label(generating ? "Generating…" : "Preview Star Chart",
                      systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(generating)

            Button {
                showColorEditor = true
            } label: {
                Label("Edit Colors", systemImage: "paintpalette")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Toggle(isOn: $theme.showDebugTimestamp) {
                Label("Debug timestamp", systemImage: "clock.badge.checkmark")
            }
            .onChange(of: theme.showDebugTimestamp) { _, _ in
                theme.save()
                generatePreview()
            }

            if previewImage != nil {
                Button {
                    saveToPhotos()
                } label: {
                    Label("Save to Photos", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Button {
                runWallpaperShortcut()
            } label: {
                Label("Set Wallpaper Now", systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)

            HStack {
                Text("Shortcut").font(.caption).foregroundStyle(.secondary)
                TextField("Shortcut name", text: $shortcutName)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
            }

            Button {
                showSetupSheet = true
            } label: {
                Label("Auto-Update Setup", systemImage: "clock.arrow.2.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            ShortcutsLink()
                .shortcutsLinkStyle(.automaticOutline)
        }
        .sheet(isPresented: $showSetupSheet) {
            AutoUpdateSetupView()
        }
        .sheet(isPresented: $showColorEditor, onDismiss: { generatePreview() }) {
            StarChartSettingsView(theme: $theme)
        }
    }

    private func generatePreview() {
        generating = true
        let theme = theme
        Task {
            let location: CLLocation
            do {
                let place = try await LocationProvider().current()
                location = place.location
            } catch {
                location = DayModelBuilder.fallback
            }
            let image = StarChartRenderer.render(location: location, date: Date(),
                                                  size: CGSize(width: 1290, height: 2796),
                                                  theme: theme)
            await MainActor.run {
                previewImage = image
                generating = false
            }
        }
    }

    private func saveToPhotos() {
        guard let image = previewImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    private func runWallpaperShortcut() {
        let name = shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "shortcuts://run-shortcut?name=\(name)") else { return }
        UIApplication.shared.open(url)
    }
}

struct AutoUpdateSetupView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("iOS only lets the Shortcuts app set the wallpaper, so the app hands off to a Shortcut you create once. Build it below, then run it hourly via an automation, or tap \"Set Wallpaper Now\" in the app to run it on demand.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 16) {
                        SetupStep(number: 1,
                                  title: "New Shortcut",
                                  detail: "In Shortcuts, tap + to create a shortcut. Name it exactly \"Star Chart Wallpaper\" (or match the name in the app's Shortcut field).")

                        SetupStep(number: 2,
                                  title: "Add Actions",
                                  detail: "Search for \"Generate Star Chart\" — the app's action. Then add \"Set Wallpaper\" and choose Lock Screen, using the generated image.")

                        SetupStep(number: 3,
                                  title: "Run It from the App",
                                  detail: "Back in the app, tap \"Set Wallpaper Now\" to run this shortcut and update your lock screen.")

                        SetupStep(number: 4,
                                  title: "Automate (optional)",
                                  detail: "In the Automation tab, add a Time of Day automation that runs the same shortcut hourly. Turn off \"Ask Before Running\" so it's silent.")
                    }

                    ShortcutsLink()
                        .shortcutsLinkStyle(.automaticOutline)
                        .frame(maxWidth: .infinity)
                }
                .padding(24)
            }
            .navigationTitle("Auto-Update Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SetupStep: View {
    let number: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(.indigo))

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
