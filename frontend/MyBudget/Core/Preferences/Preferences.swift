import Foundation
import Observation

@MainActor
@Observable
final class Preferences {
    var lastUsedCurrencyCode: String {
        didSet { UserDefaults.standard.set(lastUsedCurrencyCode, forKey: Keys.lastUsedCurrency) }
    }

    var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    init() {
        let defaults = UserDefaults.standard
        lastUsedCurrencyCode = defaults.string(forKey: Keys.lastUsedCurrency) ?? Currency.euro.code
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
    }

    func tap() {
        guard hapticsEnabled else { return }
        Haptics.tap()
    }

    func success() {
        guard hapticsEnabled else { return }
        Haptics.success()
    }

    private enum Keys {
        static let lastUsedCurrency = "preferences.lastUsedCurrency"
        static let haptics = "preferences.haptics"
    }
}
