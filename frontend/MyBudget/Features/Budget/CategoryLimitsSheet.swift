import SwiftUI

struct CategoryLimitsSheet: View {
    @Environment(LocalStore.self) private var store
    @Environment(Preferences.self) private var preferences
    @Environment(\.dismiss) private var dismiss

    @State private var monthlyLimit: String = ""
    @State private var limits: [String: String] = [:]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: "Edit limits") { dismiss() }
                    .padding(.bottom, 20)

                FieldLabel("Monthly budget")
                    .padding(.bottom, 6)
                HStack(spacing: 6) {
                    Text("€")
                        .font(Theme.font(15))
                        .foregroundStyle(Theme.muted)
                    TextField("", text: $monthlyLimit, prompt: Text("3000").foregroundStyle(Theme.faint))
                        .keyboardType(.decimalPad)
                        .font(Theme.font(15, .medium))
                        .foregroundStyle(Theme.text)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: Theme.inputHeight)
                .glassInput()
                .padding(.bottom, 22)

                HStack {
                    SectionLabel("Category limits")
                    Spacer(minLength: 12)
                    Text(dispatchText)
                        .font(Theme.font(12))
                        .foregroundStyle(dispatchColor)
                }
                .padding(.bottom, 12)

                VStack(spacing: 10) {
                    ForEach(store.categories) { category in
                        limitRow(category)
                    }
                }

                PrimaryButton(title: "Save limits") {
                    save()
                }
                .padding(.top, 24)
            }
            .padding(.top, 20)
            .padding(.horizontal, Theme.screenPadding)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .screenBackground()
        .presentationDragIndicator(.visible)
        .onAppear(perform: loadValues)
    }

    private var toDispatch: Double {
        let budget = Formatting.parseAmount(monthlyLimit) ?? 0
        let allocated = store.categories.reduce(0) { total, category in
            total + (Formatting.parseAmount(limits[category.id] ?? "") ?? 0)
        }
        return budget - allocated
    }

    private var dispatchText: String {
        if toDispatch > 0 { return Formatting.euro(toDispatch) + " to dispatch" }
        if toDispatch < 0 { return Formatting.euro(-toDispatch) + " over budget" }
        return "Fully dispatched"
    }

    private var dispatchColor: Color {
        if toDispatch > 0 { return Theme.accent300 }
        if toDispatch < 0 { return Theme.negative }
        return Theme.positive
    }

    private func limitRow(_ category: Category) -> some View {
        HStack(spacing: 11) {
            IconTile(symbol: category.symbol, color: category.color)
            Text(category.name)
                .font(Theme.font(14))
                .foregroundStyle(Theme.text)
            Spacer(minLength: 8)
            HStack(spacing: 4) {
                Text("€")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.muted)
                TextField(
                    "",
                    text: Binding(
                        get: { limits[category.id] ?? "" },
                        set: { limits[category.id] = $0 }
                    ),
                    prompt: Text("0").foregroundStyle(Theme.faint)
                )
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(Theme.font(14, .medium))
                .foregroundStyle(Theme.text)
                .frame(width: 66)
            }
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(Theme.neutral900, in: RoundedRectangle(cornerRadius: Theme.inputRadius, style: .continuous))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .glassCard()
    }

    private func loadValues() {
        monthlyLimit = Formatting.decimalInput(store.budget.monthlyLimit)
        limits = Dictionary(
            uniqueKeysWithValues: store.categories.map { ($0.id, Formatting.decimalInput($0.monthlyLimit)) }
        )
    }

    private func save() {
        if let value = Formatting.parseAmount(monthlyLimit) {
            store.setMonthlyLimit(value)
        }
        for (categoryId, text) in limits {
            guard let value = Formatting.parseAmount(text) else { continue }
            store.updateLimit(categoryId: categoryId, limit: value)
        }
        preferences.success()
        dismiss()
    }
}
