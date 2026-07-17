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
        self.provider = provider ?? Self.makeProvider(
            id: settings.apiProvider,
            credentials: settings.alpacaCredentials
        )

        settings.$apiProvider
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] id in
                guard let self else { return }
                self.provider = Self.makeProvider(id: id, credentials: self.settings.alpacaCredentials)
                self.start()
            }
            .store(in: &cancellables)

        // Debounced: SecureField writes through on every keystroke, and each one
        // would otherwise rebuild the provider and restart the polling loop.
        Publishers.CombineLatest(settings.$alpacaKeyId, settings.$alpacaSecret)
            .dropFirst()
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .removeDuplicates { $0 == $1 }
            .sink { [weak self] _ in
                guard let self else { return }
                self.provider = Self.makeProvider(
                    id: self.settings.apiProvider,
                    credentials: self.settings.alpacaCredentials
                )
                self.start()
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

    /// Data older than this during a live session means the feed has stalled.
    /// Generous on purpose: quiet extended-hours symbols can legitimately go
    /// minutes between trades, while the failure this catches — a provider stuck
    /// at the 20:00 ET close — is hours wide.
    private static let staleThreshold: TimeInterval = 15 * 60

    static func makeProvider(
        id: String,
        credentials: AlpacaOvernightProvider.Credentials?
    ) -> any QuoteProvider {
        let base: any QuoteProvider = id == "yahoo" ? YahooFinanceProvider() : WebullProvider()
        return OvernightCompositeProvider(
            base: base,
            alpaca: AlpacaOvernightProvider(credentials: credentials)
        )
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

        // Report when the data is from, not when we asked for it — a feed frozen
        // hours ago used to render with the current time next to it.
        let newest = fetched.values.map(\.updatedAt).max()
        lastUpdated = newest

        let missingSymbols = fetched.count < symbols.count
        let age = newest.map { Date().timeIntervalSince($0) } ?? .infinity
        // Only while a session is running: outside one, a close that's hours old
        // is simply the current price.
        let sessionIsLive = MarketSession.currentUS() != .closed
        isStale = missingSymbols || (sessionIsLive && age > Self.staleThreshold)
    }
}
