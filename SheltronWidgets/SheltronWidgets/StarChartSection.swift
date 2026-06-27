import SwiftUI
import AppIntents
import CoreLocation

struct StarChartSection: View {
    @State private var previewImage: UIImage?
    @State private var generating = false
    @State private var showSetupSheet = false

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
                showSetupSheet = true
            } label: {
                Label("Auto-Update Setup", systemImage: "clock.arrow.2.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)

            ShortcutsLink()
                .shortcutsLinkStyle(.automaticOutline)
        }
        .sheet(isPresented: $showSetupSheet) {
            AutoUpdateSetupView()
        }
    }

    private func generatePreview() {
        generating = true
        Task {
            let location: CLLocation
            do {
                let place = try await LocationProvider().current()
                location = place.location
            } catch {
                location = DayModelBuilder.fallback
            }
            let image = StarChartRenderer.render(location: location, date: Date(),
                                                  size: CGSize(width: 1290, height: 2796))
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
}

struct AutoUpdateSetupView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("The app provides a Shortcut action that generates a fresh star chart. You can set up a Shortcuts automation to run it hourly and set your lock screen wallpaper automatically.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 16) {
                        SetupStep(number: 1,
                                  title: "Open Shortcuts",
                                  detail: "Go to the Automation tab")

                        SetupStep(number: 2,
                                  title: "New Automation",
                                  detail: "Tap + → Personal Automation → Time of Day")

                        SetupStep(number: 3,
                                  title: "Set Schedule",
                                  detail: "Choose \"Hourly\" or your preferred interval")

                        SetupStep(number: 4,
                                  title: "Add Actions",
                                  detail: "Search for \"Generate Star Chart\" — this is the app's action. Then add \"Set Wallpaper\" and choose Lock Screen.")

                        SetupStep(number: 5,
                                  title: "Disable Ask Before Running",
                                  detail: "Toggle it off so it runs silently in the background")
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
