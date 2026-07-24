#if DEBUG
import Foundation

@MainActor
enum DebugSeed {

    static func enterDemo(store: LocalStore) {
        let calendar = BudgetMath.calendar
        let today = calendar.startOfDay(for: .now)
        let monthStart = BudgetMath.monthStart(today)

        func day(_ offset: Int, hour: Int = 12) -> Date {
            let base = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: base) ?? base
        }

        func dayOfMonth(_ number: Int, hour: Int = 12) -> Date {
            let base = calendar.date(byAdding: .day, value: number - 1, to: monthStart) ?? monthStart
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: base) ?? base
        }

        func monthsAgo(_ offset: Int, day number: Int = 1) -> Date {
            let month = BudgetMath.shiftMonth(today, by: -offset)
            return calendar.date(byAdding: .day, value: number - 1, to: month) ?? month
        }

        let usd = Currency.named("USD")
        let gbp = Currency.named("GBP")

        let operations: [Operation] = [
            Operation(date: day(0, hour: 18), name: "Whole Foods", categoryId: "groceries", location: "Berlin Mitte", method: .card, amount: 54.20, currencyCode: usd.code, rateToEuro: usd.rateToEuro),
            Operation(date: day(0, hour: 9), name: "Deutsche Bahn", categoryId: "transport", location: "Hauptbahnhof", method: .card, amount: 12.90),
            Operation(date: day(0, hour: 8), name: "The Barn Coffee", categoryId: "dining", location: "Mitte", method: .cash, amount: 4.20),
            Operation(date: day(1, hour: 10), name: "Salary", categoryId: "income", location: "Employer", method: .transfer, amount: 3200, type: .income, isRecurring: true),
            Operation(date: day(1, hour: 20), name: "Amazon", categoryId: "shopping", location: "Online", method: .card, amount: 38, currencyCode: gbp.code, rateToEuro: gbp.rateToEuro),
            Operation(date: day(1, hour: 21), name: "Trattoria Dinner", categoryId: "dining", location: "Kreuzberg", method: .card, amount: 48),
            Operation(date: day(3, hour: 8), name: "Rent", categoryId: "rent", location: "Landlord", method: .transfer, amount: 1150, isRecurring: true),
            Operation(date: day(3, hour: 19), name: "FitX Gym", categoryId: "health", location: "Prenzlauer Berg", method: .card, amount: 29.90, isRecurring: true),
            Operation(date: day(4, hour: 21), name: "Netflix", categoryId: "fun", location: "Online", method: .card, amount: 12.99, isRecurring: true),
            Operation(date: day(4, hour: 17), name: "REWE", categoryId: "groceries", location: "Prenzlauer Berg", method: .card, amount: 31.40),

            Operation(date: dayOfMonth(16), name: "REWE", categoryId: "groceries", location: "Prenzlauer Berg", method: .card, amount: 62.30),
            Operation(date: dayOfMonth(12), name: "Bio Company", categoryId: "groceries", location: "Kollwitzstraße", method: .card, amount: 41.20),
            Operation(date: dayOfMonth(8), name: "Edeka", categoryId: "groceries", location: "Schönhauser Allee", method: .card, amount: 58.90),
            Operation(date: dayOfMonth(3), name: "REWE", categoryId: "groceries", location: "Prenzlauer Berg", method: .card, amount: 68.30),

            Operation(date: dayOfMonth(15), name: "Sushi Bar", categoryId: "dining", location: "Rosenthaler Platz", method: .card, amount: 38.50),
            Operation(date: dayOfMonth(10), name: "Zenkichi", categoryId: "dining", location: "Mitte", method: .card, amount: 52),
            Operation(date: dayOfMonth(7), name: "The Barn Coffee", categoryId: "dining", location: "Mitte", method: .cash, amount: 4.80),
            Operation(date: dayOfMonth(5), name: "Burgermeister", categoryId: "dining", location: "Schlesisches Tor", method: .cash, amount: 22.50),
            Operation(date: dayOfMonth(2), name: "Café Kranzler", categoryId: "dining", location: "Charlottenburg", method: .card, amount: 18),

            Operation(date: dayOfMonth(1), name: "BVG Monthly", categoryId: "transport", location: "Berlin", method: .transfer, amount: 49, isRecurring: true),
            Operation(date: dayOfMonth(11), name: "Deutsche Bahn", categoryId: "transport", location: "Hauptbahnhof", method: .card, amount: 22.60),
            Operation(date: dayOfMonth(6), name: "Uber", categoryId: "transport", location: "Neukölln", method: .card, amount: 11.50),

            Operation(date: dayOfMonth(14), name: "Zalando", categoryId: "shopping", location: "Online", method: .card, amount: 89.90),
            Operation(date: dayOfMonth(9), name: "Muji", categoryId: "shopping", location: "Alexanderplatz", method: .card, amount: 34.50),
            Operation(date: dayOfMonth(4), name: "Dussmann", categoryId: "shopping", location: "Friedrichstraße", method: .card, amount: 36),

            Operation(date: dayOfMonth(1, hour: 9), name: "Spotify", categoryId: "fun", location: "Online", method: .card, amount: 10.99, isRecurring: true),
            Operation(date: dayOfMonth(13), name: "Berghain", categoryId: "fun", location: "Friedrichshain", method: .cash, amount: 25),
            Operation(date: dayOfMonth(6, hour: 20), name: "Kino Babylon", categoryId: "fun", location: "Mitte", method: .card, amount: 25.02)
        ]

        let goals: [SavingsGoal] = [
            SavingsGoal(id: "emergency", name: "Emergency fund", symbol: "checkmark.shield", colorHex: CategoryPalette.goalGreen, saved: 8400, target: 10000),
            SavingsGoal(id: "japan", name: "Japan trip", symbol: "airplane", colorHex: CategoryPalette.goalBlue, saved: 2150, target: 4000),
            SavingsGoal(id: "laptop", name: "New laptop", symbol: "laptopcomputer", colorHex: CategoryPalette.goalViolet, saved: 900, target: 2000)
        ]

        let movements: [SavingsMovement] = [
            SavingsMovement(date: monthsAgo(0), name: "Monthly deposit", note: "Auto", amount: 300, kind: .deposit),
            SavingsMovement(date: monthsAgo(1, day: 18), name: "Flight tickets", note: "Vacation", amount: 480, kind: .withdrawal, goalId: "japan"),
            SavingsMovement(date: monthsAgo(1), name: "Monthly deposit", note: "Auto", amount: 300, kind: .deposit),
            SavingsMovement(date: monthsAgo(2), name: "Monthly deposit", note: "Auto", amount: 300, kind: .deposit),
            SavingsMovement(date: monthsAgo(3), name: "Bonus", note: "Emergency fund", amount: 750, kind: .deposit, goalId: "emergency"),
            SavingsMovement(date: monthsAgo(3, day: 2), name: "Monthly deposit", note: "Auto", amount: 300, kind: .deposit),
            SavingsMovement(date: monthsAgo(4), name: "Monthly deposit", note: "Auto", amount: 300, kind: .deposit),
            SavingsMovement(date: monthsAgo(5), name: "Monthly deposit", note: "Auto", amount: 300, kind: .deposit)
        ]

        store.replaceAll(
            categories: Category.defaults,
            operations: operations,
            goals: goals,
            movements: movements,
            savingsBalance: 11450,
            budget: BudgetSettings(monthlyLimit: 3000)
        )
    }

    static func enterDemoEmpty(store: LocalStore) {
        store.clearAll()
    }
}
#endif
