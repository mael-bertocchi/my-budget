import Foundation

enum Formatting {

    private static let euroCompact: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    private static let euroPrecise: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    static func euro(_ amount: Double) -> String {
        "€" + (euroCompact.string(from: NSNumber(value: amount.rounded())) ?? "0")
    }

    static func euroPrecise(_ amount: Double) -> String {
        "€" + (euroPrecise.string(from: NSNumber(value: amount)) ?? "0.00")
    }

    static func amount(_ amount: Double, currency: Currency = .euro) -> String {
        currency.symbol + (euroPrecise.string(from: NSNumber(value: abs(amount))) ?? "0.00")
    }

    static func rate(_ value: Double) -> String {
        if value >= 0.1 { return String(format: "%.2f", value) }
        if value >= 0.001 { return String(format: "%.4f", value) }
        return String(format: "%.5f", value)
    }

    static func decimalInput(_ amount: Double) -> String {
        amount == amount.rounded() ? String(format: "%.0f", amount) : String(format: "%.2f", amount)
    }

    static func groupedAmountInput(_ raw: String) -> String {
        guard let separator = raw.firstIndex(of: ".") else { return grouped(raw) }
        return grouped(String(raw[raw.startIndex..<separator])) + String(raw[separator...])
    }

    static func sanitizeAmountInput(_ text: String, maximumDigits: Int = 8) -> String {
        var working = text
        if working.hasSuffix(","), !working.contains(".") {
            working = working.dropLast() + "."
        }
        working = working.replacingOccurrences(of: ",", with: "")

        var integer = ""
        var fraction = ""
        var hasSeparator = false
        var digits = 0
        for character in working {
            if character.isNumber {
                guard digits < maximumDigits else { continue }
                if hasSeparator {
                    guard fraction.count < 2 else { continue }
                    fraction.append(character)
                } else {
                    integer.append(character)
                }
                digits += 1
            } else if character == ".", !hasSeparator {
                hasSeparator = true
            }
        }

        while integer.count > 1, integer.hasPrefix("0") {
            integer.removeFirst()
        }
        if integer.isEmpty {
            guard hasSeparator else { return "" }
            integer = "0"
        }
        guard hasSeparator, !(fraction.isEmpty && digits >= maximumDigits) else { return integer }
        return integer + "." + fraction
    }

    private static func grouped(_ digits: String) -> String {
        guard digits.count > 3 else { return digits }
        var result = ""
        for (offset, character) in digits.reversed().enumerated() {
            if offset > 0, offset.isMultiple(of: 3) { result.append(",") }
            result.append(character)
        }
        return String(result.reversed())
    }

    static func parseAmount(_ text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard !normalized.isEmpty, let value = Double(normalized), value.isFinite else { return nil }
        return value
    }

    static func percent(_ fraction: Double) -> String {
        "\(Int((fraction * 100).rounded()))%"
    }

    static func monthTitle(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date)
    }

    static func monthWithYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    static func dayShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }

    static func weekdayDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE d MMM"
        return formatter.string(from: date)
    }

    static func relativeDay(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return weekdayDay(date)
    }

    static func fieldDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today, " + dayShort(date) }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday, " + dayShort(date) }
        return weekdayDay(date)
    }
}
