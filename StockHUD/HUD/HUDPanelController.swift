import AppKit
import SwiftUI
import Combine

@MainActor
final class HUDPanelController {
    private let panel: HUDPanel
    private let settings: SettingsStore
    private var cancellables: Set<AnyCancellable> = []

    init(settings: SettingsStore, viewModel: WatchlistViewModel) {
        self.settings = settings

        let rootView = HUDView()
            .environmentObject(settings)
            .environmentObject(viewModel)
        let hosting = NSHostingController(rootView: rootView)
        hosting.sizingOptions = [.preferredContentSize]

        let panel = HUDPanel(contentViewController: hosting)
        panel.styleMask = [.borderless, .nonactivatingPanel]
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.animationBehavior = .none
        panel.setFrameAutosaveName("StockHUDPanel")
        self.panel = panel

        applySettings()

        settings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.applySettings() }
            .store(in: &cancellables)
    }

    var isVisible: Bool { panel.isVisible }

    func show() {
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    func toggle() {
        if isVisible { hide() } else { show() }
    }

    private func applySettings() {
        panel.level = settings.alwaysOnTop ? .floating : .normal
        panel.alphaValue = max(0.1, settings.transparency)
        panel.ignoresMouseEvents = settings.clickThrough
        panel.isMovable = !settings.lockPosition
        panel.isMovableByWindowBackground = !settings.lockPosition
        panel.hasShadow = settings.shadow

        var behavior: NSWindow.CollectionBehavior = []
        if settings.showOnAllSpaces { behavior.insert(.canJoinAllSpaces) }
        if settings.showOverFullscreen { behavior.insert(.fullScreenAuxiliary) }
        panel.collectionBehavior = behavior
    }
}
