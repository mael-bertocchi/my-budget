import Foundation
import Observation

enum JSONCoding {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

@MainActor
@Observable
final class LocalStore {
    private(set) var categories: [Category] = []
    private(set) var operations: [Operation] = []
    private(set) var goals: [SavingsGoal] = []
    private(set) var movements: [SavingsMovement] = []
    private(set) var savingsBalance: Double = 0
    private(set) var budget: BudgetSettings = .default

    init() {
        load()
        if categories.isEmpty {
            categories = Category.defaults
            save()
        }
    }

    func category(id: String) -> Category? {
        categories.first { $0.id == id }
    }

    func categoryOrFallback(id: String) -> Category {
        category(id: id) ?? .fallback
    }

    var expenseCategories: [Category] {
        categories.filter { $0.type == .expense }
    }

    var incomeCategories: [Category] {
        categories.filter { $0.type == .income }
    }

    func categories(for type: OperationType) -> [Category] {
        type == .income ? incomeCategories : expenseCategories
    }

    func upsertCategory(_ category: Category) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        } else {
            categories.append(category)
        }
        save()
    }

    func updateLimit(categoryId: String, limit: Double) {
        guard let index = categories.firstIndex(where: { $0.id == categoryId }) else { return }
        categories[index].monthlyLimit = max(0, limit)
        save()
    }

    func deleteCategory(id: String) {
        categories.removeAll { $0.id == id }
        operations.removeAll { $0.categoryId == id }
        save()
    }

    func upsertOperation(_ operation: Operation) {
        var updated = operation
        updated.updatedAt = .now
        if let index = operations.firstIndex(where: { $0.id == operation.id }) {
            operations[index] = updated
        } else {
            operations.append(updated)
        }
        sortOperations()
        save()
    }

    func deleteOperation(id: String) {
        operations.removeAll { $0.id == id }
        save()
    }

    func operation(id: String) -> Operation? {
        operations.first { $0.id == id }
    }

    func setMonthlyLimit(_ limit: Double) {
        budget.monthlyLimit = max(0, limit)
        save()
    }

    func upsertGoal(_ goal: SavingsGoal) {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
        } else {
            goals.append(goal)
        }
        save()
    }

    func deleteGoal(id: String) {
        goals.removeAll { $0.id == id }
        movements = movements.map { movement in
            var updated = movement
            if updated.goalId == id { updated.goalId = nil }
            return updated
        }
        save()
    }

    func deposit(amount: Double, name: String, goalId: String?, date: Date = .now) {
        guard amount > 0 else { return }
        savingsBalance += amount
        if let goalId, let index = goals.firstIndex(where: { $0.id == goalId }) {
            goals[index].saved += amount
        }
        movements.append(SavingsMovement(
            date: date,
            name: name,
            note: goalId.flatMap { id in goals.first { $0.id == id }?.name },
            amount: amount,
            kind: .deposit,
            goalId: goalId
        ))
        sortMovements()
        save()
    }

    func withdraw(amount: Double, name: String, goalId: String?, date: Date = .now) {
        guard amount > 0 else { return }
        savingsBalance -= amount
        if let goalId, let index = goals.firstIndex(where: { $0.id == goalId }) {
            goals[index].saved = max(0, goals[index].saved - amount)
        }
        movements.append(SavingsMovement(
            date: date,
            name: name,
            note: goalId.flatMap { id in goals.first { $0.id == id }?.name },
            amount: amount,
            kind: .withdrawal,
            goalId: goalId
        ))
        sortMovements()
        save()
    }

    func deleteMovement(id: String) {
        guard let movement = movements.first(where: { $0.id == id }) else { return }
        savingsBalance -= movement.signedAmount
        if let goalId = movement.goalId, let index = goals.firstIndex(where: { $0.id == goalId }) {
            goals[index].saved = max(0, goals[index].saved - movement.signedAmount)
        }
        movements.removeAll { $0.id == id }
        save()
    }

    func replaceAll(
        categories: [Category],
        operations: [Operation],
        goals: [SavingsGoal],
        movements: [SavingsMovement],
        savingsBalance: Double,
        budget: BudgetSettings
    ) {
        self.categories = categories
        self.operations = operations
        self.goals = goals
        self.movements = movements
        self.savingsBalance = savingsBalance
        self.budget = budget
        sortOperations()
        sortMovements()
        save()
    }

    func clearAll() {
        categories = Category.defaults
        operations = []
        goals = []
        movements = []
        savingsBalance = 0
        budget = .default
        save()
    }

    private struct Snapshot: Codable {
        var categories: [Category]
        var operations: [Operation]
        var goals: [SavingsGoal]
        var movements: [SavingsMovement]
        var savingsBalance: Double
        var budget: BudgetSettings
    }

    private static var fileURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "local-store.json")
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let snapshot = try? JSONCoding.decoder.decode(Snapshot.self, from: data) else { return }
        categories = snapshot.categories
        operations = snapshot.operations
        goals = snapshot.goals
        movements = snapshot.movements
        savingsBalance = snapshot.savingsBalance
        budget = snapshot.budget
        sortOperations()
        sortMovements()
    }

    func save() {
        let snapshot = Snapshot(
            categories: categories,
            operations: operations,
            goals: goals,
            movements: movements,
            savingsBalance: savingsBalance,
            budget: budget
        )
        if let data = try? JSONCoding.encoder.encode(snapshot) {
            try? data.write(to: Self.fileURL, options: .atomic)
        }
    }

    private func sortOperations() {
        operations.sort { $0.date > $1.date }
    }

    private func sortMovements() {
        movements.sort { $0.date > $1.date }
    }
}
