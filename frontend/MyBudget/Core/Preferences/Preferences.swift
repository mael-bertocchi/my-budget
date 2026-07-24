import Foundation
import Observation

@MainActor
@Observable
final class Preferences {
    var lastUsedCurrencyCode: String {
        didSet { UserDefaults.standard.set(lastUsedCurrencyCode, forKey: Keys.lastUsedCurrency) }
    }

    var defaultPaymentMethod: PaymentMethod {
        didSet { UserDefaults.standard.set(defaultPaymentMethod.rawValue, forKey: Keys.defaultPaymentMethod) }
    }

    var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: Keys.haptics) }
    }

    init() {
        let defaults = UserDefaults.standard
        lastUsedCurrencyCode = defaults.string(forKey: Keys.lastUsedCurrency) ?? Currency.euro.code
        defaultPaymentMethod = defaults.string(forKey: Keys.defaultPaymentMethod)
            .flatMap(PaymentMethod.init(rawValue:)) ?? .card
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
        static let defaultPaymentMethod = "preferences.defaultPaymentMethod"
        static let haptics = "preferences.haptics"
    }
}
