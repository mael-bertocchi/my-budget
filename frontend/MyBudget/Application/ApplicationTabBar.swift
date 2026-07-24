import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case budget
    case history
    case savings
    case settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .budget: return "Budget"
        case .history: return "History"
        case .savings: return "Savings"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .budget: return "chart.pie"
        case .history: return "clock.arrow.circlepath"
        case .savings: return "banknote"
        case .settings: return "gearshape"
        }
    }

    var selectedSystemImage: String {
        switch self {
        case .budget: return "chart.pie.fill"
        case .history: return "clock.arrow.circlepath"
        case .savings: return "banknote.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct ApplicationTabBar: View {
    @Binding var selection: AppTab
    var onAddTap: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabItem(.budget)
            tabItem(.history)
            addButton
            tabItem(.savings)
            tabItem(.settings)
        }
        .padding(.horizontal, 12)
        .frame(height: 68)
        .glassBar()
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .padding(.top, 4)
    }

    private func tabItem(_ tab: AppTab) -> some View {
        let isActive = selection == tab
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isActive ? tab.selectedSystemImage : tab.systemImage)
                    .font(.system(size: 22, weight: .regular))
                    .frame(height: 26)
                Text(tab.label)
                    .font(Theme.font(10))
            }
            .foregroundStyle(isActive ? Theme.accent : Theme.faint)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }

    private var addButton: some View {
        Button(action: onAddTap) {
            Circle()
                .fill(Theme.accent)
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(Theme.background)
                )
                .shadow(color: Theme.accent.opacity(0.45), radius: 9, y: 8)
                .frame(maxWidth: .infinity)
                .offset(y: -10)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("New operation")
    }
}
