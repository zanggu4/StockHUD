import Foundation

struct Quote: Identifiable, Equatable, Sendable {
    let symbol: String
    let price: Double
    /// Baseline for change calculation: previous close during regular hours,
    /// regular-session close during extended sessions.
    let previousClose: Double
    let currency: String?
    let updatedAt: Date
    var session: MarketSession = .regular

    var id: String { symbol }

    var change: Double { price - previousClose }

    var changePercent: Double {
        guard previousClose != 0 else { return 0 }
        return change / previousClose * 100
    }

    enum Direction: Sendable {
        case up, down, flat
    }

    var direction: Direction {
        if change > 0.000_01 { return .up }
        if change < -0.000_01 { return .down }
        return .flat
    }
}
