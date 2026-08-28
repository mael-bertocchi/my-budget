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
        self.isRecurring = isRecurring
        self.updatedAt = updatedAt
    }

    var isForeign: Bool { currencyCode != Currency.euro.code }

    var euroAmount: Double { amount * rateToEuro }
}

struct BudgetSettings: Codable, Equatable {
    var monthlyLimit: Double

    static let `default` = BudgetSettings(monthlyLimit: 3000)
}

enum CategoryPalette {
    static let groceries: UInt32 = 0x3ECF8E
    static let restaurant: UInt32 = 0xFFA23E
    static let transport: UInt32 = 0x4D9BFF
    static let rent: UInt32 = 0xA78BFA
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
        Category(id: "transport", name: "Transport", symbol: "tram", colorHex: CategoryPalette.transport, monthlyLimit: 150),
        Category(id: "rent", name: "Rent", symbol: "house", colorHex: CategoryPalette.rent, monthlyLimit: 1150),
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
