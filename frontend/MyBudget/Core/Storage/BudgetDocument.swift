import Foundation

struct BudgetDocument: Codable, Equatable {
    var categories: [Category]
    var operations: [Operation]
    var goals: [SavingsGoal]
    var movements: [SavingsMovement]
    var savingsBalance: Double
    var budget: BudgetSettings

    var isEmpty: Bool {
        operations.isEmpty && goals.isEmpty && movements.isEmpty && savingsBalance == 0
    }
}
