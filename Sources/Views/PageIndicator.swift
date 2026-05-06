import SwiftUI

/// Two-dot page indicator that mirrors the active screen. Sits in the
/// expanded panel footer between the style chip and the live-status group.
/// Each dot is tappable so regular-mouse users (no trackpad swipe, no
/// horizontal wheel) have a click-to-page affordance.
struct PageIndicator: View {
    @ObservedObject private var screenPref = ScreenPref.shared

    var body: some View {
        HStack(spacing: 5) {
            dot(for: .usage)
            dot(for: .cost)
        }
        .animation(.strongEaseOut, value: screenPref.screen)
    }

    private func dot(for screen: ScreenPref.Screen) -> some View {
        let isActive = screenPref.screen == screen
        return Circle()
            .fill(.white.opacity(isActive ? 0.78 : 0.22))
            .frame(width: 5, height: 5)
            // Visual stays 5pt; hit area expands ~6pt outward so the dot
            // is reachable without pixel-precise aim.
            .contentShape(Rectangle().inset(by: -6))
            .onTapGesture { screenPref.screen = screen }
            .accessibilityElement()
            .accessibilityLabel(screen == .usage ? "Usage page, 1 of 2" : "Cost page, 2 of 2")
            .accessibilityAddTraits(.isButton)
            .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}
