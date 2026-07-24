import SwiftUI
import Observation

@MainActor
@Observable
final class TabBarVisibility {
    private(set) var isHidden = false
    private var lastOffset: CGFloat = 0

    func track(offset: CGFloat) {
        guard offset > Self.pinnedTopThreshold else {
            lastOffset = offset
            isHidden = false
            return
        }
        let delta = offset - lastOffset
        guard abs(delta) > Self.movementThreshold else { return }
        lastOffset = offset
        isHidden = delta > 0
    }

    func reveal() {
        lastOffset = 0
        isHidden = false
    }

    private static let pinnedTopThreshold: CGFloat = 24
    private static let movementThreshold: CGFloat = 8
}

private struct HidesTabBarOnScroll: ViewModifier {
    @Environment(TabBarVisibility.self) private var visibility

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: CGFloat.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top
            } action: { _, offset in
                visibility.track(offset: offset)
            }
    }
}

extension View {
    func hidesTabBarOnScroll() -> some View {
        modifier(HidesTabBarOnScroll())
    }
}
