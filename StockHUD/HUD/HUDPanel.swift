import AppKit

/// Borderless, non-activating floating panel that never steals focus.
final class HUDPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
