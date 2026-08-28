import SwiftUI

struct TrackBar: View {
    var progress: Double
    var color: Color
    var height: CGFloat = Theme.trackHeight

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: Theme.trackRadius, style: .continuous)
                    .fill(Theme.neutral900)
                RoundedRectangle(cornerRadius: Theme.trackRadius, style: .continuous)
                    .fill(color)
                    .frame(width: max(0, min(1, progress)) * geometry.size.width)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

struct BudgetRing: View {
    var progress: Double
    var caption: String
    var amount: String
    var subtitle: String
    var color: Color = Theme.accent

    private let diameter: CGFloat = 214
    private let thickness: CGFloat = 21

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.neutral800, lineWidth: thickness)
            Circle()
                .trim(from: 0, to: max(0, min(1, animatedProgress)))
                .stroke(color, style: StrokeStyle(lineWidth: thickness, lineCap: .butt))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text(caption.uppercased())
                    .font(Theme.font(11))
                    .kerning(0.88)
                    .foregroundStyle(Theme.muted)
                Text(amount)
                    .font(Theme.font(40, .semibold))
                    .tracking(-0.8)
                    .foregroundStyle(Theme.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(subtitle)
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, thickness + 8)
        }
        .padding(thickness / 2)
        .frame(width: diameter, height: diameter)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, value in
            withAnimation(.easeOut(duration: 0.4)) {
                animatedProgress = value
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(caption) \(amount) \(subtitle)")
    }
}
