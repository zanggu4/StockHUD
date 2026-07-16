import Foundation

enum MarketSession: String, Sendable, Equatable {
    case preMarket
    case regular
    case afterHours
    case overnight
    case closed

    /// Short badge shown in the HUD; nil during regular hours or when closed.
    var badge: String? {
        switch self {
        case .preMarket: return "PRE"
        case .afterHours: return "AH"
        case .overnight: return "OVN"
        case .regular, .closed: return nil
        }
    }

    /// Current US equity market session based on Eastern Time.
    /// Overnight (Blue Ocean ATS): Sun–Thu 20:00 → next day 04:00 ET.
    static func currentUS(now: Date = Date()) -> MarketSession {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        let comps = calendar.dateComponents([.weekday, .hour, .minute], from: now)
        guard let weekday = comps.weekday, let hour = comps.hour, let minute = comps.minute else {
            return .closed
        }
        let minutes = hour * 60 + minute
        let isWeekday = (2...6).contains(weekday) // Mon–Fri

        switch minutes {
        case 240..<570: // 04:00–09:30
            return isWeekday ? .preMarket : .closed
        case 570..<960: // 09:30–16:00
            return isWeekday ? .regular : .closed
        case 960..<1200: // 16:00–20:00
            return isWeekday ? .afterHours : .closed
        case 1200...: // 20:00–24:00, Sun–Thu evenings
            return (1...5).contains(weekday) ? .overnight : .closed
        default: // 00:00–04:00, Mon–Fri early mornings
            return isWeekday ? .overnight : .closed
        }
    }
}
