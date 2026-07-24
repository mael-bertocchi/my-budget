# 💶 My Budget — iOS App

The native **iOS** app, built entirely in SwiftUI against the iOS 26 "Liquid Glass" design language: translucent, blurred materials floating over ambient colour glows on a pure-black base.

## Highlights

- **Budget ring** — left to spend, spent, days left, and a per-day allowance that recomputes as the month runs down.
- **Per-category limits** — a tinted tile, a progress bar, and an over-budget state that turns everything red.
- **Month stepper** — walk back through previous months; every figure recomputes.
- **History ledger** — day groups with day totals, a search field, and filter chips for type and category.
- **Multi-currency** — pick the entry currency; the euro equivalent recomputes live and is stored with the operation, so past entries keep the rate they were logged at.
- **Savings** — total saved, monthly trend, goals with progress rings, and deposit/withdraw movements.

## Screens

**Budget · History · Savings · Settings** — plus a floating **＋** that presents the *New operation* sheet.

## Tech

Swift · SwiftUI · Observation — a single target (`MyBudget`), no dependencies, no network.

## Architecture

```
MyBudget/
├─ Application/    App entry, root shell, floating tab bar
├─ Core/
│  ├─ Budget/      Derived selectors (month summary, category spend, day groups)
│  ├─ Formatting/  Euro, amount, rate and date formatting
│  ├─ Models/      Domain types (Category, Operation, SavingsGoal, …)
│  ├─ Money/       Currencies and euro exchange rates
│  ├─ Preferences/ Last-used currency, default payment method, haptics
│  ├─ Storage/     LocalStore (JSON snapshot) + debug seed
│  └─ Theme/       Design tokens, haptics
├─ Features/       One folder per screen (Budget, History, Operations, Savings, Settings)
└─ UIComponents/   Liquid glass surfaces, buttons, progress, tiles
```

State lives in three `@Observable` objects injected through the environment: `LocalStore` (data, persisted to Application Support as JSON), `ExchangeRates` (currencies), and `Preferences` (UserDefaults). Views read them directly and derive everything else through `BudgetMath` — no view models.

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

## Running Demonstration

The shared scheme launches with `-demo` **enabled**, so pressing Run seeds the sample month from the design handoff. Demo seeding only exists in Debug builds.

To start from an empty app, edit the scheme (**Product ▸ Scheme ▸ Edit Scheme… ▸ Run ▸ Arguments**) and untick `-demo`.

| Flag | Effect |
| --- | --- |
| `-demo` | Seeds the sample month, savings and goals (on by default) |
| `-demo-empty` | Wipes the store instead (use alone, not with `-demo`) |
| `-tab budget\|history\|savings\|settings` | Opens directly on a given tab |
| `-open add` | Opens straight into the New operation sheet |

Example: `-demo -tab savings` launches on the Savings tab with data.
