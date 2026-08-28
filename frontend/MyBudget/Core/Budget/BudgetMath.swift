import Foundation

struct CategorySpend: Identifiable, Equatable {
    var category: Category
    var spent: Double
    var limit: Double

    var id: String { category.id }
    var isOverBudget: Bool { spent > limit && limit > 0 }

    var progress: Double {
        guard limit > 0 else { return spent > 0 ? 1 : 0 }
        return min(1, spent / limit)
    }
}

struct MonthSummary: Equatable {
    var limit: Double
    var spent: Double
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

    var spent: Double {
        operations.reduce(0) { $0 + $1.euroAmount }
    }
}

enum BudgetMath {

    static var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    static func monthKey(_ date: Date) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
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
        budget: MonthlyBudget,
        now: Date = .now
    ) -> MonthSummary {
        let spent = self.operations(operations, in: month).reduce(0) { $0 + $1.euroAmount }
        return MonthSummary(
            limit: budget.monthlyLimit,
            spent: spent,
            daysLeft: daysLeft(in: month, now: now)
        )
    }

    static func categorySpends(
        operations: [Operation],
        categories: [Category],
        month: Date,
        budget: MonthlyBudget
    ) -> [CategorySpend] {
        var totals: [String: Double] = [:]
        for operation in self.operations(operations, in: month) {
            totals[operation.categoryId, default: 0] += operation.euroAmount
        }
        return categories.map {
            CategorySpend(category: $0, spent: totals[$0.id] ?? 0, limit: budget.limit(for: $0.id))
        }
    }

    static func allocatedLimits(categories: [Category], budget: MonthlyBudget) -> Double {
        categories.reduce(0) { $0 + budget.limit(for: $1.id) }
    }

    static func toDispatch(categories: [Category], budget: MonthlyBudget) -> Double {
        budget.monthlyLimit - allocatedLimits(categories: categories, budget: budget)
    }

    static func dayGroups(_ operations: [Operation]) -> [DayGroup] {
        let grouped = Dictionary(grouping: operations) { calendar.startOfDay(for: $0.date) }
        return grouped
            .map { DayGroup(date: $0.key, operations: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.date > $1.date }
    }
}
