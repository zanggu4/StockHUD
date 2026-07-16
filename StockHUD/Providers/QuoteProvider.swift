import Foundation

protocol QuoteProvider: Sendable {
    var name: String { get }
    func fetchQuote(symbol: String) async throws -> Quote
    /// Fetches all symbols; implementations may batch. Failed symbols are omitted.
    func fetchQuotes(symbols: [String]) async -> [String: Quote]
}

extension QuoteProvider {
    /// Fetches all symbols in parallel. Failed symbols are omitted from the result.
    func fetchQuotes(symbols: [String]) async -> [String: Quote] {
        await withTaskGroup(of: Quote?.self) { group in
            for symbol in symbols {
                group.addTask {
                    try? await self.fetchQuote(symbol: symbol)
                }
            }
            var quotes: [String: Quote] = [:]
            for await quote in group {
                if let quote {
                    quotes[quote.symbol] = quote
                }
            }
            return quotes
        }
    }
}
