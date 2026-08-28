# 💶 My Budget — Frontend

The native **iOS** app, built entirely in SwiftUI against the iOS 26 "Liquid Glass" design language: translucent, blurred materials floating over ambient colour glows on a pure-black base.

## Highlights

- **Budget ring** — left to spend, spent, days left, and a per-day allowance that recomputes as the month runs down.
- **Per-category limits** — a tinted tile, a progress bar, and an over-budget state that turns everything red.
- **Month stepper** — walk back through previous months; every figure recomputes.
- **History ledger** — day groups with day totals, a search field, and filter chips for type and category.
- **Current location** — the *New operation* sheet fills its location field from where you are, reverse geocoded to a place and a city.
- **Multi-currency** — pick the entry currency; the euro equivalent recomputes live and is stored with the operation, so past entries keep the rate they were logged at.
- **Savings** — total saved, monthly trend, goals with progress rings, and deposit/withdraw movements.
- **Sign in & sync** — one account (its password lives in the backend's environment); every change is pushed to the server and restored on a fresh device. Offline changes stay local and reconcile when the connection returns.

## Screens

**Sign in** → **Budget · History · Savings · Settings** — a **＋** in the Budget and History headers presents the *New operation* sheet. Navigation uses the native iOS 26 Liquid Glass tab bar, which minimizes as you scroll.

## Tech

Swift · SwiftUI · Observation · URLSession — a single target (`MyBudget`), no third-party dependencies.

## Architecture

```
MyBudget/
├─ Application/    App entry, root shell (auth gate + native TabView)
├─ Core/
│  ├─ Budget/      Derived selectors (month summary, category spend, day groups)
│  ├─ Formatting/  Euro, amount, rate and date formatting
│  ├─ Location/    LocationProvider — one-shot fix, reverse geocoded to a place name
│  ├─ Models/      Domain types (Category, Operation, SavingsGoal, …)
│  ├─ Money/       Currencies and euro exchange rates
│  ├─ Networking/  APIClient (bearer + refresh-on-401), Keychain token store
│  ├─ Preferences/ Last-used currency, default payment method, haptics
│  ├─ Session/     ApplicationSession — auth state + pull/push sync
│  ├─ Storage/     LocalStore (JSON snapshot), BudgetDocument, debug seed
│  └─ Theme/       Design tokens, haptics
├─ Features/       One folder per screen (Identity, Budget, History, Operations, Savings, Settings)
└─ UIComponents/   Liquid glass surfaces, buttons, progress, tiles
```

State lives in `@Observable` objects injected through the environment: `LocalStore` (data, persisted to Application Support as JSON), `ExchangeRates` (currencies), `Preferences` (UserDefaults), and `ApplicationSession` (auth + sync). Views read them directly and derive everything else through `BudgetMath` — no view models.

### Sync model

The local JSON store is the working copy; the server holds the durable one. On sign-in the app pulls the server's budget document (or, if the server is empty, uploads what's on the device). After that, every mutation debounces a full-document `PUT /v1/state`; a failed push flips the Settings badge to **Offline** and retries when the app next becomes active. Access tokens refresh automatically on a `401`; when the refresh token is gone, the app returns to the sign-in screen.

The app talks to a fixed HTTPS endpoint — `https://my-budget.mael-bertocchi.fr` (`ApplicationSession.serverURL`) — shown in Settings. To develop against a local server, change that constant.

## Local Development

1. Open the project in Xcode

```bash
open MyBudget.xcodeproj
```

2. Build the application

```bash
xcodebuild -project MyBudget.xcodeproj -scheme MyBudget -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

> Note: To run the simulator, go to Xcode and press the run button.

## Signing in

The app needs the backend running at `https://my-budget.mael-bertocchi.fr`. Sign in with the username and password set in the backend's environment (`IDENTITY_USERNAME` / `IDENTITY_PASSWORD`).

## Running Demonstration

The shared scheme launches with `-demo` **enabled**, so pressing Run seeds the sample month from the design handoff and skips sign-in entirely (no backend needed). Demo mode only exists in Debug builds and never touches the network.

To reach the real sign-in screen, edit the scheme (**Product ▸ Scheme ▸ Edit Scheme… ▸ Run ▸ Arguments**) and untick `-demo`.

| Flag | Effect |
| --- | --- |
| `-demo` | Seeds the sample month and skips sign-in (on by default) |
| `-demo-empty` | Skips sign-in with an empty store (use alone, not with `-demo`) |
| `-tab budget\|history\|savings\|settings` | Opens directly on a given tab |
| `-open add` | Opens straight into the New operation sheet |

Example: `-demo -tab savings` launches on the Savings tab with data.
