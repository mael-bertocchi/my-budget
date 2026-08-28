import Foundation

enum LegacyDocument {
    static func migrated(_ data: Data) -> Data {
        guard var object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return data }
        for key in ["categories", "operations"] {
            guard let items = object[key] as? [[String: Any]] else { continue }
            object[key] = items.filter { ($0["type"] as? String) != "INCOME" }
        }
        if let operations = object["operations"] as? [[String: Any]] {
            object["operations"] = operations.map { operation in
                var updated = operation
                if updated["isOnline"] == nil { updated["isOnline"] = false }
                return updated
            }
        }
        guard let migrated = try? JSONSerialization.data(withJSONObject: object) else { return data }
        return migrated
    }
}
