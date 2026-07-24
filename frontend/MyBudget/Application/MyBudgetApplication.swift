import SwiftUI

@main
struct MyBudgetApplication: App {
    @State private var store: LocalStore
    @State private var rates: ExchangeRates
    @State private var preferences: Preferences

    init() {
        _store = State(initialValue: LocalStore())
        _rates = State(initialValue: ExchangeRates())
        _preferences = State(initialValue: Preferences())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(rates)
                .environment(preferences)
                .tint(Theme.accent)
                .preferredColorScheme(.dark)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
    }
}
