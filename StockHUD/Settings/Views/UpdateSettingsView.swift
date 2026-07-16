import SwiftUI

struct UpdateSettingsView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        Form {
            Picker("Refresh Interval", selection: $settings.refreshInterval) {
                ForEach(SettingsStore.refreshIntervalChoices, id: \.self) { seconds in
                    Text(seconds < 60 ? "\(Int(seconds))s" : "1m").tag(seconds)
                }
            }

            Picker("API Provider", selection: $settings.apiProvider) {
                Text("Webull (extended hours, batch)").tag("webull")
                Text("Yahoo Finance (regular hours)").tag("yahoo")
            }
            Text("Webull covers pre-market / after-hours prices and falls back to Yahoo for symbols it doesn't carry (e.g. crypto).")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Double-Click Opens", selection: $settings.linkTarget) {
                ForEach(LinkTarget.allCases) { target in
                    Text(target.displayName).tag(target)
                }
            }
        }
        .padding(20)
    }
}
