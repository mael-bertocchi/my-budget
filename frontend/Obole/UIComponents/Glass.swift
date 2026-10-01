import SwiftUI

struct GlassStyle {
    var fill: Color
    var border: Color
    var specular: Color
    var blur: Material

    static let card = GlassStyle(
        fill: Theme.glassCardFill,
        border: Theme.glassCardBorder,
        specular: Theme.specularCard,
        blur: .ultraThinMaterial
    )

    static let input = GlassStyle(
        fill: Theme.glassInputFill,
        border: Theme.glassInputBorder,
        specular: Theme.specularCard,
        blur: .ultraThinMaterial
    )
}

struct GlassSurface: ViewModifier {
    var radius: CGFloat
    var style: GlassStyle
    var shadow: Bool

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
    }

    func body(content: Content) -> some View {
        content
            .background {
                shape
                    .fill(style.blur)
                    .overlay(shape.fill(style.fill))
            }
            .overlay(shape.strokeBorder(style.border, lineWidth: 1))
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: style.specular, location: 0),
                            .init(color: .clear, location: 0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            )
            .compositingGroup()
            .shadow(color: shadow ? Color.black.opacity(0.45) : .clear, radius: 13, y: 10)
    }
}

extension View {
    func glassCard(radius: CGFloat = Theme.cardRadius) -> some View {
        modifier(GlassSurface(radius: radius, style: .card, shadow: false))
    }

    func glassInput(radius: CGFloat = Theme.inputRadius) -> some View {
        modifier(GlassSurface(radius: radius, style: .input, shadow: false))
    }
}

struct AmbientBackground: View {
    var body: some View {
        ZStack {
            Theme.background
            glow(Theme.glowViolet, center: UnitPoint(x: 0.12, y: -0.05), radius: 0.66)
            glow(Theme.glowBlue, center: UnitPoint(x: 1.06, y: 0.14), radius: 0.62)
            glow(Theme.glowTeal, center: UnitPoint(x: 0.5, y: 1.12), radius: 0.66)
        }
        .ignoresSafeArea()
    }

    private func glow(_ color: Color, center: UnitPoint, radius: CGFloat) -> some View {
        EllipticalGradient(
            colors: [color, .clear],
            center: center,
            startRadiusFraction: 0,
            endRadiusFraction: radius
        )
    }
}

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.background(AmbientBackground())
    }
}

extension View {
    func screenBackground() -> some View {
        modifier(ScreenBackground())
    }

    func scrollTopBlur() -> some View {
        modifier(ScrollTopBlur())
    }
}

struct ScrollTopBlur: ViewModifier {
    @State private var isScrolled = false

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top > 1
            } action: { _, scrolled in
                withAnimation(.easeOut(duration: 0.2)) { isScrolled = scrolled }
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .black, location: 0),
                                .init(color: .black.opacity(0.95), location: 0.3),
                                .init(color: .black.opacity(0.78), location: 0.5),
                                .init(color: .black.opacity(0.44), location: 0.68),
                                .init(color: .black.opacity(0.14), location: 0.85),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 84)
                    .opacity(isScrolled ? 0.88 : 0)
                    .allowsHitTesting(false)
                    .ignoresSafeArea(edges: .top)
            }
    }
}

struct SectionLabel: View {
    let text: String
    var color: Color = Theme.muted

    init(_ text: String, color: Color = Theme.muted) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text.uppercased())
            .font(Theme.font(11))
            .kerning(0.88)
            .foregroundStyle(color)
    }
}

struct DayLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(Theme.font(12))
            .kerning(0.72)
            .foregroundStyle(Theme.muted)
    }
}

struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.divider)
            .frame(height: 1)
    }
}

struct StatusDot: View {
    var color: Color
    var size: CGFloat = 7

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }
}
