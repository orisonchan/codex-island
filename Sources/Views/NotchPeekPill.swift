import SwiftUI

/// Glance-state token pill that lives outboard of each provider logo
/// while the island is in `.peek`. No background of its own — text painted
/// directly on the dark silhouette, like the logos.
///
/// Renders two token volumes on one line — last 5h (brand-tinted, the
/// active figure) and last 7d (white, the cumulative) — drawn from local
/// session logs, same source as the Usage page. Stateless; the parent owns
/// visibility/animation.
struct NotchPeekPill: View {
    /// Last 5h token volume — brand-tinted, the active figure.
    let recentTokens: Int
    /// Last 7d token volume — white, the cumulative.
    let weekTokens: Int
    let loading: Bool
    let tint: Color
    let alignment: HorizontalAlignment

    var body: some View {
        Group {
            if showSpinner {
                LoadingDot()
            } else {
                HStack(spacing: 4) {
                    if alignment == .leading {
                        // Left pill: 5h on the outside (left), 7d inside.
                        recentLabel
                        separator
                        weekLabel
                    } else {
                        // Right pill: mirrored — 5h stays on the outside (right).
                        weekLabel
                        separator
                        recentLabel
                    }
                }
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .fixedSize()
    }

    private var recentLabel: some View {
        Text(tokenText(recentTokens))
            .font(Typography.peekNumber)
            .foregroundStyle(tint)
    }

    private var weekLabel: some View {
        Text(tokenText(weekTokens))
            .font(Typography.peekNumber)
            .foregroundStyle(.white.opacity(0.70))
    }

    private var separator: some View {
        Text("·")
            .font(Typography.peekNumber)
            .foregroundStyle(.white.opacity(0.40))
    }

    /// "—" when there's no token activity yet (cold start); otherwise the
    /// compact coefficient + suffix, e.g. "122.5M".
    private func tokenText(_ tokens: Int) -> String {
        guard tokens > 0 else { return "—" }
        return TokenFormat.value(tokens) + TokenFormat.unit(tokens)
    }

    /// Spinner only fires for the cold-start case (loading AND nothing to
    /// show). Keep showing prior values during refresh — same "don't blank
    /// the panel" principle as the Usage page.
    private var showSpinner: Bool {
        loading && recentTokens == 0 && weekTokens == 0
    }
}

private struct LoadingDot: View {
    @State private var pulsing = false

    var body: some View {
        Circle()
            .fill(.white.opacity(0.55))
            .frame(width: 6, height: 6)
            .opacity(pulsing ? 0.30 : 0.85)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
    }
}
