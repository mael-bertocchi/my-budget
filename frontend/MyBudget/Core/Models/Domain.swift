import Foundation
import SwiftUI

enum OperationType: String, Codable, CaseIterable, Identifiable {
    case expense = "EXPENSE"
    case income = "INCOME"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        }
    }

    var systemImage: String {
        switch self {
        case .expense: return "arrow.down.left"
        case .income: return "arrow.up.right"
        }
    }
}

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case card = "CARD"
    case cash = "CASH"
    case transfer = "TRANSFER"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .card: return "Card"
        case .cash: return "Cash"
        case .transfer: return "Transfer"
        }
    }

    var systemImage: String {
        switch self {
        case .card: return "creditcard"
        case .cash: return "banknote"
        case .transfer: return "arrow.left.arrow.right"
        }
    }
}

enum MovementKind: String, Codable, CaseIterable, Identifiable {
    case deposit = "DEPOSIT"
    case withdrawal = "WITHDRAWAL"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .deposit: return "Deposit"
        case .withdrawal: return "Withdraw"
        }
    }

    var systemImage: String {
        switch self {
        case .deposit: return "arrow.down"
        case .withdrawal: return "arrow.up"
        }
    }
}

struct Category: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var name: String
    var symbol: String
    var colorHex: UInt32
    var monthlyLimit: Double
    var type: OperationType

    init(
        id: String = UUID().uuidString,
        name: String,
        symbol: String,
        colorHex: UInt32,
        monthlyLimit: Double,
        type: OperationType = .expense
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.monthlyLimit = monthlyLimit
        self.type = type
    }

    var color: Color { Color(hex: colorHex) }
    var tileBackground: Color { color.opacity(0.20) }
    var chipBackground: Color { color.opacity(0.18) }
}

struct Operation: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var date: Date
    var name: String
    var categoryId: String
    var location: String?
    var method: PaymentMethod
    var amount: Double
    var currencyCode: String
    var rateToEuro: Double
    var type: OperationType
    var isRecurring: Bool
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        date: Date,
        name: String,
        categoryId: String,
        location: String? = nil,
        method: PaymentMethod = .card,
        amount: Double,
        currencyCode: String = Currency.euro.code,
        rateToEuro: Double = 1,
        type: OperationType = .expense,
        isRecurring: Bool = false,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.name = name
        self.categoryId = categoryId
        self.location = location
        self.method = method
        self.amount = amount
        self.currencyCode = currencyCode
        self.rateToEuro = rateToEuro
        self.type = type
        self.isRecurring = isRecurring
        self.updatedAt = updatedAt
    }

    var isForeign: Bool { currencyCode != Currency.euro.code }

    var euroAmount: Double { amount * rateToEuro }

    var signedEuroAmount: Double { type == .income ? euroAmount : -euroAmount }
}

struct SavingsGoal: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var name: String
    var symbol: String
    var colorHex: UInt32
    var saved: Double
    var target: Double

    init(
        id: String = UUID().uuidString,
        name: String,
        symbol: String,
        colorHex: UInt32,
        saved: Double,
        target: Double
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colorHex = colorHex
        self.saved = saved
        self.target = target
    }

    var color: Color { Color(hex: colorHex) }
    var tileBackground: Color { color.opacity(0.20) }

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(1, saved / target)
    }
}

struct SavingsMovement: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var date: Date
    var name: String
    var note: String?
    var amount: Double
    var kind: MovementKind
    var goalId: String?

    init(
        id: String = UUID().uuidString,
        date: Date,
        name: String,
        note: String? = nil,
        amount: Double,
        kind: MovementKind,
        goalId: String? = nil
    ) {
        self.id = id
        self.date = date
        self.name = name
        self.note = note
        self.amount = amount
        self.kind = kind
        self.goalId = goalId
    }

    var signedAmount: Double { kind == .deposit ? amount : -amount }
}

struct BudgetSettings: Codable, Equatable {
    var monthlyLimit: Double

    static let `default` = BudgetSettings(monthlyLimit: 3000)
}

enum CategoryPalette {
    static let groceries: UInt32 = 0x3ECF8E
    static let dining: UInt32 = 0xFFA23E
    static let transport: UInt32 = 0x4D9BFF
    static let rent: UInt32 = 0xA78BFA
    static let shopping: UInt32 = 0xFF6BA8
    static let fun: UInt32 = 0x38D6D6
    static let income: UInt32 = 0x3ECF8E
    static let health: UInt32 = 0xFF8A5C

    static let goalGreen: UInt32 = 0x3ECF8E
    static let goalBlue: UInt32 = 0x4D9BFF
    static let goalViolet: UInt32 = 0xA78BFA

    static let all: [UInt32] = [
        groceries, dining, transport, rent, shopping, fun, health, goalBlue
    ]
}

extension Category {
    static let defaults: [Category] = [
        Category(id: "groceries", name: "Groceries", symbol: "cart", colorHex: CategoryPalette.groceries, monthlyLimit: 400),
        Category(id: "dining", name: "Dining", symbol: "fork.knife", colorHex: CategoryPalette.dining, monthlyLimit: 250),
        Category(id: "transport", name: "Transport", symbol: "tram", colorHex: CategoryPalette.transport, monthlyLimit: 150),
        Category(id: "rent", name: "Rent", symbol: "house", colorHex: CategoryPalette.rent, monthlyLimit: 1150),
        Category(id: "shopping", name: "Shopping", symbol: "bag", colorHex: CategoryPalette.shopping, monthlyLimit: 180),
        Category(id: "fun", name: "Fun", symbol: "film", colorHex: CategoryPalette.fun, monthlyLimit: 120),
        Category(id: "health", name: "Health", symbol: "dumbbell", colorHex: CategoryPalette.health, monthlyLimit: 80),
        Category(id: "income", name: "Income", symbol: "briefcase", colorHex: CategoryPalette.income, monthlyLimit: 0, type: .income)
    ]

    static let fallback = Category(
        id: "uncategorized",
        name: "Uncategorized",
        symbol: "circle.dashed",
        colorHex: 0xA78BFA,
        monthlyLimit: 0
    )
}

extension SavingsGoal {
    static let symbolChoices = [
        "checkmark.shield", "airplane", "laptopcomputer", "house", "car",
        "graduationcap", "gift", "heart", "star"
    ]
}
