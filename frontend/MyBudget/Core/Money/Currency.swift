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
        Currency(code: "GBP", symbol: "£", name: "British Pound", rateToEuro: 1.1737),
        Currency(code: "CHF", symbol: "CHF", name: "Swiss Franc", rateToEuro: 1.0640),
        Currency(code: "JPY", symbol: "¥", name: "Japanese Yen", rateToEuro: 0.0059),
        Currency(code: "CAD", symbol: "CA$", name: "Canadian Dollar", rateToEuro: 0.6740),
        Currency(code: "AUD", symbol: "AU$", name: "Australian Dollar", rateToEuro: 0.6010),
        Currency(code: "SEK", symbol: "kr", name: "Swedish Krona", rateToEuro: 0.0885),
        Currency(code: "NOK", symbol: "kr", name: "Norwegian Krone", rateToEuro: 0.0862),
        Currency(code: "DKK", symbol: "kr", name: "Danish Krone", rateToEuro: 0.1341),
        Currency(code: "PLN", symbol: "zł", name: "Polish Zloty", rateToEuro: 0.2334)
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
