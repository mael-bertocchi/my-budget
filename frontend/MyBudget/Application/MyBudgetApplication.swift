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
        _store = State(initialValue: store)
        _rates = State(initialValue: ExchangeRates())
        _preferences = State(initialValue: Preferences())
        _session = State(initialValue: ApplicationSession(store: store, tokens: tokens, api: api))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(rates)
                .environment(preferences)
                .environment(session)
                .tint(Theme.accent)
                .preferredColorScheme(.dark)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
    }
}
