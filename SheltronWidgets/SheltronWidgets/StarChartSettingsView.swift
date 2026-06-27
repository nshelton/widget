import SwiftUI

struct StarChartSettingsView: View {
    @Binding var theme: StarChartTheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Star Chart Colors") {
                    picker("Background", \.background)
                    picker("Stars", \.stars)
                    picker("Constellations", \.constellation)
                    picker("Grid & horizon", \.grid)
                    picker("Text", \.text)
                    picker("Ecliptic", \.ecliptic)
                    picker("Sun", \.sun)
                    picker("Moon", \.moon)
                }
            }
            .navigationTitle("Star Chart Colors")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: theme) { _, _ in theme.save() }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func picker(_ label: String, _ kp: WritableKeyPath<StarChartTheme, RGBAColor>) -> some View {
        ColorPicker(label, selection: Binding(
            get: { theme[keyPath: kp].color },
            set: { theme[keyPath: kp] = RGBAColor($0) }
        ), supportsOpacity: true)
    }
}
