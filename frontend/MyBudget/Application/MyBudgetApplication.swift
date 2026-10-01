import SwiftUI

@main
struct MyBudgetApplication: App {
    @State private var store: LocalStore
    @State private var rates: ExchangeRates
    @State private var preferences: Preferences
    @State private var session: ApplicationSession

    init() {
        let store = LocalStore()
        let tokens = TokenStore()
        let api = APIClient(tokens: tokens)
        let rates = ExchangeRates(api: api)
        _store = State(initialValue: store)
        _rates = State(initialValue: rates)
        _preferences = State(initialValue: Preferences())
        _session = State(initialValue: ApplicationSession(store: store, rates: rates, tokens: tokens, api: api))
    }

    /// Read through `preferences` so the scene redraws in a language picked in Settings.
    private var interfaceLocale: Locale {
        _ = preferences.language
        return Localization.locale
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(rates)
                .environment(preferences)
                .environment(session)
                .environment(\.locale, interfaceLocale)
                .tint(Theme.accent)
                .preferredColorScheme(.dark)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
    }
}
