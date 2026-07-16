import Foundation

enum LinkTarget: String, CaseIterable, Identifiable, Sendable {
    case tradingView
    case yahooFinance
    case finviz
    case stockAnalysis

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tradingView: return "TradingView"
        case .yahooFinance: return "Yahoo Finance"
        case .finviz: return "Finviz"
        case .stockAnalysis: return "Stock Analysis"
        }
    }

    func url(for symbol: String) -> URL? {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        switch self {
        case .tradingView:
            return URL(string: "https://www.tradingview.com/symbols/\(encoded)/")
        case .yahooFinance:
            return URL(string: "https://finance.yahoo.com/quote/\(encoded)")
        case .finviz:
            return URL(string: "https://finviz.com/quote.ashx?t=\(encoded)")
        case .stockAnalysis:
            return URL(string: "https://stockanalysis.com/stocks/\(encoded.lowercased())/")
        }
    }
}
