import SwiftUI

struct FixedCostsSheet: View {
    @Environment(LocalStore.self) private var store
    @Environment(Preferences.self) private var preferences
    @Environment(\.dismiss) private var dismiss

    @State private var drafts: [Draft] = []

    @FocusState private var focus: Field?

    /// One editable row. The amount stays a string while it is being typed, so a half-written number
    /// never rounds itself under the cursor.
    private struct Draft: Identifiable, Equatable {
        var id: String
        var name: String
        var amount: String
    }

    private enum Field: Hashable {
        case name(String)
        case amount(String)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: "Fixed costs") { dismiss() }
                    .padding(.bottom, 10)

                Text("Charges of the same amount every month. They leave the budget before anything else, so they never have to be logged.")
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 22)

                if drafts.isEmpty {
                    EmptyStateCard(message: "No fixed costs yet. Add rent, a transport pass or a subscription and the budget will set it aside for you.")
                } else {
                    VStack(spacing: 10) {
                        ForEach($drafts) { draft in
                            row(draft)
                        }
                    }
                }

                SecondaryButton(title: "Add a fixed cost", systemImage: "plus") {
                    add()
                }
                .padding(.top, 14)

                breakdown
                    .padding(.top, 22)

                PrimaryButton(title: "Save fixed costs") {
                    save()
                }
                .padding(.top, 22)
            }
            .padding(.top, 20)
            .padding(.horizontal, Theme.screenPadding)
            .padding(.bottom, 32)
            .background(
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { focus = nil }
            )
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .screenBackground()
        .presentationDragIndicator(.visible)
        .onAppear(perform: loadValues)
    }

    private var total: Double {
        drafts.reduce(0) { $0 + (Formatting.parseAmount($1.amount) ?? 0) }
    }

    private var isOverBudget: Bool {
        total > store.budget.monthlyLimit
    }

    private func row(_ draft: Binding<Draft>) -> some View {
        HStack(spacing: 11) {
            IconTile(symbol: "repeat", color: Theme.accent)

            TextField("", text: draft.name, prompt: Text("Rent").foregroundStyle(Theme.faint))
                .focused($focus, equals: .name(draft.wrappedValue.id))
                .font(Theme.font(14))
                .foregroundStyle(Theme.text)
                .accessibilityLabel("Fixed cost name")

            HStack(spacing: 4) {
                Text("€")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.muted)
                TextField("", text: draft.amount, prompt: Text("0").foregroundStyle(Theme.faint))
                    .focused($focus, equals: .amount(draft.wrappedValue.id))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .font(Theme.font(14, .medium))
                    .foregroundStyle(Theme.text)
                    .frame(width: 60)
                    .accessibilityLabel("Amount")
            }
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(Theme.neutral900, in: RoundedRectangle(cornerRadius: Theme.inputRadius, style: .continuous))

            Button {
                remove(draft.wrappedValue.id)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.negative.opacity(0.85))
                    .expandedTapTarget(vertical: 12, horizontal: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove fixed cost")
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .glassCard()
    }

    private var breakdown: some View {
        VStack(spacing: 0) {
            breakdownRow(label: "Monthly budget", value: Formatting.euro(store.budget.monthlyLimit), tint: Theme.text)
            RowDivider()
            breakdownRow(label: "Fixed costs", value: "− " + Formatting.euro(total), tint: Theme.muted)
            RowDivider()
            breakdownRow(
                label: "Left to spend",
                value: Formatting.euro(max(0, store.budget.monthlyLimit - total)),
                tint: isOverBudget ? Theme.negative : Theme.accent300
            )
        }
        .glassCard()
    }

    private func breakdownRow(label: String, value: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(Theme.font(13))
                .foregroundStyle(Theme.muted)
            Spacer(minLength: 8)
            Text(value)
                .font(Theme.font(14, .medium))
                .foregroundStyle(tint)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }

    private func add() {
        preferences.tap()
        let draft = Draft(id: UUID().uuidString, name: "", amount: "")
        withAnimation(.easeOut(duration: 0.2)) {
            drafts.append(draft)
        }
        focus = .name(draft.id)
    }

    private func remove(_ id: String) {
        preferences.tap()
        focus = nil
        withAnimation(.easeOut(duration: 0.2)) {
            drafts.removeAll { $0.id == id }
        }
    }

    private func loadValues() {
        drafts = store.budget.fixedCosts.map {
            Draft(id: $0.id, name: $0.name, amount: Formatting.decimalInput($0.amount))
        }
    }

    /// A row left without a name never became a fixed cost, so it is dropped rather than saved blank.
    private func save() {
        let costs: [FixedCost] = drafts.compactMap { draft in
            let name = draft.name.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { return nil }
            return FixedCost(id: draft.id, name: name, amount: Formatting.parseAmount(draft.amount) ?? 0)
        }
        store.setFixedCosts(costs)
        preferences.success()
        dismiss()
    }
}
