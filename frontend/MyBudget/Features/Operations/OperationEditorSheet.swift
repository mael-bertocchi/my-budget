import SwiftUI

enum OperationEditorRoute: Identifiable {
    case new
    case edit(String)

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let operationId): return operationId
        }
    }
}

struct OperationEditorSheet: View {
    let route: OperationEditorRoute

    @Environment(LocalStore.self) private var store
    @Environment(ExchangeRates.self) private var rates
    @Environment(Preferences.self) private var preferences
    @Environment(\.dismiss) private var dismiss

    @State private var type: OperationType = .expense
    @State private var amountText = ""
    @State private var currencyCode = Currency.euro.code
    @State private var categoryId = ""
    @State private var name = ""
    @State private var location = ""
    @State private var date = Date.now
    @State private var isRecurring = false

    @State private var showCurrencyPicker = false
    @State private var showDatePicker = false
    @State private var showDeleteConfirmation = false
    @State private var isLocating = false
    @State private var locationError: String?
    @State private var locator = LocationProvider()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SheetHeader(title: isEditing ? "Edit operation" : "New operation") { dismiss() }
                    .padding(.bottom, 16)

                typeControl
                    .padding(.bottom, 22)

                amountBlock
                    .padding(.bottom, 8)

                RowDivider()
                    .padding(.vertical, 18)

                FieldLabel("Category")
                    .padding(.bottom, 10)
                categoryGrid
                    .padding(.bottom, 20)

                fields

                PrimaryButton(title: isEditing ? "Save changes" : "Save operation", isDisabled: !isValid) {
                    save()
                }
                .padding(.top, 20)

                if isEditing {
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete operation")
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
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selection: $currencyCode)
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog("Delete this operation?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { delete() }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear(perform: loadValues)
        .onChange(of: type) { _, _ in alignCategoryWithType() }
    }

    private var isEditing: Bool {
        if case .edit = route { return true }
        return false
    }

    private var currency: Currency {
        rates.currency(code: currencyCode)
    }

    private var amount: Double {
        Formatting.parseAmount(amountText) ?? 0
    }

    private var euroAmount: Double {
        amount * currency.rateToEuro
    }

    private var isValid: Bool {
        amount > 0 && !name.trimmingCharacters(in: .whitespaces).isEmpty && !categoryId.isEmpty
    }

    private var typeControl: some View {
        SegmentedControl(
            options: OperationType.allCases.map { ($0, $0.label, $0.systemImage) },
            selection: $type
        )
    }

    private var amountBlock: some View {
        VStack(spacing: 4) {
            FieldLabel("Amount")
            HStack(alignment: .center, spacing: 6) {
                TextField("", text: $amountText, prompt: Text("0.00").foregroundStyle(Theme.faint))
                    .font(Theme.font(44, .semibold))
                    .tracking(-0.88)
                    .foregroundStyle(Theme.text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: true, vertical: false)
                    .accessibilityLabel("Amount")

                Button {
                    preferences.tap()
                    showCurrencyPicker = true
                } label: {
                    HStack(spacing: 3) {
                        Text(currency.code)
                            .font(Theme.font(15))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Theme.text)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.neutral900, in: RoundedRectangle(cornerRadius: Theme.inputRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Currency, \(currency.name)")
            }
            .padding(.top, 2)

            if currency.code != Currency.euro.code {
                Text(Formatting.euroEquivalent(euroAmount))
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.accent300)
                    .padding(.top, 4)
                Text("\(currency.symbol)\(Formatting.decimalInput(amount)) \(currency.code) · rate \(Formatting.rate(currency.rateToEuro))")
                    .font(Theme.font(11))
                    .foregroundStyle(Theme.faint)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 4), spacing: 9) {
            ForEach(store.categories(for: type)) { category in
                CategoryChip(category: category, isSelected: categoryId == category.id) {
                    preferences.tap()
                    withAnimation(.easeOut(duration: 0.15)) {
                        categoryId = category.id
                    }
                }
            }
        }
    }

    private var fields: some View {
        VStack(alignment: .leading, spacing: 12) {
            GlassField(label: "Name") {
                TextField("", text: $name, prompt: Text("Whole Foods").foregroundStyle(Theme.faint))
                    .accessibilityLabel("Name")
            }

            VStack(alignment: .leading, spacing: 6) {
                FieldLabel("Date")
                Button {
                    preferences.tap()
                    withAnimation(.easeOut(duration: 0.2)) {
                        showDatePicker.toggle()
                    }
                } label: {
                    HStack {
                        Text(Formatting.fieldDate(date))
                            .font(Theme.font(14))
                            .foregroundStyle(Theme.text)
                        Spacer(minLength: 8)
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.muted)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: Theme.inputHeight)
                    .glassInput()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if showDatePicker {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(Theme.accent)
                        .labelsHidden()
                        .padding(.horizontal, 6)
                        .glassCard()
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                GlassField(label: "Location") {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.accent)
                        TextField("", text: $location, prompt: Text("Berlin Mitte").foregroundStyle(Theme.faint))
                            .accessibilityLabel("Location")
                        currentLocationButton
                    }
                }

                if let locationError {
                    Text(locationError)
                        .font(Theme.font(11))
                        .foregroundStyle(Theme.negative)
                }
            }

            recurringRow
        }
    }

