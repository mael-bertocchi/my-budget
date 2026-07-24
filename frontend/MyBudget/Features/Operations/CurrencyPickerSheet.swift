import SwiftUI

struct CurrencyPickerSheet: View {
    @Binding var selection: String

    @Environment(ExchangeRates.self) private var rates
    @Environment(Preferences.self) private var preferences
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: "Currency") { dismiss() }
                    .padding(.bottom, 16)

                VStack(spacing: 0) {
                    ForEach(Array(rates.currencies.enumerated()), id: \.element.id) { index, currency in
                        Button {
                            preferences.tap()
                            selection = currency.code
                            dismiss()
                        } label: {
                            row(currency)
                        }
                        .buttonStyle(.plain)
                        if index < rates.currencies.count - 1 {
                            RowDivider()
                        }
                    }
                }
                .glassCard()
            }
            .padding(.top, 20)
            .padding(.horizontal, Theme.screenPadding)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .screenBackground()
        .presentationDragIndicator(.visible)
    }

    private func row(_ currency: Currency) -> some View {
        HStack(spacing: 12) {
            Text(currency.symbol)
                .font(Theme.font(15, .medium))
                .foregroundStyle(Theme.accent)
                .frame(width: 34, height: 34)
                .background(Theme.accent.opacity(0.20), in: RoundedRectangle(cornerRadius: Theme.tileRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(currency.code)
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.text)
                Text(currency.name)
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.muted)
            }

            Spacer(minLength: 8)

            Text(currency.code == Currency.euro.code ? "base" : "rate \(Formatting.rate(currency.rateToEuro))")
                .font(Theme.font(11))
                .foregroundStyle(Theme.faint)

            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .opacity(selection == currency.code ? 1 : 0)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 14)
        .contentShape(Rectangle())
    }
}
