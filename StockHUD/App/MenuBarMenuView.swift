import SwiftUI

struct MenuBarMenuView: View {
    @EnvironmentObject private var appDelegate: AppDelegate
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button(appDelegate.hudVisible ? "Hide HUD" : "Show HUD") {
            appDelegate.toggleHUD()
        }
        .keyboardShortcut("h", modifiers: [.command, .shift])

        Divider()

        Button("Settings…") {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
        .keyboardShortcut(",")

        Divider()

        Button("Quit StockHUD") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
