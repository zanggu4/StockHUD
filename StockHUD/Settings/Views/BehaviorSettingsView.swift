import SwiftUI

struct BehaviorSettingsView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        Form {
            Toggle("Always On Top", isOn: $settings.alwaysOnTop)
            Toggle("Click Through (Ignore Mouse Events)", isOn: $settings.clickThrough)
            Text("When enabled, the HUD cannot be clicked or dragged. Turn it off here to interact again.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Toggle("Lock Position", isOn: $settings.lockPosition)
            Toggle("Show on All Spaces", isOn: $settings.showOnAllSpaces)
            Toggle("Show over Fullscreen Apps", isOn: $settings.showOverFullscreen)
        }
        .padding(20)
    }
}
