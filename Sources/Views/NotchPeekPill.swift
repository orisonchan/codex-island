import SwiftUI

/// Glance-state token pill that lives outboard of each provider logo
/// while the island is in `.peek`. No background of its own — text painted
/// directly on the dark silhouette, like the logos.
///
/// Renders the 5-hour token volume (e.g. "121M · 5h") drawn from local
/// session logs — same source as the Usage page, so the glance value
/// matches the expanded panel. Stateless — pure function of inputs. The
/// parent owns visibility/animation.
struct NotchPeekPill: View {
    let tokens: Int
    let loading: Bool
    let tint: Color
    let alignment: HorizontalAlignment
    let windowLabel: String

    var body: some View {
        Group {
            if showSpinner {
                LoadingDot()
            } else {
                HStack(spacing: 4) {
                    if alignment == .leading {
                        // Left pill: token count on the outside (left),
                        // window label on the inside (toward the notch).
                        tokenLabel
                        separator
                        windowLabelView
                    } else {
                        // Right pill: mirrored so the token count stays
                        // on the outside (right) and the window label inside.
                        windowLabelView
                        separator
                        tokenLabel
                    }
                }
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .fixedSize()
    }

    private var tokenLabel: some View {
        Text(tokenText)
            .font(Typography.bodyNumber)
            .foregroundStyle(tint)
    }

    private var separator: some View {
        Text("·")
            .font(Typography.bodyNumber)
            .foregroundStyle(.white.opacity(0.40))
    }

    private var windowLabelView: some View {
        Text(windowLabel)
            .font(Typography.bodyNumber)
            .foregroundStyle(.white.opacity(0.70))
    }

    /// "—" when there's no token activity yet (cold start, no logs);
    /// otherwise the compact coefficient + suffix, e.g. "121M".
    private var tokenText: String {
        guard tokens > 0 else { return "—" }
        return TokenFormat.value(tokens) + TokenFormat.unit(tokens)
    }

    /// Spinner only fires for the cold-start case (loading AND we have
    /// nothing to show). If we have a prior value, keep showing it during
    /// refresh — same "don't blank the panel" principle as the Usage page.
    private var showSpinner: Bool {
        loading && tokens == 0
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
