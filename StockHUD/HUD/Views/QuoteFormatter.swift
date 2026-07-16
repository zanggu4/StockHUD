import Foundation

@MainActor
enum QuoteFormatter {
    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    static func price(_ value: Double, currency: String? = nil) -> String {
        priceFormatter.minimumFractionDigits = 2
        priceFormatter.maximumFractionDigits = 4
        let number = priceFormatter.string(from: NSNumber(value: value)) ?? String(value)
        let symbol = currency == "USD" ? "$" : ""
        return symbol + number
    }

    static func percent(_ value: Double, signed: Bool) -> String {
        let sign = signed ? (value > 0 ? "+" : value < 0 ? "-" : "") : ""
        return String(format: "%@%.2f%%", sign, abs(value))
    }

    static func change(_ value: Double, currency: String?) -> String {
        let sign = value >= 0 ? "+" : "-"
        let symbol = currency == "USD" ? "$" : ""
        priceFormatter.minimumFractionDigits = 2
        priceFormatter.maximumFractionDigits = 4
        let number = priceFormatter.string(from: NSNumber(value: abs(value))) ?? String(abs(value))
        return "\(sign)\(symbol)\(number)"
    }

    static func time(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    static func arrow(for direction: Quote.Direction) -> String {
        switch direction {
        case .up: return "▲"
        case .down: return "▼"
        case .flat: return "–"
        }
    }
}
