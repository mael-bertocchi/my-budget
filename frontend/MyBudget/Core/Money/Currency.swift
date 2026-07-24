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

    static let all: [Currency] = [
        euro,
        Currency(code: "USD", symbol: "$", name: "US Dollar", rateToEuro: 0.9207),
        Currency(code: "CHF", symbol: "CHF", name: "Swiss Franc", rateToEuro: 1.0640),
        Currency(code: "KRW", symbol: "₩", name: "South Korean Won", rateToEuro: 0.00063)
    ]

    static func named(_ code: String) -> Currency {
        all.first { $0.code == code } ?? euro
    }
}

@MainActor
@Observable
final class ExchangeRates {
    private(set) var currencies: [Currency] = Currency.all

    func currency(code: String) -> Currency {
        currencies.first { $0.code == code } ?? .euro
    }

    func rate(code: String) -> Double {
        currency(code: code).rateToEuro
    }

    func euroAmount(_ amount: Double, code: String) -> Double {
        amount * rate(code: code)
    }
}
