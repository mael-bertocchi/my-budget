import Foundation
import Security

enum Keychain {
    private static let service = "fr.mael-bertocchi.my-budget"

    static func set(_ value: String, for key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func remove(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

@MainActor
final class TokenStore {
    private enum Keys {
        static let access = "identity.accessToken"
        static let refresh = "identity.refreshToken"
    }

    private(set) var accessToken: String?
    private(set) var refreshToken: String?

    init() {
        accessToken = Keychain.get(Keys.access)
        refreshToken = Keychain.get(Keys.refresh)
    }

    var hasTokens: Bool {
        refreshToken != nil
    }

    func store(access: String, refresh: String) {
        accessToken = access
        refreshToken = refresh
        Keychain.set(access, for: Keys.access)
        Keychain.set(refresh, for: Keys.refresh)
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
        Keychain.remove(Keys.access)
        Keychain.remove(Keys.refresh)
    }
}
