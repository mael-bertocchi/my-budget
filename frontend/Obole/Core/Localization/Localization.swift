import Foundation

/// The languages the interface can be shown in. `automatic` follows the device (or the language picked for the
/// app in the iOS settings) and falls back to English when the device speaks neither.
enum InterfaceLanguage: String, CaseIterable, Identifiable {
    case automatic
    case english = "en"
    case french = "fr"

    var id: String { rawValue }

    /// How the picker names it: each language in itself, so it can be found whatever the interface speaks.
    var title: String {
        switch self {
        case .automatic: return String(appLocalized: "Automatic")
        case .english: return "English"
        case .french: return "Français"
        }
    }
}

/// The language the interface is shown in. It can change while the app runs, which the main bundle can't follow:
/// it settles its localization once, at launch. So views take it from the `locale` environment value the root sets,
/// and strings built outside a view go through `String(appLocalized:)`, which looks them up in it.
enum Localization {
    static let supported = ["en", "fr"]

    private(set) static var locale = Locale(identifier: resolve(.automatic))

    static var isFrench: Bool {
        locale.language.languageCode == .french
    }

    static func apply(_ language: InterfaceLanguage) {
        locale = Locale(identifier: resolve(language))
    }

    private static func resolve(_ language: InterfaceLanguage) -> String {
        guard language == .automatic else { return language.rawValue }
        return Bundle.preferredLocalizations(from: supported, forPreferences: Locale.preferredLanguages).first ?? "en"
    }
}

extension String {
    /// Looks a string up in the language the interface is set to. `String(localized:)` would answer in the
    /// language the app launched in, which stops being the right one as soon as another is picked in Settings.
    init(appLocalized resource: LocalizedStringResource) {
        var resource = resource
        resource.locale = Localization.locale
        self.init(localized: resource)
    }
}
