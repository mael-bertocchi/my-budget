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

    var language: InterfaceLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Keys.language)
            Localization.apply(language)
        }
    }

    init() {
        let defaults = UserDefaults.standard
        lastUsedCurrencyCode = defaults.string(forKey: Keys.lastUsedCurrency) ?? Currency.euro.code
        hapticsEnabled = defaults.object(forKey: Keys.haptics) as? Bool ?? true
        language = defaults.string(forKey: Keys.language).flatMap(InterfaceLanguage.init(rawValue:)) ?? .automatic
        Localization.apply(language)
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
        static let language = "preferences.language"
    }
}
