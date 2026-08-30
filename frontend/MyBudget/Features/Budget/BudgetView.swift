import SwiftUI

struct BudgetView: View {
    var onOpenCategory: (Category) -> Void = { _ in }
    var onNewOperation: () -> Void = {}

    @Environment(LocalStore.self) private var store
    @Environment(Preferences.self) private var preferences

    @State private var month: Date = BudgetMath.monthStart(.now)
    @State private var showLimits = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, 6)

                BudgetRing(
                    progress: hasOperations ? summary.progress : 0,
                    caption: isOverBudget ? "Overspent" : "Left to spend",
                    amount: hasOperations ? Formatting.euro(abs(summary.left)) : "—",
                    subtitle: hasOperations ? "of " + Formatting.euro(summary.limit) : "No operations",
                    color: isOverBudget ? Theme.negative : Theme.accent
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 18)
                .padding(.bottom, 6)

                statCards
                    .padding(.top, 14)
                    .padding(.bottom, 22)

                categoryHeader
                    .padding(.bottom, showDispatchNote ? 6 : 12)

                if showDispatchNote {
                    Text(Formatting.euro(toDispatch) + " of the budget is not dispatched yet")
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.accent300)
                        .padding(.bottom, 12)
                }

                categoryList
            }
            .padding(.top, 8)
            .padding(.horizontal, Theme.screenPadding)
        }
        .scrollIndicators(.hidden)
        .scrollTopBlur()
        .sheet(isPresented: $showLimits) {
            CategoryLimitsSheet()
        }
    }

    private var monthlyBudget: MonthlyBudget {
        store.monthlyBudget(for: month)
    }

    private var hasOperations: Bool {
        !BudgetMath.operations(store.operations, in: month).isEmpty
    }

    private var summary: MonthSummary {
        BudgetMath.summary(
            operations: store.operations,
            month: month,
            budget: monthlyBudget
        )
    }

    private var isOverBudget: Bool {
        hasOperations && summary.left < 0
    }

    private var isCurrentMonth: Bool {
        BudgetMath.isSameMonth(month, .now)
    }

    private var spends: [CategorySpend] {
        BudgetMath.categorySpends(
            operations: store.operations,
            categories: store.categories,
            month: month,
            budget: monthlyBudget
        )
        .filter { $0.limit > 0 || $0.spent > 0 }
    }

    private var toDispatch: Double {
        BudgetMath.toDispatch(categories: store.categories, budget: monthlyBudget)
    }

    private var canGoForward: Bool {
        month < BudgetMath.monthStart(.now)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            StepperButton(
                title: Formatting.monthTitle(month),
                onBack: { step(-1) },
                onForward: { step(1) },
                forwardEnabled: canGoForward
            )
            Spacer(minLength: 8)
            HeaderAddButton {
                preferences.tap()
                onNewOperation()
            }
        }
    }

    private var showDispatchNote: Bool {
        hasOperations && toDispatch > 0
    }

    private var statCards: some View {
        HStack(spacing: 10) {
            StatCard(label: "Spent", value: hasOperations ? Formatting.euro(summary.spent) : "—")
            StatCard(label: "Days left", value: hasOperations ? "\(summary.daysLeft)" : "—")
            StatCard(label: "Per day", value: hasOperations ? Formatting.euro(summary.perDay) : "—")
        }
    }

    private var categoryHeader: some View {
        HStack {
            SectionLabel("By category")
            Spacer(minLength: 12)
            if isCurrentMonth {
                InlineLink(title: "Edit limits") {
                    preferences.tap()
                    showLimits = true
                }
            }
        }
    }

    @ViewBuilder
    private var categoryList: some View {
        if !hasOperations {
            EmptyStateCard(message: "No operations in this month.")
        } else if spends.isEmpty {
            EmptyStateCard(message: "No spending yet this month. Log an operation and your categories will fill in here.")
        } else {
            VStack(spacing: 16) {
                ForEach(spends) { spend in
                    Button {
                        preferences.tap()
                        onOpenCategory(spend.category)
                    } label: {
                        CategoryProgressRow(spend: spend)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func step(_ direction: Int) {
        preferences.tap()
        withAnimation(.easeOut(duration: 0.25)) {
            month = BudgetMath.shiftMonth(month, by: direction)
        }
    }
}

private struct CategoryProgressRow: View {
    let spend: CategorySpend

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 11) {
                IconTile(symbol: spend.category.symbol, color: spend.category.color)
                Text(spend.category.name)
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.text)
                Spacer(minLength: 8)
                Text(rangeText)
                    .font(Theme.font(13))
                    .foregroundStyle(spend.isOverBudget ? Theme.negative : Theme.muted)
            }
            TrackBar(
                progress: spend.progress,
                color: spend.isOverBudget ? Theme.negative : spend.category.color
            )
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(spend.category.name), \(rangeText)")
    }

    private var rangeText: String {
        guard spend.limit > 0 else { return Formatting.euro(spend.spent) }
        return Formatting.euro(spend.spent) + " / " + Formatting.euro(spend.limit)
    }
}
