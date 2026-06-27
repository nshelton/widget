import SwiftUI

struct SettingsView: View {
    @Binding var theme: WidgetTheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Colors") {
                    picker("Background", \.background)
                    picker("Sun arc line", \.sunLine)
                    picker("Day fill", \.dayFill)
                    picker("Night fill", \.nightFill)
                    picker("Temperature line", \.tempLine)
                    picker("Now line", \.nowLine)
                    picker("Horizon", \.horizon)
                    picker("Text", \.text)
                }
                Section {
                    Button("Reset to defaults", role: .destructive) {
                        theme = WidgetTheme()
                    }
                }
            }
            .navigationTitle("Widget Colors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func picker(_ label: String, _ kp: WritableKeyPath<WidgetTheme, RGBAColor>) -> some View {
        ColorPicker(label, selection: Binding(
            get: { theme[keyPath: kp].color },
            set: { theme[keyPath: kp] = RGBAColor($0) }
        ), supportsOpacity: true)
    }
}
