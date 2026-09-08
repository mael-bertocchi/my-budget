import Foundation

struct Currency: Codable, Identifiable, Equatable, Hashable {
    var code: String
    var symbol: String
    var name: String
    var rateToEuro: Double

    var id: String { code }
}

extension Currency {
    static let euro = Currency(code: "EUR", symbol: "€", name: "Euro", rateToEuro: 1)

    /// The currencies the app offers. The rates here are only a fallback for a launch that has
    /// never reached the server: `ExchangeRates` overlays the live values on top of them.
    /// They are ECB reference rates for 2026-09-07.
    static let all: [Currency] = [
        euro,
        Currency(code: "USD", symbol: "$", name: "United States Dollar", rateToEuro: 0.860437),
        Currency(code: "CHF", symbol: "CHF", name: "Swiss Franc", rateToEuro: 1.063264),
        Currency(code: "KRW", symbol: "₩", name: "South Korean Won", rateToEuro: 0.000638)
    ]

    static func named(_ code: String) -> Currency {
        all.first { $0.code == code } ?? euro
    }
}

/// One set of reference rates as published by the server. `rates` maps a currency code to the
/// euros a single unit of it buys, which is the convention `Currency.rateToEuro` uses.
struct RateSnapshot: Codable, Equatable {
    var quoteDate: String
    var fetchedAt: Date
    var rates: [String: Double]
}

@MainActor
@Observable
final class ExchangeRates {
    enum RefreshState: Equatable {
        case idle
        case refreshing
        case failed(String)
    }

    private(set) var snapshot: RateSnapshot?
    private(set) var refreshState: RefreshState = .idle

    /// Rates for one past day, keyed by that day. Held for the run only: the server caches them
    /// permanently, and a finished day's rates never change.
    private(set) var dated: [String: RateSnapshot] = [:]

    private let api: APIClient
    private var loading: Set<String> = []

    init(api: APIClient) {
        self.api = api
        snapshot = Self.stored()
    }

    /// The calendar day a date falls on, in the viewer's own timezone. Picking the 5th should price an
    /// operation at the 5th's rate, whatever that instant happens to be in UTC.
    static func day(from date: Date) -> String {
        dayFormatter.string(from: date)
    }

    /// The catalogue with the latest known rate overlaid onto each currency.
    var currencies: [Currency] {
        guard let rates = snapshot?.rates else { return Currency.all }

        return Currency.all.map { currency in
            guard let rate = rates[currency.code], rate > 0 else { return currency }

            var live = currency
            live.rateToEuro = rate
            return live
        }
    }

    /// When the server last answered with these rates, or nil while the bundled fallback is in use.
    var updatedAt: Date? { snapshot?.fetchedAt }

    /// The day the reference rates were published, or nil while the bundled fallback is in use.
    var quoteDate: String? { snapshot?.quoteDate }

    /// Whether the rates are old enough to be worth re-fetching.
    var isStale: Bool {
        guard let fetchedAt = snapshot?.fetchedAt else { return true }

        return Date.now.timeIntervalSince(fetchedAt) >= Self.staleAfter
    }

    func currency(code: String) -> Currency {
        currencies.first { $0.code == code } ?? .euro
    }

    func rate(code: String) -> Double {
        currency(code: code).rateToEuro
    }

    func euroAmount(_ amount: Double, code: String) -> Double {
        amount * rate(code: code)
    }

    /// The rate that applied on one day, or nil until that day has been loaded.
    func rate(code: String, on day: String) -> Double? {
        guard code != Currency.euro.code else { return 1 }

        return dated[day]?.rates[code]
    }

    /// The day the rates actually came from, which is the previous working day for a weekend or a holiday.
    func quoteDate(on day: String) -> String? {
        dated[day]?.quoteDate
    }

    /// Loads the rates for one past day, once. A failure leaves the day unloaded so the caller falls back
    /// to the current rate rather than blocking the entry.
    func load(day: String) async {
        guard dated[day] == nil, !loading.contains(day) else { return }

        loading.insert(day)

        defer { loading.remove(day) }

        guard let snapshot = try? await api.getRates(on: day) else { return }

        dated[day] = snapshot
    }

    /// Re-fetches only when the rates have gone stale, so foregrounding the app repeatedly
    /// doesn't turn into a request each time.
    func refreshIfNeeded() async {
        guard isStale, refreshState != .refreshing else { return }

        await refresh()
    }

    /// Pulls the current rates from the server. A failure keeps the last known snapshot in place:
    /// rates that are a little old beat rates that are wrong, and the UI reports their age.
    func refresh() async {
        refreshState = .refreshing

        do {
            let fresh = try await api.getRates()

            snapshot = fresh
            Self.store(fresh)
            refreshState = .idle
        } catch {
            let message = (error as? APIError)?.errorDescription ?? error.localizedDescription
            refreshState = .failed(message)
        }
    }

    private static func stored() -> RateSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: Keys.snapshot) else { return nil }

        return try? JSONCoding.decoder.decode(RateSnapshot.self, from: data)
    }

    private static func store(_ snapshot: RateSnapshot) {
        guard let data = try? JSONCoding.encoder.encode(snapshot) else { return }

        UserDefaults.standard.set(data, forKey: Keys.snapshot)
    }

    private static let staleAfter: TimeInterval = 60 * 60

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private enum Keys {
        static let snapshot = "rates.snapshot"
    }
}
