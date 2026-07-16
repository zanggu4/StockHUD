import SwiftUI

struct DisplaySettingsView: View {
    @EnvironmentObject private var settings: SettingsStore

    private static let fontFamilies: [String] = {
        var families = ["System"]
        families.append(contentsOf: NSFontManager.shared.availableFontFamilies.sorted())
        return families
    }()

    var body: some View {
        Form {
            Picker("Display Mode", selection: $settings.displayMode) {
                ForEach(DisplayMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Picker("Size", selection: $settings.sizePreset) {
                ForEach(SizePreset.allCases) { preset in
                    Text(preset.displayName).tag(preset)
                }
            }
            .pickerStyle(.segmented)

            Slider(value: $settings.fontSize, in: 9...24, step: 1) {
                sliderLabel("Font Size", value: "\(Int(settings.fontSize))pt")
            }

            Picker("Font Family", selection: $settings.fontFamily) {
                ForEach(Self.fontFamilies, id: \.self) { family in
                    Text(family).tag(family)
                }
            }

            Slider(value: $settings.transparency, in: 0.1...1.0) {
                sliderLabel("Opacity", value: "\(Int(settings.transparency * 100))%")
            }

            Slider(value: $settings.padding, in: 0...30, step: 1) {
                sliderLabel("Padding", value: "\(Int(settings.padding))")
            }

            Slider(value: $settings.cornerRadius, in: 0...30, step: 1) {
                sliderLabel("Corner Radius", value: "\(Int(settings.cornerRadius))")
            }

            Slider(value: $settings.lineSpacing, in: 0...20, step: 1) {
                sliderLabel("Line Spacing", value: "\(Int(settings.lineSpacing))")
            }

            Toggle("Shadow", isOn: $settings.shadow)

            Divider()

            ColorPicker("Up Color", selection: colorBinding(\.upColorHex), supportsOpacity: false)
            ColorPicker("Down Color", selection: colorBinding(\.downColorHex), supportsOpacity: false)
            ColorPicker("Flat Color", selection: colorBinding(\.flatColorHex), supportsOpacity: false)
        }
        .padding(20)
    }

    private func sliderLabel(_ title: LocalizedStringKey, value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
            Text(verbatim: value)
                .foregroundStyle(.secondary)
        }
    }

    private func colorBinding(_ keyPath: ReferenceWritableKeyPath<SettingsStore, String>) -> Binding<Color> {
        Binding(
            get: { Color(hex: settings[keyPath: keyPath]) ?? .gray },
            set: { settings[keyPath: keyPath] = $0.toHex() }
        )
    }
}
