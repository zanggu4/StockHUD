import Foundation

/// Overnight (Blue Ocean ATS) prices from Alpaca's market data API.
///
/// The consolidated tape does not run 20:00–04:00 ET, so Webull and Yahoo both
/// freeze at the 20:00 ET after-hours close. Alpaca's `overnight` feed is the
/// only free source of live prices in that window.
///
/// Deliberately not a `QuoteProvider`: it yields a price, not a full quote. The
/// change baseline (regular-session close) has to come from elsewhere — the
/// overnight feed's `prevDailyBar` is the *previous overnight session's* close,
/// not the regular close, and using it produces wildly wrong percentages.
///
/// On the free plan quotes are real-time but trades lag 15 minutes, so the
/// bid/ask midpoint is the only live number available.
actor AlpacaOvernightProvider {
    struct Credentials: Sendable, Equatable {
        let keyId: String
        let secret: String
    }

    struct Mid: Sendable {
        let price: Double
        let timestamp: Date
    }

    private let credentials: Credentials
    /// Symbols Alpaca rejects (crypto, delisted). One bad symbol fails the whole
    /// batch, so they have to be remembered and excluded.
    private var unsupported: Set<String> = []
    private let isoParser: ISO8601DateFormatter
    private let isoParserNoFraction: ISO8601DateFormatter

    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 8
        return URLSession(configuration: config)
    }()

    init?(credentials: Credentials?) {
        guard let credentials else { return nil }
        self.credentials = credentials
        isoParser = ISO8601DateFormatter()
        isoParser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        isoParserNoFraction = ISO8601DateFormatter()
        isoParserNoFraction.formatOptions = [.withInternetDateTime]
    }

    /// Alpaca stamps quotes with nanosecond precision (`…:06.121356381Z`), but
    /// drops the fraction entirely when it happens to be zero. A formatter set to
    /// `.withFractionalSeconds` returns nil for the latter, so both are tried.
    private func parseTimestamp(_ value: String) -> Date? {
        isoParser.date(from: value) ?? isoParserNoFraction.date(from: value)
    }

    /// Midpoints for every symbol Alpaca can cover. Symbols it can't are omitted.
    func fetchMids(symbols: [String]) async -> [String: Mid] {
        var candidates = symbols.filter { Self.isEligible($0) && !unsupported.contains($0) }
        guard !candidates.isEmpty else { return [:] }

        if let mids = try? await fetchBatch(candidates) { return mids }

        // A rejected symbol takes the batch down with it. Drop the one Alpaca
        // named and retry once; anything else waits for the next cycle.
        candidates = candidates.filter { !unsupported.contains($0) }
        guard !candidates.isEmpty else { return [:] }
        return (try? await fetchBatch(candidates)) ?? [:]
    }

    /// Crypto pairs (`BTC-USD`) aren't NMS securities; Alpaca 400s on them.
    private static func isEligible(_ symbol: String) -> Bool {
        !symbol.contains("-") && !symbol.contains("/")
    }

    private func fetchBatch(_ symbols: [String]) async throws -> [String: Mid] {
        let joined = symbols.joined(separator: ",")
        guard let encoded = joined.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://data.alpaca.markets/v2/stocks/snapshots?symbols=\(encoded)&feed=overnight")
        else { throw ProviderError.badURL }

        var request = URLRequest(url: url)
        request.setValue(credentials.keyId, forHTTPHeaderField: "APCA-API-KEY-ID")
        request.setValue(credentials.secret, forHTTPHeaderField: "APCA-API-SECRET-KEY")

        let (data, response) = try await Self.session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ProviderError.badResponse }

        guard http.statusCode == 200 else {
            if let rejected = Self.rejectedSymbol(in: data) {
                unsupported.insert(rejected)
            }
            throw ProviderError.badResponse
        }

        let decoded = try JSONDecoder().decode([String: Snapshot].self, from: data)
        var mids: [String: Mid] = [:]
        for (symbol, snapshot) in decoded {
            guard let quote = snapshot.latestQuote,
                  let bid = quote.bp, let ask = quote.ap,
                  bid > 0, ask > 0,
                  let timestamp = parseTimestamp(quote.t)
            else { continue }
            mids[symbol] = Mid(price: (bid + ask) / 2, timestamp: timestamp)
        }
        return mids
    }

    /// Alpaca names the offender: `code=400, message=invalid symbol: BTC-USD`.
    private static func rejectedSymbol(in data: Data) -> String? {
        guard let error = try? JSONDecoder().decode(ErrorResponse.self, from: data),
              let range = error.message.range(of: "invalid symbol: ")
        else { return nil }
        let symbol = error.message[range.upperBound...]
            .prefix { !$0.isWhitespace && $0 != "," }
        return symbol.isEmpty ? nil : String(symbol)
    }

    enum ProviderError: Error {
        case badURL
        case badResponse
    }
}

// MARK: - API payloads

/// The batch endpoint keys snapshots by symbol at the top level, with no wrapper.
private struct Snapshot: Decodable {
    let latestQuote: SnapshotQuote?
}

private struct SnapshotQuote: Decodable {
    let bp: Double?
    let ap: Double?
    let t: String
}

private struct ErrorResponse: Decodable {
    let message: String
}
