import SwiftUI

struct HUDView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var viewModel: WatchlistViewModel
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: settings.lineSpacing) {
            if settings.symbols.isEmpty {
                emptyView
            } else {
                rows
                footer
            }
        }
        .padding(settings.padding)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: settings.cornerRadius, style: .continuous)
        )
        .contextMenu { contextMenu }
        .fixedSize()
    }

    @ViewBuilder
    private var rows: some View {
        ForEach(settings.symbols, id: \.self) { symbol in
            Group {
                switch settings.displayMode {
                case .mini:
                    MiniRowView(symbol: symbol, quote: viewModel.quotes[symbol])
                case .detail:
                    DetailRowView(symbol: symbol, quote: viewModel.quotes[symbol])
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { open(symbol) }
        }
    }

    @ViewBuilder
    private var footer: some View {
        if settings.displayMode == .detail, let updated = viewModel.lastUpdated {
            Text(QuoteFormatter.time(updated) + (viewModel.isStale ? " ⚠︎" : ""))
                .font(settings.font(size: settings.scaledFontSize * 0.75))
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }

    private var emptyView: some View {
        Text("No symbols — right-click to open Settings")
            .font(settings.font(size: settings.scaledFontSize))
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button(settings.displayMode == .mini ? "Switch to Detail Mode" : "Switch to Mini Mode") {
            settings.displayMode = settings.displayMode == .mini ? .detail : .mini
        }
        Button("Refresh Now") {
            Task { await viewModel.refreshNow() }
        }
        Divider()
        if !settings.symbols.isEmpty {
            Menu("Remove Symbol") {
                ForEach(settings.symbols, id: \.self) { symbol in
                    Button(symbol) { settings.removeSymbol(symbol) }
                }
            }
        }
        Divider()
        Button("Settings…") {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
        Button("Quit StockHUD") {
            NSApp.terminate(nil)
        }
    }

    private func open(_ symbol: String) {
        guard let url = settings.linkTarget.url(for: symbol) else { return }
        NSWorkspace.shared.open(url)
    }
}

struct SessionBadge: View {
    let text: String
    let size: Double

    var body: some View {
        Text(text)
            .font(.system(size: size * 0.6, weight: .bold))
            .foregroundStyle(.orange)
            .padding(.horizontal, 3)
            .padding(.vertical, 1)
            .background(.orange.opacity(0.18), in: RoundedRectangle(cornerRadius: 3))
    }
}

struct MiniRowView: View {
    @EnvironmentObject private var settings: SettingsStore
    let symbol: String
    let quote: Quote?

    var body: some View {
        HStack(spacing: 6) {
            Text(symbol)
                .font(settings.font(size: settings.scaledFontSize, weight: .semibold))
                .foregroundStyle(.primary)
            if let badge = quote?.session.badge {
                SessionBadge(text: badge, size: settings.scaledFontSize)
            }
            Spacer(minLength: 8)
            if let quote {
                (
                    Text(QuoteFormatter.price(quote.price))
                        .foregroundStyle(.primary)
                    + Text("(" + QuoteFormatter.arrow(for: quote.direction) + QuoteFormatter.percent(quote.changePercent, signed: false) + ")")
                        .foregroundStyle(settings.color(for: quote.direction))
                )
                .font(settings.font(size: settings.scaledFontSize))
            } else {
                Text("—")
                    .font(settings.font(size: settings.scaledFontSize))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct DetailRowView: View {
    @EnvironmentObject private var settings: SettingsStore
    let symbol: String
    let quote: Quote?

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 5) {
                Text(symbol)
                    .font(settings.font(size: settings.scaledFontSize * 0.85, weight: .semibold))
                    .foregroundStyle(.secondary)
                if let badge = quote?.session.badge {
                    SessionBadge(text: badge, size: settings.scaledFontSize)
                }
            }
            if let quote {
                Text(QuoteFormatter.price(quote.price))
                    .font(settings.font(size: settings.scaledFontSize * 1.35, weight: .medium))
                    .foregroundStyle(.primary)
                HStack(spacing: 8) {
                    Text(QuoteFormatter.percent(quote.changePercent, signed: true))
                    Text(QuoteFormatter.change(quote.change, currency: quote.currency))
                }
                .font(settings.font(size: settings.scaledFontSize * 0.9))
                .foregroundStyle(settings.color(for: quote.direction))
            } else {
                Text("Loading…")
                    .font(settings.font(size: settings.scaledFontSize))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.bottom, 2)
    }
}
