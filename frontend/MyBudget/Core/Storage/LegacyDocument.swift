import Foundation

enum LegacyDocument {
    static func withoutIncome(_ data: Data) -> Data {
        guard var object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return data }
        for key in ["categories", "operations"] {
            guard let items = object[key] as? [[String: Any]] else { continue }
            object[key] = items.filter { ($0["type"] as? String) != "INCOME" }
        }
        guard let stripped = try? JSONSerialization.data(withJSONObject: object) else { return data }
        return stripped
    }
}
