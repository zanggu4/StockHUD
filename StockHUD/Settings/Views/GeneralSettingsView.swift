import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            Toggle("Start Hidden", isOn: $settings.startHidden)
            Toggle("Check Update Automatically", isOn: $settings.checkUpdateAutomatically)
        }
        .padding(20)
    }
}
