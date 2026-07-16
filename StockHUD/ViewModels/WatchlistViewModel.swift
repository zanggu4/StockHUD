import Foundation
import Combine

@MainActor
final class WatchlistViewModel: ObservableObject {
    @Published private(set) var quotes: [String: Quote] = [:]
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var isStale = false

    private let settings: SettingsStore
    private var provider: any QuoteProvider
    private var refreshTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    init(settings: SettingsStore, provider: (any QuoteProvider)? = nil) {
        self.settings = settings
        self.provider = provider ?? Self.makeProvider(id: settings.apiProvider)

        settings.$apiProvider
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] id in
                self?.provider = Self.makeProvider(id: id)
                self?.start()
            }
            .store(in: &cancellables)

        settings.$refreshInterval
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in self?.start() }
            .store(in: &cancellables)

        settings.$symbols
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in self?.start() }
            .store(in: &cancellables)
    }

    static func makeProvider(id: String) -> any QuoteProvider {
        id == "yahoo" ? YahooFinanceProvider() : WebullProvider()
    }

    func start() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                await self.refreshNow()
                let interval = self.settings.refreshInterval
                try? await Task.sleep(for: .seconds(max(1, interval)))
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refreshNow() async {
        let symbols = settings.symbols
        guard !symbols.isEmpty else {
            quotes = [:]
            return
        }
        let fetched = await provider.fetchQuotes(symbols: symbols)
        if fetched.isEmpty {
            // Network failure: keep last known values, mark stale.
            isStale = true
            return
        }
        // Merge so symbols that failed this round keep their previous value.
        for (symbol, quote) in fetched {
            quotes[symbol] = quote
        }
        isStale = fetched.count < symbols.count
        lastUpdated = Date()
    }
}
