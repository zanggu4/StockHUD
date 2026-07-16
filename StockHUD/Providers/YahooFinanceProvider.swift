import Foundation

struct YahooFinanceProvider: QuoteProvider {
    let name = "Yahoo Finance"

    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 8
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15"
        ]
        return URLSession(configuration: config)
    }()

    enum ProviderError: Error {
        case badURL
        case badResponse
        case emptyResult
    }

    func fetchQuote(symbol: String) async throws -> Quote {
        guard let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?interval=1d&range=1d")
        else { throw ProviderError.badURL }

        let (data, response) = try await Self.session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ProviderError.badResponse
        }

        let decoded = try JSONDecoder().decode(ChartResponse.self, from: data)
        guard let meta = decoded.chart.result?.first?.meta,
              let price = meta.regularMarketPrice
        else { throw ProviderError.emptyResult }

        let previousClose = meta.previousClose ?? meta.chartPreviousClose ?? price
        let updatedAt = meta.regularMarketTime.map { Date(timeIntervalSince1970: TimeInterval($0)) } ?? Date()

        return Quote(
            symbol: symbol,
            price: price,
            previousClose: previousClose,
            currency: meta.currency,
            updatedAt: updatedAt
        )
    }
}

private struct ChartResponse: Decodable {
    let chart: Chart

    struct Chart: Decodable {
        let result: [Item]?
    }

    struct Item: Decodable {
        let meta: Meta
    }

    struct Meta: Decodable {
        let symbol: String
        let currency: String?
        let regularMarketPrice: Double?
        let previousClose: Double?
        let chartPreviousClose: Double?
        let regularMarketTime: Int?
    }
}
