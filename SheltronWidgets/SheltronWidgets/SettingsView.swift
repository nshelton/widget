import SwiftUI

struct SettingsView: View {
    @Binding var store: PaletteStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Palette") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(store.palettes) { p in
                                chip(p)
                            }
                            Button { addPalette() } label: {
                                Image(systemName: "plus")
                                    .frame(width: 28, height: 28)
                                    .background(Color.secondary.opacity(0.2), in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                    }
                    TextField("Name", text: nameBinding)
                    if store.palettes.count > 1 {
                        Button("Delete this palette", role: .destructive) { deleteSelected() }
                    }
                }

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
            }
            .navigationTitle("Palettes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func chip(_ p: Palette) -> some View {
        let selected = p.id == store.selectedID
        return Button { store.selectedID = p.id } label: {
            Text(p.name)
                .font(.system(size: 13, design: .monospaced))
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(selected ? Color.accentColor : Color.secondary.opacity(0.2),
                            in: Capsule())
                .foregroundStyle(selected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    private var nameBinding: Binding<String> {
        let idx = store.selectedIndex
        return Binding(
            get: { store.palettes[idx].name },
            set: { store.palettes[idx].name = $0 }
        )
    }

    private func picker(_ label: String, _ kp: WritableKeyPath<WidgetTheme, RGBAColor>) -> some View {
        let idx = store.selectedIndex
        return ColorPicker(label, selection: Binding(
            get: { store.palettes[idx].theme[keyPath: kp].color },
            set: { store.palettes[idx].theme[keyPath: kp] = RGBAColor($0) }
        ), supportsOpacity: true)
    }

    private func addPalette() {
        let base = store.palettes[store.selectedIndex].theme
        let new = Palette(id: UUID(), name: "Custom \(store.palettes.count + 1)", theme: base)
        store.palettes.append(new)
        store.selectedID = new.id
    }

    private func deleteSelected() {
        guard store.palettes.count > 1 else { return }
        let idx = store.selectedIndex
        store.palettes.remove(at: idx)
        store.selectedID = store.palettes[max(0, idx - 1)].id
    }
}
