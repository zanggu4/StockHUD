import SwiftUI

@main
struct StockHUDApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("StockHUD", systemImage: "chart.line.uptrend.xyaxis") {
            MenuBarMenuView()
                .environmentObject(appDelegate)
        }

        Settings {
            SettingsRootView()
                .environmentObject(appDelegate.settings)
        }
    }
}
