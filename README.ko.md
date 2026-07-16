# StockHUD

[English](README.md) | **한국어**

macOS에서 항상 화면 위에 떠 있는 초경량 주식 시세 HUD.

차트도, 뉴스도, 로그인도 없습니다 — 게임 HUD처럼 모든 앱 위에 떠서 현재 가격과 등락률만 보여줍니다.

```
──────────────────────────
 NVDA   $212.50(▲0.33%)
 TSLA   $334.18(▼0.81%)
 SNDK   $1,522.00(▼5.76%)
 BTC-USD $121,540.00(▲0.45%)
──────────────────────────
```

## 기능

- **Always On Top** — Xcode, Chrome, 전체 화면 앱, 모든 Space 위에 표시
- **포커스를 뺏지 않음** — non-activating 패널이라 클릭해도 작업이 끊기지 않습니다
- **시간외 거래** — 프리장(`PRE`)·애프터장(`AH`) 가격을 세션 뱃지와 함께 표시
- **미니 / 상세 모드** — 종목당 한 줄 또는 가격+등락률+등락금액
- **메뉴바 앱** — Dock 아이콘 없음, ⌘⇧H로 HUD 표시/숨김
- 종목 **더블클릭**으로 TradingView, Yahoo Finance, Finviz, Stock Analysis 열기
- **자유로운 커스텀** — 투명도, 크기, 폰트, 색상, 여백, 모서리, 클릭 통과, 위치 잠금
- **자동 갱신** — 1초~60초 주기
- **API 키 불필요** — Webull(배치 요청, 시간외 지원) + 자동 Yahoo Finance 폴백(크립토·지수·환율)
- **다국어** — English, 한국어, 日本語, 简体中文, Español, Deutsch, Français

## 요구사항

- macOS 14 이상
- 빌드에는 Xcode 15 이상과 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 필요

## 빌드

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project StockHUD.xcodeproj -scheme StockHUD -configuration Release build
```

또는 `xcodegen generate` 후 `StockHUD.xcodeproj`를 Xcode에서 열어 실행하면 됩니다.

## 사용법

- 실행하면 HUD가 나타납니다. 원하는 곳으로 드래그하면 위치가 저장됩니다
- **HUD 우클릭** — 모드 전환, 종목 삭제, 설정, 종료
- **메뉴바 아이콘**(📈) — HUD 표시/숨김, 설정, 종료
- 종목 추가는 설정 → 종목 탭에서: 주식(`NVDA`), 크립토(`BTC-USD`), 지수(`^GSPC`), 환율(`KRW=X`)

## 참고

- 시세 데이터는 비공식 공개 엔드포인트(Webull, Yahoo Finance)를 사용합니다. 언제든 변경되거나 제한될 수 있으며, 이 앱은 개인적·참고용입니다. 투자 조언이 아닙니다.
- Xcode 프로젝트는 생성물입니다. `.xcodeproj`가 아니라 `project.yml`을 수정하세요.

---

SwiftUI + NSPanel · MVVM · Swift Concurrency
