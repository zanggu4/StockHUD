import SwiftUI
import Combine
import ServiceManagement

enum DisplayMode: String, CaseIterable, Identifiable {
    case mini
    case detail

    var id: String { rawValue }
    var displayName: String { self == .mini ? "Mini" : "Detail" }
}

enum SizePreset: String, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }

    var scale: Double {
        switch self {
        case .small: return 0.85
        case .medium: return 1.0
        case .large: return 1.25
        }
    }
}

@MainActor
final class SettingsStore: ObservableObject {
    private let defaults = UserDefaults.standard

    // MARK: - Watchlist

    @Published var symbols: [String] {
        didSet { defaults.set(symbols, forKey: "symbols") }
    }

    // MARK: - General

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: "launchAtLogin")
            applyLaunchAtLogin()
        }
    }
    @Published var startHidden: Bool {
        didSet { defaults.set(startHidden, forKey: "startHidden") }
    }
    @Published var checkUpdateAutomatically: Bool {
        didSet { defaults.set(checkUpdateAutomatically, forKey: "checkUpdateAutomatically") }
    }

    // MARK: - Display

    @Published var displayMode: DisplayMode {
        didSet { defaults.set(displayMode.rawValue, forKey: "displayMode") }
    }
    @Published var sizePreset: SizePreset {
        didSet { defaults.set(sizePreset.rawValue, forKey: "sizePreset") }
    }
    @Published var fontSize: Double {
        didSet { defaults.set(fontSize, forKey: "fontSize") }
    }
    @Published var fontFamily: String {
        didSet { defaults.set(fontFamily, forKey: "fontFamily") }
    }
    @Published var transparency: Double {
        didSet { defaults.set(transparency, forKey: "transparency") }
    }
    @Published var padding: Double {
        didSet { defaults.set(padding, forKey: "padding") }
    }
    @Published var cornerRadius: Double {
        didSet { defaults.set(cornerRadius, forKey: "cornerRadius") }
    }
    @Published var shadow: Bool {
        didSet { defaults.set(shadow, forKey: "shadow") }
    }
    @Published var lineSpacing: Double {
        didSet { defaults.set(lineSpacing, forKey: "lineSpacing") }
    }
    @Published var upColorHex: String {
        didSet { defaults.set(upColorHex, forKey: "upColorHex") }
    }
    @Published var downColorHex: String {
        didSet { defaults.set(downColorHex, forKey: "downColorHex") }
    }
    @Published var flatColorHex: String {
        didSet { defaults.set(flatColorHex, forKey: "flatColorHex") }
    }

    // MARK: - Behavior

    @Published var alwaysOnTop: Bool {
        didSet { defaults.set(alwaysOnTop, forKey: "alwaysOnTop") }
    }
    @Published var clickThrough: Bool {
        didSet { defaults.set(clickThrough, forKey: "clickThrough") }
    }
    @Published var lockPosition: Bool {
        didSet { defaults.set(lockPosition, forKey: "lockPosition") }
    }
    @Published var showOnAllSpaces: Bool {
        didSet { defaults.set(showOnAllSpaces, forKey: "showOnAllSpaces") }
    }
    @Published var showOverFullscreen: Bool {
        didSet { defaults.set(showOverFullscreen, forKey: "showOverFullscreen") }
    }

    // MARK: - Update

    @Published var refreshInterval: Double {
        didSet { defaults.set(refreshInterval, forKey: "refreshInterval") }
    }
    @Published var apiProvider: String {
        didSet { defaults.set(apiProvider, forKey: "apiProvider") }
    }
    @Published var linkTarget: LinkTarget {
        didSet { defaults.set(linkTarget.rawValue, forKey: "linkTarget") }
    }

    static let refreshIntervalChoices: [Double] = [1, 2, 5, 10, 30, 60]

    init() {
        symbols = defaults.stringArray(forKey: "symbols") ?? ["NVDA", "TSLA", "PLTR", "BTC-USD"]

        launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        startHidden = defaults.bool(forKey: "startHidden")
        checkUpdateAutomatically = defaults.object(forKey: "checkUpdateAutomatically") as? Bool ?? true

        displayMode = DisplayMode(rawValue: defaults.string(forKey: "displayMode") ?? "") ?? .mini
        sizePreset = SizePreset(rawValue: defaults.string(forKey: "sizePreset") ?? "") ?? .medium
        fontSize = defaults.object(forKey: "fontSize") as? Double ?? 13
        fontFamily = defaults.string(forKey: "fontFamily") ?? "System"
        transparency = defaults.object(forKey: "transparency") as? Double ?? 1.0
        padding = defaults.object(forKey: "padding") as? Double ?? 10
        cornerRadius = defaults.object(forKey: "cornerRadius") as? Double ?? 10
        shadow = defaults.object(forKey: "shadow") as? Bool ?? true
        lineSpacing = defaults.object(forKey: "lineSpacing") as? Double ?? 4
        upColorHex = defaults.string(forKey: "upColorHex") ?? "#34C759"
        downColorHex = defaults.string(forKey: "downColorHex") ?? "#FF3B30"
        flatColorHex = defaults.string(forKey: "flatColorHex") ?? "#8E8E93"

        alwaysOnTop = defaults.object(forKey: "alwaysOnTop") as? Bool ?? true
        clickThrough = defaults.bool(forKey: "clickThrough")
        lockPosition = defaults.bool(forKey: "lockPosition")
        showOnAllSpaces = defaults.object(forKey: "showOnAllSpaces") as? Bool ?? true
        showOverFullscreen = defaults.object(forKey: "showOverFullscreen") as? Bool ?? true

        refreshInterval = defaults.object(forKey: "refreshInterval") as? Double ?? 10
        apiProvider = defaults.string(forKey: "apiProvider") ?? "webull"
        linkTarget = LinkTarget(rawValue: defaults.string(forKey: "linkTarget") ?? "") ?? .tradingView
    }

    // MARK: - Derived

    var scaledFontSize: Double { fontSize * sizePreset.scale }

    var upColor: Color { Color(hex: upColorHex) ?? .green }
    var downColor: Color { Color(hex: downColorHex) ?? .red }
    var flatColor: Color { Color(hex: flatColorHex) ?? .gray }

    func color(for direction: Quote.Direction) -> Color {
        switch direction {
        case .up: return upColor
        case .down: return downColor
        case .flat: return flatColor
        }
    }

    func font(size: Double, weight: Font.Weight = .regular) -> Font {
        if fontFamily == "System" {
            return .system(size: size, weight: weight, design: .monospaced)
        }
        return .custom(fontFamily, size: size)
    }

    // MARK: - Watchlist mutations

    func addSymbol(_ raw: String) {
        let symbol = raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !symbol.isEmpty, !symbols.contains(symbol) else { return }
        symbols.append(symbol)
    }

    func removeSymbol(_ symbol: String) {
        symbols.removeAll { $0 == symbol }
    }

    // MARK: - Launch at Login

    private func applyLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Launch at Login change failed: \(error.localizedDescription)")
        }
    }
}

extension Color {
    init?(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let rgb = UInt64(value, radix: 16) else { return nil }
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }

    func toHex() -> String {
        let nsColor = NSColor(self).usingColorSpace(.sRGB) ?? .gray
        let r = Int(round(nsColor.redComponent * 255))
        let g = Int(round(nsColor.greenComponent * 255))
        let b = Int(round(nsColor.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
