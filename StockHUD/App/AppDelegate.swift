import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    let settings = SettingsStore()
    private(set) lazy var viewModel = WatchlistViewModel(settings: settings)
    private var panelController: HUDPanelController?

    @Published private(set) var hudVisible = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = HUDPanelController(settings: settings, viewModel: viewModel)
        panelController = controller
        if !settings.startHidden {
            controller.show()
        }
        hudVisible = controller.isVisible
        viewModel.start()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showHUD()
        return true
    }

    func toggleHUD() {
        panelController?.toggle()
        hudVisible = panelController?.isVisible ?? false
    }

    func showHUD() {
        panelController?.show()
        hudVisible = true
    }
}
