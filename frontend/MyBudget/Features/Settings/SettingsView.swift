import SwiftUI

struct SettingsView: View {
    @Environment(LocalStore.self) private var store
    @Environment(ExchangeRates.self) private var rates
    @Environment(Preferences.self) private var preferences

    @State private var showLimits = false
    @State private var showCurrencyPicker = false
    @State private var showResetConfirmation = false

    var body: some View {
        @Bindable var preferences = preferences

        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenTitle("Settings")
                    .padding(.bottom, 20)

                SectionLabel("Budget")
                    .padding(.bottom, 10)
                VStack(spacing: 0) {
                    valueRow(
                        symbol: "target",
                        color: Theme.accent,
                        title: "Monthly budget",
                        value: Formatting.euro(store.budget.monthlyLimit)
                    ) {
                        showLimits = true
                    }
                    RowDivider()
                    valueRow(
                        symbol: "slider.horizontal.3",
                        color: Theme.accent,
                        title: "Category limits",
                        value: "\(store.expenseCategories.count)"
                    ) {
                        showLimits = true
                    }
                }
                .glassCard()

                SectionLabel("Entry")
                    .padding(.top, 22)
                    .padding(.bottom, 10)
                VStack(spacing: 0) {
                    valueRow(
                        symbol: "eurosign.circle",
                        color: Theme.accent,
                        title: "Default currency",
                        value: preferences.lastUsedCurrencyCode
                    ) {
                        showCurrencyPicker = true
                    }
                    RowDivider()
                    HStack(spacing: 12) {
                        IconTile(symbol: "creditcard", color: Theme.accent)
                        Text("Payment method")
                            .font(Theme.font(14))
                            .foregroundStyle(Theme.text)
                        Spacer(minLength: 8)
                        Picker("", selection: $preferences.defaultPaymentMethod) {
                            ForEach(PaymentMethod.allCases) { method in
                                Text(method.label).tag(method)
                            }
                        }
                        .labelsHidden()
                        .tint(Theme.muted)
                    }
                    .padding(.vertical, 11)
                    .padding(.horizontal, 14)
                    RowDivider()
                    HStack(spacing: 12) {
                        IconTile(symbol: "hand.tap", color: Theme.accent)
                        Text("Haptics")
                            .font(Theme.font(14))
                            .foregroundStyle(Theme.text)
                        Spacer(minLength: 8)
                        Toggle("", isOn: $preferences.hapticsEnabled)
                            .labelsHidden()
                            .tint(Theme.accent)
                            .accessibilityLabel("Haptics")
                    }
                    .padding(.vertical, 11)
                    .padding(.horizontal, 14)
                }
                .glassCard()

                SectionLabel("Exchange rates")
                    .padding(.top, 22)
                    .padding(.bottom, 10)
                VStack(spacing: 0) {
                    ForEach(Array(rates.currencies.dropFirst().enumerated()), id: \.element.id) { index, currency in
                        HStack(spacing: 12) {
                            Text(currency.symbol)
                                .font(Theme.font(14, .medium))
                                .foregroundStyle(Theme.accent)
                                .frame(width: 32, height: 32)
                                .background(Theme.accent.opacity(0.20), in: RoundedRectangle(cornerRadius: Theme.tileRadius, style: .continuous))
                            Text(currency.code)
                                .font(Theme.font(14))
                                .foregroundStyle(Theme.text)
                            Spacer(minLength: 8)
                            Text("1 \(currency.code) = \(Formatting.rate(currency.rateToEuro)) €")
                                .font(Theme.font(12))
                                .foregroundStyle(Theme.muted)
                        }
                        .padding(.vertical, 11)
                        .padding(.horizontal, 14)
                        if index < rates.currencies.count - 2 {
                            RowDivider()
                        }
                    }
                }
                .glassCard()

                SectionLabel("Data")
                    .padding(.top, 22)
                    .padding(.bottom, 10)
                VStack(spacing: 0) {
                    infoRow(symbol: "list.bullet", title: "Operations", value: "\(store.operations.count)")
                    RowDivider()
                    infoRow(symbol: "flag", title: "Goals", value: "\(store.goals.count)")
                    RowDivider()
                    Button {
                        showResetConfirmation = true
                    } label: {
                        HStack(spacing: 12) {
                            IconTile(symbol: "trash", color: Theme.negative)
                            Text("Reset all data")
                                .font(Theme.font(14))
                                .foregroundStyle(Theme.negative)
                            Spacer(minLength: 8)
                        }
                        .padding(.vertical, 11)
                        .padding(.horizontal, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .glassCard()

                Text("My Budget \(applicationVersion)")
                    .font(Theme.font(11))
                    .foregroundStyle(Theme.faint)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
            }
            .padding(.top, 8)
            .padding(.horizontal, Theme.screenPadding)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.bottom, Theme.tabBarClearance, for: .scrollContent)
        .sheet(isPresented: $showLimits) {
            CategoryLimitsSheet()
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selection: $preferences.lastUsedCurrencyCode)
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Delete every operation, goal and movement?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                store.clearAll()
                preferences.success()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var applicationVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private func valueRow(
        symbol: String,
        color: Color,
        title: String,
        value: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            preferences.tap()
            action()
        } label: {
            HStack(spacing: 12) {
                IconTile(symbol: symbol, color: color)
                Text(title)
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.text)
                Spacer(minLength: 8)
                Text(value)
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.muted)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.faint)
            }
            .padding(.vertical, 11)
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func infoRow(symbol: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            IconTile(symbol: symbol, color: Theme.accent)
            Text(title)
                .font(Theme.font(14))
                .foregroundStyle(Theme.text)
            Spacer(minLength: 8)
            Text(value)
                .font(Theme.font(13))
                .foregroundStyle(Theme.muted)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 14)
    }
}
