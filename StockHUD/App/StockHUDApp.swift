import SwiftUI

@main
struct StockHUDApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsRootView()
                .environmentObject(appDelegate.settings)
        }
        .commands {
            CommandMenu("HUD") {
                Button("Toggle HUD") {
                    appDelegate.toggleHUD()
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])
            }
        }
    }
}
