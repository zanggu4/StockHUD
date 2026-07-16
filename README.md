# StockHUD

An ultra-light, always-on-top stock ticker HUD for macOS.

No charts, no news, no login — just current prices and change, floating over every app like a game HUD.

```
──────────────────────────
 NVDA   $212.50(▲0.33%)
 TSLA   $334.18(▼0.81%)
 SNDK   $1,522.00(▼5.76%)
 BTC-USD $121,540.00(▲0.45%)
──────────────────────────
```

## Features

- **Always on top** — floats over Xcode, Chrome, fullscreen apps, every Space
- **Never steals focus** — non-activating panel; clicks don't interrupt your work
- **Extended hours** — pre-market (`PRE`) and after-hours (`AH`) prices with session badges
- **Mini / detail modes** — one-liner per symbol, or price + change + amount
- **Menu bar app** — no Dock icon; toggle the HUD with ⌘⇧H
- **Double-click** a symbol to open it on TradingView, Yahoo Finance, Finviz, or Stock Analysis
- **Fully adjustable** — opacity, size, font, colors, padding, corner radius, click-through, position lock
- **Auto refresh** — 1s to 60s interval
- **No API key required** — quotes from Webull (batch, extended hours) with automatic Yahoo Finance fallback (crypto, indices, FX)
- **Localized** — English, 한국어, 日本語, 简体中文, Español, Deutsch, Français

## Requirements

- macOS 14+
- Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) to build

## Build

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project StockHUD.xcodeproj -scheme StockHUD -configuration Release build
```

Or open `StockHUD.xcodeproj` in Xcode after `xcodegen generate` and hit Run.

## Usage

- The HUD appears on launch; drag it anywhere — position is remembered
- **Right-click the HUD** for mode switch, symbol removal, settings, quit
- **Menu bar icon** (📈) → Show/Hide HUD, Settings, Quit
- Add symbols in Settings → Symbols: stocks (`NVDA`), crypto (`BTC-USD`), indices (`^GSPC`), FX (`KRW=X`)

## Notes

- Quote data comes from unofficial public endpoints (Webull, Yahoo Finance). They may change or rate-limit at any time; this app is for personal, informational use only — not investment advice.
- The Xcode project is generated: edit `project.yml`, not the `.xcodeproj`.

---

Built with SwiftUI + NSPanel · MVVM · Swift Concurrency
