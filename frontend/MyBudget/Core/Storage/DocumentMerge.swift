import Foundation

/// Reconciles the device's copy of the budget with the server's, now that the device is no longer the only writer.
///
/// Both copies are compared against the base — the last document the two agreed on — so each side's edits can be
/// told apart from the other's and kept. Only when both sides changed the same entry does one have to lose, and the
/// device wins: it holds what the person in front of it just did. An entry one side edited and the other deleted
/// is kept, since an edit is the more recent intent and a lost expense is worse than a stray one.
enum DocumentMerge {

    static func merge(base: BudgetDocument, local: BudgetDocument, remote: BudgetDocument) -> BudgetDocument {
        BudgetDocument(
            categories: merge(base: base.categories, local: local.categories, remote: remote.categories, same: ==),
            operations: merge(base: base.operations, local: local.operations, remote: remote.operations, same: sameOperation),
            budget: local.budget == base.budget ? remote.budget : local.budget,
            budgetHistory: merge(base: base.budgetHistory, local: local.budgetHistory, remote: remote.budgetHistory)
        )
    }

    /// Whether two documents hold the same budget. The server stamps its own `updatedAt` and keeps dates to the
    /// millisecond while the device encodes them to the second, so neither difference counts as an edit.
    static func sameContent(_ lhs: BudgetDocument, _ rhs: BudgetDocument) -> Bool {
        guard lhs.categories == rhs.categories,
              lhs.budget == rhs.budget,
              lhs.budgetHistory == rhs.budgetHistory,
              lhs.operations.count == rhs.operations.count else { return false }

        let indexed = Dictionary(rhs.operations.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        return lhs.operations.allSatisfy { operation in
            indexed[operation.id].map { sameOperation(operation, $0) } ?? false
        }
    }

    private static func sameOperation(_ lhs: Operation, _ rhs: Operation) -> Bool {
        comparable(lhs) == comparable(rhs)
    }

    private static func comparable(_ operation: Operation) -> Operation {
        var copy = operation
        copy.date = Date(timeIntervalSince1970: operation.date.timeIntervalSince1970.rounded(.down))
        copy.updatedAt = .distantPast
        return copy
    }

    private static func resolve<Value>(base: Value?, local: Value?, remote: Value?, same: (Value, Value) -> Bool) -> Value? {
        if matches(local, base, same) { return remote }
        if matches(remote, base, same) { return local }

        return local ?? remote
    }

    private static func matches<Value>(_ lhs: Value?, _ rhs: Value?, _ same: (Value, Value) -> Bool) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil): return true
        case let (lhs?, rhs?): return same(lhs, rhs)
        default: return false
        }
    }

    /// Merges two lists entry by entry. The result keeps the device's order, with anything only the server knows
    /// appended in the server's order.
    private static func merge<Item: Identifiable>(
        base: [Item],
        local: [Item],
        remote: [Item],
        same: (Item, Item) -> Bool
    ) -> [Item] where Item.ID == String {
        let baseById = Dictionary(base.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let localById = Dictionary(local.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let remoteById = Dictionary(remote.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        var seen = Set<String>()
        let order = (local + remote + base).map(\.id).filter { seen.insert($0).inserted }

        return order.compactMap { id in
            resolve(base: baseById[id], local: localById[id], remote: remoteById[id], same: same)
        }
    }

    private static func merge<Value: Equatable>(
        base: [String: Value],
        local: [String: Value],
        remote: [String: Value]
    ) -> [String: Value] {
        let keys = Set(base.keys).union(local.keys).union(remote.keys)

        return keys.reduce(into: [:]) { merged, key in
            merged[key] = resolve(base: base[key], local: local[key], remote: remote[key], same: ==)
        }
    }
}
