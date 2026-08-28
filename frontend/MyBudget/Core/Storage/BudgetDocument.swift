import Foundation

struct BudgetDocument: Codable, Equatable {
    var categories: [Category]
    var operations: [Operation]
    var budget: BudgetSettings
    var budgetHistory: [String: MonthlyBudget]

    var isEmpty: Bool {
        operations.isEmpty
    }
}
