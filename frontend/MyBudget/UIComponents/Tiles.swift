import SwiftUI

struct IconTile: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 32
    var radius: CGFloat = Theme.tileRadius
    var glyphSize: CGFloat = 16
    var background: Color?

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(background ?? color.opacity(0.20))
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: glyphSize, weight: .regular))
                    .foregroundStyle(color)
            )
    }
}

struct StatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Theme.font(11))
                .foregroundStyle(Theme.muted)
            Text(value)
                .font(Theme.font(18, .semibold))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .glassCard(radius: Theme.statRadius)
        .accessibilityElement(children: .combine)
    }
}

struct CategoryChip: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.symbol)
                    .font(.system(size: 20, weight: .regular))
                Text(category.name)
                    .font(Theme.font(10))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(isSelected ? category.color : Theme.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .padding(.horizontal, 4)
            .background(
                isSelected ? AnyShapeStyle(category.chipBackground) : AnyShapeStyle(Theme.surface),
                in: RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous)
                    .strokeBorder(isSelected ? category.color : Theme.divider, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.chipRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.name)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct FieldLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(Theme.font(12))
            .foregroundStyle(Theme.muted)
    }
}

struct GlassField<Content: View>: View {
    var label: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let label {
                FieldLabel(label)
            }
            content()
                .font(Theme.font(14))
                .foregroundStyle(Theme.text)
                .padding(.horizontal, 12)
                .frame(minHeight: Theme.inputHeight)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassInput()
        }
    }
}
