import Foundation
import SwiftUI

struct Category: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var name: String
    var symbol: String
    var colorHex: UInt32
    var monthlyLimit: Double

    init(
        id: String = UUID().uuidString,
        name: String,
        symbol: String,
        colorHex: UInt32,
        monthlyLimit: Double
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.monthlyLimit = monthlyLimit
    }

    var color: Color { Color(hex: colorHex) }
    var tileBackground: Color { color.opacity(0.20) }
    var chipBackground: Color { color.opacity(0.18) }
}

struct Operation: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var date: Date
    var name: String
    var description: String?
    var categoryId: String
    var location: String?
    var amount: Double
    var currencyCode: String
    var rateToEuro: Double
    var isOnline: Bool
    var isRecurring: Bool
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        date: Date,
        name: String,
        description: String? = nil,
        categoryId: String,
        location: String? = nil,
        amount: Double,
        currencyCode: String = Currency.euro.code,
        rateToEuro: Double = 1,
        isOnline: Bool = false,
        isRecurring: Bool = false,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.name = name
        self.description = description
        self.categoryId = categoryId
        self.location = location
        self.amount = amount
        self.currencyCode = currencyCode
        self.rateToEuro = rateToEuro
        self.isOnline = isOnline
        self.isRecurring = isRecurring
        self.updatedAt = updatedAt
    }

    var isForeign: Bool { currencyCode != Currency.euro.code }

    var euroAmount: Double { amount * rateToEuro }
}

/// A charge of the same size every month — rent, a transport pass, a subscription. It is never logged
/// as an operation: the month's budget simply starts with it already taken out, so the ring and the
/// per-day figure speak about money that is genuinely still free to spend.
struct FixedCost: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var name: String
    var amount: Double

    init(id: String = UUID().uuidString, name: String, amount: Double) {
        self.id = id
        self.name = name
        self.amount = amount
    }
}

struct BudgetSettings: Codable, Equatable {
    var monthlyLimit: Double
    var fixedCosts: [FixedCost]

    init(monthlyLimit: Double, fixedCosts: [FixedCost] = []) {
        self.monthlyLimit = monthlyLimit
        self.fixedCosts = fixedCosts
    }

    /// A document written before fixed costs existed carries no list. Decoding it as an empty one keeps
    /// the stored monthly limit instead of failing and dropping the whole budget back to its default.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        monthlyLimit = try container.decode(Double.self, forKey: .monthlyLimit)
        fixedCosts = try container.decodeIfPresent([FixedCost].self, forKey: .fixedCosts) ?? []
    }

    var fixedCostsTotal: Double { fixedCosts.reduce(0) { $0 + $1.amount } }

    /// The part of the budget the month is free to spend, once every fixed charge is set aside.
    var spendable: Double { max(0, monthlyLimit - fixedCostsTotal) }

    static let `default` = BudgetSettings(
        monthlyLimit: 3000,
        fixedCosts: [FixedCost(id: "rent", name: "Rent", amount: 1150)]
    )
}

struct MonthlyBudget: Codable, Equatable {
    var monthlyLimit: Double
    var categoryLimits: [String: Double]
    var fixedCostsTotal: Double

    init(monthlyLimit: Double, categoryLimits: [String: Double], fixedCostsTotal: Double = 0) {
        self.monthlyLimit = monthlyLimit
        self.categoryLimits = categoryLimits
        self.fixedCostsTotal = fixedCostsTotal
    }

    /// Months sealed before fixed costs existed carry no total, and had none: they read back as zero,
    /// leaving those months to render exactly as they always did.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        monthlyLimit = try container.decode(Double.self, forKey: .monthlyLimit)
        categoryLimits = try container.decode([String: Double].self, forKey: .categoryLimits)
        fixedCostsTotal = try container.decodeIfPresent(Double.self, forKey: .fixedCostsTotal) ?? 0
    }

    var spendable: Double { max(0, monthlyLimit - fixedCostsTotal) }

    func limit(for categoryId: String) -> Double {
        categoryLimits[categoryId] ?? 0
    }
}

enum CategoryPalette {
    static let groceries: UInt32 = 0x3ECF8E
    static let restaurant: UInt32 = 0xFFA23E
    static let bar: UInt32 = 0x8FE05C
    static let coffee: UInt32 = 0xDF74E7
    static let transport: UInt32 = 0x4D9BFF
    static let shopping: UInt32 = 0xFF6BA8
    static let fun: UInt32 = 0x38D6D6
    static let health: UInt32 = 0xFF8A5C
    static let school: UInt32 = 0xFFD166
    static let miscellaneous: UInt32 = 0x9BA1B0
}

extension Category {
    static let defaults: [Category] = [
        Category(id: "groceries", name: "Groceries", symbol: "cart", colorHex: CategoryPalette.groceries, monthlyLimit: 400),
        Category(id: "restaurant", name: "Restaurant", symbol: "fork.knife", colorHex: CategoryPalette.restaurant, monthlyLimit: 250),
        Category(id: "bar", name: "Bar", symbol: "wineglass", colorHex: CategoryPalette.bar, monthlyLimit: 100),
        Category(id: "coffee", name: "Coffee", symbol: "cup.and.saucer", colorHex: CategoryPalette.coffee, monthlyLimit: 50),
        Category(id: "transport", name: "Transport", symbol: "tram", colorHex: CategoryPalette.transport, monthlyLimit: 150),
        Category(id: "shopping", name: "Shopping", symbol: "bag", colorHex: CategoryPalette.shopping, monthlyLimit: 180),
        Category(id: "fun", name: "Fun", symbol: "film", colorHex: CategoryPalette.fun, monthlyLimit: 120),
        Category(id: "health", name: "Health", symbol: "dumbbell", colorHex: CategoryPalette.health, monthlyLimit: 80),
        Category(id: "school", name: "School", symbol: "graduationcap", colorHex: CategoryPalette.school, monthlyLimit: 120),
        Category(id: "miscellaneous", name: "Miscellaneous", symbol: "square.grid.2x2", colorHex: CategoryPalette.miscellaneous, monthlyLimit: 100)
    ]

    static let fallback = Category(
        id: "uncategorized",
        name: "Uncategorized",
        symbol: "circle.dashed",
        colorHex: 0xA78BFA,
        monthlyLimit: 0
    )
}
