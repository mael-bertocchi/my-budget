import SwiftUI

struct SavingsView: View {
    @Environment(LocalStore.self) private var store
    @Environment(Preferences.self) private var preferences

    @State private var movementRoute: MovementRoute?
    @State private var goalRoute: GoalRoute?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScreenTitle("Savings")
                    .padding(.bottom, 16)

                heroCard

                trendCard
                    .padding(.top, 12)

                HStack {
                    SectionLabel("Goals")
                    Spacer(minLength: 12)
                    InlineLink(title: "Add goal") {
                        preferences.tap()
                        goalRoute = .new
                    }
                }
                .padding(.top, 22)
                .padding(.bottom, 12)

                goalsList

                SectionLabel("Recent movements")
                    .padding(.top, 22)
                    .padding(.bottom, 10)

                movementsCard
            }
            .padding(.top, 8)
            .padding(.horizontal, Theme.screenPadding)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.bottom, Theme.tabBarClearance, for: .scrollContent)
        .sheet(item: $movementRoute) { route in
            MovementSheet(kind: route.kind)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $goalRoute) { route in
            GoalSheet(route: route)
                .presentationDetents([.medium, .large])
        }
    }

    private var savedThisMonth: Double {
        BudgetMath.savedThisMonth(movements: store.movements)
    }

    private var recentMovements: [SavingsMovement] {
        Array(store.movements.prefix(5))
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Total saved")
                .font(Theme.font(12))
                .foregroundStyle(Theme.accent200)
            Text(Formatting.euro(store.savingsBalance))
                .font(Theme.font(38, .semibold))
                .tracking(-0.76)
                .foregroundStyle(Theme.text)
                .padding(.top, 4)
                .padding(.bottom, 2)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            HStack(spacing: 5) {
                Image(systemName: savedThisMonth < 0 ? "arrow.down" : "arrow.up")
                    .font(.system(size: 12, weight: .medium))
                Text(Formatting.signedEuroCompact(savedThisMonth) + " this month")
                    .font(Theme.font(13))
            }
            .foregroundStyle(savedThisMonth < 0 ? Theme.negative : Theme.positive)

            HStack(spacing: 10) {
                PrimaryButton(title: "Deposit", systemImage: "arrow.down", height: 42) {
                    preferences.tap()
                    movementRoute = MovementRoute(kind: .deposit)
                }
                SecondaryButton(title: "Withdraw", systemImage: "arrow.up", height: 42) {
                    preferences.tap()
                    movementRoute = MovementRoute(kind: .withdrawal)
                }
            }
            .padding(.top, 18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Theme.accent900, Theme.surface],
                startPoint: UnitPoint(x: 0.33, y: 0),
                endPoint: UnitPoint(x: 0.67, y: 1)
            ),
            in: RoundedRectangle(cornerRadius: Theme.heroRadius, style: .continuous)
        )
    }

    @ViewBuilder
    private var trendCard: some View {
        let points = BudgetMath.monthlySavings(movements: store.movements)
        if points.contains(where: { $0.amount != 0 }) {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel("Monthly trend")
                MonthlyBars(points: points)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .glassCard()
        }
    }

    @ViewBuilder
    private var goalsList: some View {
        if store.goals.isEmpty {
            EmptyStateCard(message: "No goals yet. Add one to track what you are saving towards.") {
                preferences.tap()
                goalRoute = .new
            }
        } else {
            VStack(spacing: 12) {
                ForEach(store.goals) { goal in
                    Button {
                        preferences.tap()
                        goalRoute = .edit(goal.id)
                    } label: {
                        GoalCard(goal: goal)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var movementsCard: some View {
        if recentMovements.isEmpty {
            EmptyStateCard(message: "Deposits and withdrawals will show up here.")
        } else {
            VStack(spacing: 0) {
                ForEach(Array(recentMovements.enumerated()), id: \.element.id) { index, movement in
                    MovementRow(movement: movement)
                    if index < recentMovements.count - 1 {
                        RowDivider()
                    }
                }
            }
            .glassCard()
        }
    }
}

private struct GoalCard: View {
    let goal: SavingsGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 11) {
                IconTile(symbol: goal.symbol, color: goal.color, size: 36, radius: 10, glyphSize: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text(goal.name)
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.text)
                    Text(Formatting.euro(goal.saved) + " of " + Formatting.euro(goal.target))
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 8)
                Text(Formatting.percent(goal.progress))
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.accent300)
            }
            TrackBar(progress: goal.progress, color: goal.color)
        }
        .padding(14)
        .glassCard()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

private struct MovementRow: View {
    let movement: SavingsMovement

    var body: some View {
        HStack(spacing: 12) {
            IconTile(
                symbol: movement.kind.systemImage,
                color: movement.kind == .deposit ? Theme.positive : Theme.negative,
                size: 32,
                radius: Theme.tileRadius,
                glyphSize: 15,
                background: Theme.neutral900
            )
            VStack(alignment: .leading, spacing: 1) {
                Text(movement.name)
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                Text(subtitle)
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(Formatting.signedEuroCompact(movement.signedAmount))
                .font(Theme.font(14, .semibold))
                .foregroundStyle(movement.kind == .deposit ? Theme.positive : Theme.negative)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        [Formatting.dayShort(movement.date), movement.note]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}
