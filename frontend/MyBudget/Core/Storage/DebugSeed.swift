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
        let chf = Currency.named("CHF")

        let operations: [Operation] = [
            Operation(date: day(0, hour: 18), name: "Whole Foods", categoryId: "groceries", location: "Berlin Mitte", amount: 54.20, currencyCode: usd.code, rateToEuro: usd.rateToEuro),
            Operation(date: day(0, hour: 9), name: "Deutsche Bahn", categoryId: "transport", location: "Hauptbahnhof", amount: 12.90),
            Operation(date: day(0, hour: 8), name: "The Barn Coffee", categoryId: "restaurant", location: "Mitte", amount: 4.20),
            Operation(date: day(1, hour: 20), name: "Amazon", categoryId: "shopping", location: "Online", amount: 38, currencyCode: chf.code, rateToEuro: chf.rateToEuro),
            Operation(date: day(1, hour: 21), name: "Trattoria Dinner", categoryId: "restaurant", location: "Kreuzberg", amount: 48),
            Operation(date: day(3, hour: 8), name: "Rent", categoryId: "rent", location: "Landlord", amount: 1150, isRecurring: true),
            Operation(date: day(3, hour: 19), name: "FitX Gym", categoryId: "health", location: "Prenzlauer Berg", amount: 29.90, isRecurring: true),
            Operation(date: day(4, hour: 21), name: "Netflix", categoryId: "fun", location: "Online", amount: 12.99, isRecurring: true),
            Operation(date: day(4, hour: 17), name: "REWE", categoryId: "groceries", location: "Prenzlauer Berg", amount: 31.40),

            Operation(date: dayOfMonth(16), name: "REWE", categoryId: "groceries", location: "Prenzlauer Berg", amount: 62.30),
            Operation(date: dayOfMonth(12), name: "Bio Company", categoryId: "groceries", location: "Kollwitzstraße", amount: 41.20),
            Operation(date: dayOfMonth(8), name: "Edeka", categoryId: "groceries", location: "Schönhauser Allee", amount: 58.90),
            Operation(date: dayOfMonth(3), name: "REWE", categoryId: "groceries", location: "Prenzlauer Berg", amount: 68.30),

            Operation(date: dayOfMonth(15), name: "Sushi Bar", categoryId: "restaurant", location: "Rosenthaler Platz", amount: 38.50),
            Operation(date: dayOfMonth(10), name: "Zenkichi", categoryId: "restaurant", location: "Mitte", amount: 52),
            Operation(date: dayOfMonth(7), name: "The Barn Coffee", categoryId: "restaurant", location: "Mitte", amount: 4.80),
            Operation(date: dayOfMonth(5), name: "Burgermeister", categoryId: "restaurant", location: "Schlesisches Tor", amount: 22.50),
            Operation(date: dayOfMonth(2), name: "Café Kranzler", categoryId: "restaurant", location: "Charlottenburg", amount: 18),

            Operation(date: dayOfMonth(1), name: "BVG Monthly", categoryId: "transport", location: "Berlin", amount: 49, isRecurring: true),
            Operation(date: dayOfMonth(11), name: "Deutsche Bahn", categoryId: "transport", location: "Hauptbahnhof", amount: 22.60),
            Operation(date: dayOfMonth(6), name: "Uber", categoryId: "transport", location: "Neukölln", amount: 11.50),

            Operation(date: dayOfMonth(14), name: "Zalando", categoryId: "shopping", location: "Online", amount: 89.90),
            Operation(date: dayOfMonth(9), name: "Muji", categoryId: "shopping", location: "Alexanderplatz", amount: 34.50),
            Operation(date: dayOfMonth(4), name: "Dussmann", categoryId: "shopping", location: "Friedrichstraße", amount: 36),

            Operation(date: dayOfMonth(1, hour: 9), name: "Spotify", categoryId: "fun", location: "Online", amount: 10.99, isRecurring: true),
            Operation(date: dayOfMonth(13), name: "Berghain", categoryId: "fun", location: "Friedrichshain", amount: 25),
            Operation(date: dayOfMonth(6, hour: 20), name: "Kino Babylon", categoryId: "fun", location: "Mitte", amount: 25.02)
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
