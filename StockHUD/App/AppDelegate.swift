import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let settings = SettingsStore()
    private(set) lazy var viewModel = WatchlistViewModel(settings: settings)
    private var panelController: HUDPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = HUDPanelController(settings: settings, viewModel: viewModel)
        panelController = controller
        if !settings.startHidden {
            controller.show()
        }
        viewModel.start()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        panelController?.show()
        return true
    }

    func toggleHUD() {
        panelController?.toggle()
    }

    func showHUD() {
        panelController?.show()
    }
}