    private var currentLocationButton: some View {
        Button {
            preferences.tap()
            resolveCurrentLocation()
        } label: {
            Group {
                if isLocating {
                    ProgressView()
                        .controlSize(.mini)
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .tint(Theme.accent)
            .foregroundStyle(Theme.accent)
            .frame(width: 26, height: 26)
            .background(Theme.accent900, in: RoundedRectangle(cornerRadius: Theme.inputRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isLocating)
        .expandedTapTarget(vertical: 9, horizontal: 9)
        .accessibilityLabel("Use current location")
    }

    private var recurringRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "repeat")
                .font(.system(size: 17))
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text("Recurring")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.text)
                Text("Repeats monthly")
                    .font(Theme.font(11))
                    .foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: $isRecurring)
                .labelsHidden()
                .tint(Theme.accent)
                .accessibilityLabel("Recurring")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .glassCard(radius: Theme.controlRadius)
    }

    private func loadValues() {
        guard case .edit(let operationId) = route, let operation = store.operation(id: operationId) else {
            currencyCode = preferences.lastUsedCurrencyCode
            categoryId = store.categories(for: type).first?.id ?? ""
            return
        }
        type = operation.type
        amountText = Formatting.decimalInput(operation.amount)
        currencyCode = operation.currencyCode
        categoryId = operation.categoryId
        name = operation.name
        location = operation.location ?? ""
        date = operation.date
        isRecurring = operation.isRecurring
    }

    private func alignCategoryWithType() {
        let available = store.categories(for: type)
        guard !available.contains(where: { $0.id == categoryId }) else { return }
        categoryId = available.first?.id ?? ""
    }

    private func resolveCurrentLocation() {
        guard !isLocating else { return }
        isLocating = true
        locationError = nil
        Task {
            do {
                location = try await locator.currentPlaceName()
                preferences.success()
            } catch {
                locationError = error.localizedDescription
            }
            isLocating = false
        }
    }

    private func save() {
        guard isValid else { return }
        let trimmedLocation = location.trimmingCharacters(in: .whitespaces)
        let existingId: String? = {
            if case .edit(let operationId) = route { return operationId }
            return nil
        }()

        let operation = Operation(
            id: existingId ?? UUID().uuidString,
            date: date,
            name: name.trimmingCharacters(in: .whitespaces),
            categoryId: categoryId,
            location: trimmedLocation.isEmpty ? nil : trimmedLocation,
            amount: amount,
            currencyCode: currencyCode,
            rateToEuro: currency.rateToEuro,
            type: type,
            isRecurring: isRecurring
        )

        store.upsertOperation(operation)
        preferences.lastUsedCurrencyCode = currencyCode
        preferences.success()
        dismiss()
    }

    private func delete() {
        guard case .edit(let operationId) = route else { return }
        store.deleteOperation(id: operationId)
        preferences.success()
        dismiss()
    }
}
