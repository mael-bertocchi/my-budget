import SwiftUI

struct MovementRoute: Identifiable {
    let kind: MovementKind

    var id: String { kind.rawValue }
}

enum GoalRoute: Identifiable {
    case new
    case edit(String)

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let goalId): return goalId
        }
    }
}

struct MovementSheet: View {
    let kind: MovementKind

    @Environment(LocalStore.self) private var store
    @Environment(Preferences.self) private var preferences
    @Environment(\.dismiss) private var dismiss

    @State private var amountText = ""
    @State private var name = ""
    @State private var goalId: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: kind.label) { dismiss() }
                    .padding(.bottom, 20)

                VStack(spacing: 4) {
                    FieldLabel("Amount")
                    HStack(alignment: .center, spacing: 4) {
                        Text("€")
                            .font(Theme.font(32, .semibold))
                            .foregroundStyle(Theme.muted)
                        TextField("", text: $amountText, prompt: Text("0.00").foregroundStyle(Theme.faint))
                            .font(Theme.font(44, .semibold))
                            .tracking(-0.88)
                            .foregroundStyle(Theme.text)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: true, vertical: false)
                            .accessibilityLabel("Amount")
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 22)

                GlassField(label: "Label") {
                    TextField("", text: $name, prompt: Text(defaultName).foregroundStyle(Theme.faint))
                        .accessibilityLabel("Label")
                }
                .padding(.bottom, 12)

                if !store.goals.isEmpty {
                    FieldLabel("Goal")
                        .padding(.bottom, 8)
                    goalPicker
                }

                PrimaryButton(title: kind.label, isDisabled: !isValid) {
                    submit()
                }
                .padding(.top, 24)
            }
            .padding(.top, 20)
            .padding(.horizontal, Theme.screenPadding)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .screenBackground()
        .presentationDragIndicator(.visible)
    }

    private var goalPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                FilterChip(title: "None", isActive: goalId == nil) {
                    preferences.tap()
                    goalId = nil
                }
                ForEach(store.goals) { goal in
                    FilterChip(title: goal.name, isActive: goalId == goal.id) {
                        preferences.tap()
                        goalId = goal.id
                    }
                }
            }
            .padding(.horizontal, Theme.screenPadding)
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal, -Theme.screenPadding)
    }

    private var defaultName: String {
        kind == .deposit ? "Deposit" : "Withdrawal"
    }

    private var amount: Double {
        Formatting.parseAmount(amountText) ?? 0
    }

    private var isValid: Bool {
        amount > 0
    }

    private func submit() {
        guard isValid else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let label = trimmed.isEmpty ? defaultName : trimmed
        switch kind {
        case .deposit:
            store.deposit(amount: amount, name: label, goalId: goalId)
        case .withdrawal:
            store.withdraw(amount: amount, name: label, goalId: goalId)
        }
        preferences.success()
        dismiss()
    }
}

struct GoalSheet: View {
    let route: GoalRoute

    @Environment(LocalStore.self) private var store
    @Environment(Preferences.self) private var preferences
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var target = ""
    @State private var saved = ""
    @State private var symbol = SavingsGoal.symbolChoices[0]
    @State private var colorHex = CategoryPalette.goalGreen
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: isEditing ? "Edit goal" : "New goal") { dismiss() }
                    .padding(.bottom, 20)

                GlassField(label: "Name") {
                    TextField("", text: $name, prompt: Text("Japan trip").foregroundStyle(Theme.faint))
                        .accessibilityLabel("Goal name")
                }
                .padding(.bottom, 12)

                HStack(spacing: 12) {
                    GlassField(label: "Saved") {
                        TextField("", text: $saved, prompt: Text("0").foregroundStyle(Theme.faint))
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Amount saved")
                    }
                    GlassField(label: "Target") {
                        TextField("", text: $target, prompt: Text("4000").foregroundStyle(Theme.faint))
                            .keyboardType(.decimalPad)
                            .accessibilityLabel("Target amount")
                    }
                }
                .padding(.bottom, 18)

                FieldLabel("Icon")
                    .padding(.bottom, 8)
                symbolGrid
                    .padding(.bottom, 18)

                FieldLabel("Colour")
                    .padding(.bottom, 8)
                colorRow

                PrimaryButton(title: isEditing ? "Save changes" : "Create goal", isDisabled: !isValid) {
                    save()
                }
                .padding(.top, 24)

                if isEditing {
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete goal")
                            .font(Theme.font(14))
                            .foregroundStyle(Theme.negative)
                            .frame(maxWidth: .infinity)
                            .expandedTapTarget(vertical: 14, horizontal: 8)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 14)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, Theme.screenPadding)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .screenBackground()
        .presentationDragIndicator(.visible)
        .confirmationDialog("Delete this goal?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear(perform: loadValues)
    }

    private var isEditing: Bool {
        if case .edit = route { return true }
        return false
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && (Formatting.parseAmount(target) ?? 0) > 0
    }

    private var symbolGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 5), spacing: 9) {
            ForEach(SavingsGoal.symbolChoices, id: \.self) { choice in
                Button {
                    preferences.tap()
                    symbol = choice
                } label: {
                    Image(systemName: choice)
                        .font(.system(size: 18))
                        .foregroundStyle(symbol == choice ? Color(hex: colorHex) : Theme.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            symbol == choice ? AnyShapeStyle(Color(hex: colorHex).opacity(0.18)) : AnyShapeStyle(Theme.surface),
                            in: RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
                                .strokeBorder(symbol == choice ? Color(hex: colorHex) : Theme.divider, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(choice)
            }
        }
    }

    private var colorRow: some View {
        HStack(spacing: 10) {
            ForEach(CategoryPalette.all, id: \.self) { hex in
                Button {
                    preferences.tap()
                    colorHex = hex
                } label: {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .strokeBorder(Theme.text, lineWidth: colorHex == hex ? 2 : 0)
                                .padding(-3)
                        )
                        .expandedTapTarget(vertical: 8, horizontal: 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Colour option")
                .accessibilityAddTraits(colorHex == hex ? [.isSelected] : [])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func loadValues() {
        guard case .edit(let goalId) = route, let goal = store.goals.first(where: { $0.id == goalId }) else { return }
        name = goal.name
        saved = Formatting.decimalInput(goal.saved)
        target = Formatting.decimalInput(goal.target)
        symbol = goal.symbol
        colorHex = goal.colorHex
    }

    private func save() {
        guard isValid else { return }
        let existingId: String? = {
            if case .edit(let goalId) = route { return goalId }
            return nil
        }()
        store.upsertGoal(SavingsGoal(
            id: existingId ?? UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            symbol: symbol,
            colorHex: colorHex,
            saved: Formatting.parseAmount(saved) ?? 0,
            target: Formatting.parseAmount(target) ?? 0
        ))
        preferences.success()
        dismiss()
    }

    private func delete() {
        guard case .edit(let goalId) = route else { return }
        store.deleteGoal(id: goalId)
        preferences.success()
        dismiss()
    }
}
