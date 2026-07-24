import SwiftUI

struct BudgetView: View {
    var onOpenCategory: (Category) -> Void = { _ in }

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
                    progress: summary.progress,
                    caption: "Left to spend",
                    amount: Formatting.euro(summary.left),
                    subtitle: "of " + Formatting.euro(summary.limit),
                    color: isOverBudget ? Theme.negative : Theme.accent
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 18)
                .padding(.bottom, 6)

                statCards
                    .padding(.top, 14)
                    .padding(.bottom, 22)

                categoryHeader
                    .padding(.bottom, 12)

                categoryList
            }
            .padding(.top, 8)
            .padding(.horizontal, Theme.screenPadding)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.bottom, Theme.tabBarClearance, for: .scrollContent)
        .hidesTabBarOnScroll()
        .sheet(isPresented: $showLimits) {
            CategoryLimitsSheet()
        }
    }

    private var summary: MonthSummary {
        BudgetMath.summary(
            operations: store.operations,
            month: month,
            settings: store.budget
        )
    }

    private var isOverBudget: Bool {
        summary.left < 0
    }

    private var spends: [CategorySpend] {
        BudgetMath.categorySpends(
            operations: store.operations,
            categories: store.categories,
            month: month
        )
        .filter { $0.limit > 0 || $0.spent > 0 }
    }

    private var canGoForward: Bool {
        month < BudgetMath.monthStart(.now)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Monthly budget")
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.muted)
                ScreenTitle(Formatting.monthTitle(month))
            }
            Spacer(minLength: 12)
            StepperButton(
                title: Formatting.monthShort(BudgetMath.shiftMonth(month, by: -1)),
                onBack: { step(-1) },
                onForward: { step(1) },
                forwardEnabled: canGoForward
            )
        }
    }

    private var statCards: some View {
        HStack(spacing: 10) {
            StatCard(label: "Spent", value: Formatting.euro(summary.spent))
            StatCard(label: "Days left", value: "\(summary.daysLeft)")
            StatCard(label: "Per day", value: Formatting.euro(summary.perDay))
        }
    }

    private var categoryHeader: some View {
        HStack {
            SectionLabel("By category")
            Spacer(minLength: 12)
            InlineLink(title: "Edit limits") {
                preferences.tap()
                showLimits = true
            }
        }
    }

    @ViewBuilder
    private var categoryList: some View {
        if spends.isEmpty {
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
