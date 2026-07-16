import SwiftUI

struct SymbolsSettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var newSymbol = ""

    var body: some View {
        VStack(spacing: 12) {
            List {
                ForEach(settings.symbols, id: \.self) { symbol in
                    HStack {
                        Text(symbol)
                        Spacer()
                        Button {
                            settings.removeSymbol(symbol)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onMove { indices, offset in
                    settings.symbols.move(fromOffsets: indices, toOffset: offset)
                }
            }
            .frame(minHeight: 180)

            HStack {
                TextField("Symbol (e.g. AAPL, BTC-USD)", text: $newSymbol)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(add)
                Button("Add", action: add)
                    .disabled(newSymbol.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Text("Yahoo Finance symbols: stocks (NVDA), crypto (BTC-USD), indices (^GSPC), FX (KRW=X)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
    }

    private func add() {
        settings.addSymbol(newSymbol)
        newSymbol = ""
    }
}
