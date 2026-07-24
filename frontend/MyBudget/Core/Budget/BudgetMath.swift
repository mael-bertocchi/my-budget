import Foundation

struct CategorySpend: Identifiable, Equatable {
    var category: Category
    var spent: Double

    var id: String { category.id }
    var limit: Double { category.monthlyLimit }
    var isOverBudget: Bool { spent > limit && limit > 0 }

    var progress: Double {
        guard limit > 0 else { return spent > 0 ? 1 : 0 }
        return min(1, spent / limit)
    }
}

struct MonthSummary: Equatable {
    var limit: Double
    var spent: Double
    var income: Double
    var daysLeft: Int

    var left: Double { limit - spent }

    var progress: Double {
        guard limit > 0 else { return spent > 0 ? 1 : 0 }
        return min(1, max(0, spent / limit))
    }

    var perDay: Double {
        guard daysLeft > 0 else { return 0 }
        return max(0, left) / Double(daysLeft)
    }
}

struct DayGroup: Identifiable, Equatable {
    var date: Date
    var operations: [Operation]

    var id: Date { date }

    var total: Double {
        operations.reduce(0) { $0 + $1.signedEuroAmount }
    }
}

struct MonthlySavingPoint: Identifiable, Equatable {
    var month: Date
    var amount: Double

    var id: Date { month }
}

enum BudgetMath {

    static var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    static func monthStart(_ date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    static func shiftMonth(_ date: Date, by months: Int) -> Date {
        calendar.date(byAdding: .month, value: months, to: monthStart(date)) ?? date
    }

    static func isSameMonth(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, equalTo: rhs, toGranularity: .month)
    }

    static func operations(_ operations: [Operation], in month: Date) -> [Operation] {
        operations.filter { isSameMonth($0.date, month) }
    }

    static func daysLeft(in month: Date, now: Date = .now) -> Int {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return 0 }
        let total = range.count
        if isSameMonth(month, now) {
            let today = calendar.component(.day, from: now)
            return max(0, total - today + 1)
        }
        return month < monthStart(now) ? 0 : total
    }

    static func summary(
        operations: [Operation],
        month: Date,
        settings: BudgetSettings,
        now: Date = .now
    ) -> MonthSummary {
        let scoped = self.operations(operations, in: month)
        let spent = scoped.filter { $0.type == .expense }.reduce(0) { $0 + $1.euroAmount }
        let income = scoped.filter { $0.type == .income }.reduce(0) { $0 + $1.euroAmount }
        return MonthSummary(
            limit: settings.monthlyLimit,
            spent: spent,
            income: income,
            daysLeft: daysLeft(in: month, now: now)
        )
    }

    static func categorySpends(
        operations: [Operation],
        categories: [Category],
        month: Date
    ) -> [CategorySpend] {
        let scoped = self.operations(operations, in: month).filter { $0.type == .expense }
        var totals: [String: Double] = [:]
        for operation in scoped {
            totals[operation.categoryId, default: 0] += operation.euroAmount
        }
        return categories
            .filter { $0.type == .expense }
            .map { CategorySpend(category: $0, spent: totals[$0.id] ?? 0) }
    }

    static func dayGroups(_ operations: [Operation]) -> [DayGroup] {
        let grouped = Dictionary(grouping: operations) { calendar.startOfDay(for: $0.date) }
        return grouped
            .map { DayGroup(date: $0.key, operations: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.date > $1.date }
    }

    static func monthlySavings(
        movements: [SavingsMovement],
        months: Int = 6,
        now: Date = .now
    ) -> [MonthlySavingPoint] {
        let anchor = monthStart(now)
        return (0..<months).reversed().compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: -offset, to: anchor) else { return nil }
            let amount = movements
                .filter { isSameMonth($0.date, month) }
                .reduce(0) { $0 + $1.signedAmount }
            return MonthlySavingPoint(month: month, amount: amount)
        }
    }

    static func savedThisMonth(movements: [SavingsMovement], now: Date = .now) -> Double {
        movements
            .filter { isSameMonth($0.date, now) }
            .reduce(0) { $0 + $1.signedAmount }
    }
}
