import Foundation

/// Quotes from Webull's unofficial anonymous API.
/// One batched request covers all resolvable symbols and includes pre-market and
/// after-hours prices. It has no overnight data — the endpoint always reports
/// `overnight: 0` and freezes at the 20:00 ET close, because the consolidated
/// tape doesn't run overnight. See `OvernightCompositeProvider` for that session.
/// Symbols Webull can't resolve (e.g. crypto like BTC-USD) fall back to Yahoo.
actor WebullProvider: QuoteProvider {
    nonisolated let name = "Webull"

    private var tickerIds: [String: Int] = [:]
    private var unresolvable: Set<String> = []
    private let fallback = YahooFinanceProvider()
    private let isoParser: ISO8601DateFormatter

    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 8
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"
        ]
        return URLSession(configuration: config)
    }()

    init() {
        isoParser = ISO8601DateFormatter()
        isoParser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    }

    enum ProviderError: Error {
        case badURL
        case badResponse
        case symbolNotFound
    }

    func fetchQuote(symbol: String) async throws -> Quote {
        let quotes = await fetchQuotes(symbols: [symbol])
        guard let quote = quotes[symbol] else { throw ProviderError.symbolNotFound }
        return quote
    }

    func fetchQuotes(symbols: [String]) async -> [String: Quote] {
        var result: [String: Quote] = [:]

        var resolved: [Int: String] = [:] // tickerId -> symbol
        for symbol in symbols {
            if let id = await resolveTickerId(symbol) {
                resolved[id] = symbol
            }
        }

        if !resolved.isEmpty, let batch = try? await fetchBatch(resolved) {
            result.merge(batch) { _, new in new }
        }

        // Anything Webull couldn't resolve or return goes to Yahoo.
        let missing = symbols.filter { result[$0] == nil }
        if !missing.isEmpty {
            let fallbackQuotes = await fallback.fetchQuotes(symbols: missing)
            result.merge(fallbackQuotes) { _, new in new }
        }
        return result
    }

    // MARK: - Symbol resolution

    private func resolveTickerId(_ symbol: String) async -> Int? {
        if let cached = tickerIds[symbol] { return cached }
        if unresolvable.contains(symbol) { return nil }

        guard let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://quotes-gw.webullfintech.com/api/search/pc/tickers?keyword=\(encoded)&pageIndex=1&pageSize=8")
        else { return nil }

        guard let (data, response) = try? await Self.session.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let search = try? JSONDecoder().decode(SearchResponse.self, from: data)
        else {
            // Transient failure: don't mark unresolvable so we retry next cycle.
            return nil
        }

        let match = (search.data ?? []).first {
            $0.disSymbol?.uppercased() == symbol.uppercased() && $0.regionCode == "US"
        }
        if let id = match?.tickerId {
            tickerIds[symbol] = id
            return id
        }
        unresolvable.insert(symbol)
        return nil
    }

    // MARK: - Batch quotes

    private func fetchBatch(_ resolved: [Int: String]) async throws -> [String: Quote] {
        let ids = resolved.keys.map(String.init).joined(separator: ",")
        guard let url = URL(string: "https://quotes-gw.webullfintech.com/api/bgw/quote/realtime?ids=\(ids)&includeSecu=1&delay=0&more=1")
        else { throw ProviderError.badURL }

        let (data, response) = try await Self.session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ProviderError.badResponse
        }

        let tickers = try JSONDecoder().decode([TickerQuote].self, from: data)
        let clockSession = MarketSession.currentUS()
        // Overnight is excluded: `pPrice` stops updating at the 20:00 ET close,
        // so claiming it as an overnight price would badge stale data as live.
        let isExtended = clockSession == .preMarket || clockSession == .afterHours

        var quotes: [String: Quote] = [:]
        for ticker in tickers {
            guard let symbol = resolved[ticker.tickerId],
                  let close = Self.double(ticker.close)
            else { continue }

            let updatedAt = ticker.tradeTime.flatMap { isoParser.date(from: $0) } ?? Date()

            if isExtended, let extendedPrice = Self.double(ticker.pPrice) {
                // Extended session: change is measured against the regular-session close.
                quotes[symbol] = Quote(
                    symbol: symbol,
                    price: extendedPrice,
                    previousClose: close,
                    currency: "USD",
                    updatedAt: updatedAt,
                    session: clockSession
                )
            } else {
                quotes[symbol] = Quote(
                    symbol: symbol,
                    price: close,
                    previousClose: Self.double(ticker.preClose) ?? close,
                    currency: "USD",
                    updatedAt: updatedAt,
                    session: clockSession == .regular ? .regular : .closed
                )
            }
        }
        return quotes
    }

    private static func double(_ value: String?) -> Double? {
        value.flatMap(Double.init)
    }
}

// MARK: - API payloads (Webull sends numbers as strings)

private struct SearchResponse: Decodable {
    let data: [SearchTicker]?

    struct SearchTicker: Decodable {
        let tickerId: Int
        let disSymbol: String?
        let regionCode: String?
    }
}

private struct TickerQuote: Decodable {
    let tickerId: Int
    let close: String?
    let preClose: String?
    let pPrice: String?
    let tradeTime: String?
}
