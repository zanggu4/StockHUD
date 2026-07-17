import Foundation

/// Substitutes live overnight prices from Alpaca during the 20:00–04:00 ET
/// session, and gets out of the way the rest of the day.
///
/// Outside overnight — or with no Alpaca credentials — this is a pass-through to
/// the base provider, so the user's Webull/Yahoo choice still decides everything.
actor OvernightCompositeProvider: QuoteProvider {
    nonisolated let name: String

    private let base: any QuoteProvider
    private let alpaca: AlpacaOvernightProvider?

    init(base: any QuoteProvider, alpaca: AlpacaOvernightProvider?) {
        self.base = base
        self.alpaca = alpaca
        self.name = base.name
    }

    func fetchQuote(symbol: String) async throws -> Quote {
        let quotes = await fetchQuotes(symbols: [symbol])
        guard let quote = quotes[symbol] else { throw ProviderError.symbolNotFound }
        return quote
    }

    func fetchQuotes(symbols: [String]) async -> [String: Quote] {
        let baseQuotes = await base.fetchQuotes(symbols: symbols)
        guard MarketSession.currentUS() == .overnight, let alpaca else { return baseQuotes }

        let mids = await alpaca.fetchMids(symbols: symbols)
        guard !mids.isEmpty else { return baseQuotes }

        var quotes = baseQuotes
        for (symbol, mid) in mids {
            // The base quote carries the regular-session close in `price` during
            // overnight (Webull takes its non-extended branch, Yahoo reports
            // regularMarketPrice), which is the baseline extended-hours change is
            // measured against.
            guard let regular = baseQuotes[symbol] else { continue }
            quotes[symbol] = Quote(
                symbol: symbol,
                price: mid.price,
                previousClose: regular.price,
                currency: regular.currency,
                updatedAt: mid.timestamp,
                session: .overnight
            )
        }
        // Symbols Alpaca couldn't cover keep their base quote — no overnight
        // badge, and WatchlistViewModel flags them stale once they age out.
        return quotes
    }

    enum ProviderError: Error {
        case symbolNotFound
    }
}
