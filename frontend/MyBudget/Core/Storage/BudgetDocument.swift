import Foundation

struct BudgetDocument: Codable, Equatable {
    var categories: [Category]
    var operations: [Operation]
    var budget: BudgetSettings

    var isEmpty: Bool {
        operations.isEmpty
    }
}
