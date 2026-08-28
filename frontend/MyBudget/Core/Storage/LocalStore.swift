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
    private(set) var budget: BudgetSettings = .default

    @ObservationIgnored var onChange: (() -> Void)?
    @ObservationIgnored private var isApplyingRemote = false

    init() {
        load()
        if categories.isEmpty {
            categories = Category.defaults
            save()
        }
    }

    func document() -> BudgetDocument {
        BudgetDocument(
            categories: categories,
            operations: operations,
            budget: budget
        )
    }

    func applyRemote(_ document: BudgetDocument) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }
        categories = document.categories
        operations = document.operations
        budget = document.budget
        sortOperations()
        persist()
    }

    func category(id: String) -> Category? {
        categories.first { $0.id == id }
    }

    func categoryOrFallback(id: String) -> Category {
        category(id: id) ?? .fallback
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

    var latestLocation: String? {
        operations.first { !$0.isOnline && !($0.location ?? "").isEmpty }?.location
    }

    func setMonthlyLimit(_ limit: Double) {
        budget.monthlyLimit = max(0, limit)
        save()
    }

    func replaceAll(
        categories: [Category],
        operations: [Operation],
        budget: BudgetSettings
    ) {
        self.categories = categories
        self.operations = operations
        self.budget = budget
        sortOperations()
        save()
    }

    func clearAll() {
        categories = Category.defaults
        operations = []
        budget = .default
        save()
    }

    private static var fileURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "local-store.json")
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let document = try? JSONCoding.decoder.decode(BudgetDocument.self, from: LegacyDocument.migrated(data)) else { return }
        categories = document.categories
        operations = document.operations
        budget = document.budget
        sortOperations()
    }

    func save() {
        persist()
        if !isApplyingRemote {
            onChange?()
        }
    }

    private func persist() {
        if let data = try? JSONCoding.encoder.encode(document()) {
            try? data.write(to: Self.fileURL, options: .atomic)
        }
    }

    private func sortOperations() {
        operations.sort { $0.date > $1.date }
    }
}
