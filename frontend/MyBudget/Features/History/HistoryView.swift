import SwiftUI

enum HistoryFilter: Hashable {
    case all
    case type(OperationType)
    case category(String)
}

struct HistoryView: View {
    @Binding var filter: HistoryFilter
    var onSelect: (Operation) -> Void = { _ in }

    @Environment(LocalStore.self) private var store
    @Environment(Preferences.self) private var preferences

    @State private var query = ""

    var body: some View {
        VStack(spacing: 0) {
            headerBlock
            operationList
        }
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScreenTitle("History")
                .padding(.bottom, 12)

            SearchField(text: $query, prompt: "Search operations")
                .padding(.bottom, 12)

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    FilterChip(title: "All", isActive: filter == .all) {
                        select(.all)
                    }
                    ForEach(OperationType.allCases) { type in
                        FilterChip(title: type.label, isActive: filter == .type(type)) {
                            select(.type(type))
                        }
                    }
                    ForEach(store.categories) { category in
                        FilterChip(title: category.name, isActive: filter == .category(category.id)) {
                            select(.category(category.id))
                        }
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -Theme.screenPadding)
        }
        .padding(.top, 8)
        .padding(.horizontal, Theme.screenPadding)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var operationList: some View {
        if groups.isEmpty {
            ScrollView {
                EmptyStateCard(message: emptyMessage)
                    .padding(.horizontal, Theme.screenPadding)
                    .padding(.top, 12)
            }
            .scrollIndicators(.hidden)
            .contentMargins(.bottom, Theme.tabBarClearance, for: .scrollContent)
            .hidesTabBarOnScroll()
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(groups) { group in
                        HStack {
                            DayLabel(Formatting.relativeDay(group.date))
                            Spacer(minLength: 12)
                            Text(Formatting.signedEuro(group.total))
                                .font(Theme.font(12))
                                .foregroundStyle(Theme.faint)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            ForEach(Array(group.operations.enumerated()), id: \.element.id) { index, operation in
                                Button {
                                    preferences.tap()
                                    onSelect(operation)
                                } label: {
                                    OperationRow(
                                        operation: operation,
                                        category: store.categoryOrFallback(id: operation.categoryId)
                                    )
                                }
                                .buttonStyle(.plain)
                                if index < group.operations.count - 1 {
                                    RowDivider()
                                }
                            }
                        }
                        .glassCard()
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .contentMargins(.bottom, Theme.tabBarClearance, for: .scrollContent)
            .hidesTabBarOnScroll()
        }
    }

    private var emptyMessage: String {
        if !query.isEmpty || filter != .all {
            return "No operations match this search."
        }
        return "No operations yet. Tap ＋ to log your first expense or income."
    }

    private var groups: [DayGroup] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let filtered = store.operations.filter { operation in
            matchesFilter(operation) && matchesQuery(operation, trimmed)
        }
        return BudgetMath.dayGroups(filtered)
    }

    private func matchesFilter(_ operation: Operation) -> Bool {
        switch filter {
        case .all:
            return true
        case .type(let type):
            return operation.type == type
        case .category(let categoryId):
            return operation.categoryId == categoryId
        }
    }

    private func matchesQuery(_ operation: Operation, _ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let category = store.categoryOrFallback(id: operation.categoryId).name
        let haystack = [operation.name, operation.location ?? "", category, operation.method.label]
        return haystack.contains { $0.localizedCaseInsensitiveContains(query) }
    }

    private func select(_ value: HistoryFilter) {
        preferences.tap()
        withAnimation(.easeOut(duration: 0.18)) {
            filter = filter == value ? .all : value
        }
    }
}

struct OperationRow: View {
    let operation: Operation
    let category: Category

    var body: some View {
        HStack(spacing: 12) {
            IconTile(
                symbol: category.symbol,
                color: category.color,
                size: 38,
                radius: 11,
                glyphSize: 18
            )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(operation.name)
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.text)
                        .lineLimit(1)
                    if operation.isRecurring {
                        Image(systemName: "repeat")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.faint)
                    }
                }
                HStack(spacing: 4) {
                    if operation.location != nil {
                        Image(systemName: "mappin")
                            .font(.system(size: 10))
                    }
                    Text(subtitle)
                }
                .font(Theme.font(12))
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
                .truncationMode(.tail)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 1) {
                Text(amountText)
                    .font(Theme.font(14, .semibold))
                    .foregroundStyle(operation.type == .income ? Theme.positive : Theme.text)
                if operation.isForeign {
                    Text(Formatting.euroEquivalent(operation.euroAmount))
                        .font(Theme.font(11))
                        .foregroundStyle(Theme.faint)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(operation.name), \(amountText), \(subtitle)")
    }

    private var subtitle: String {
        [operation.location, operation.method.label]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    private var amountText: String {
        Formatting.amount(
            operation.amount,
            currency: Currency.named(operation.currencyCode),
            signed: operation.type
        )
    }
}
