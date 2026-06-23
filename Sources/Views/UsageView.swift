import SwiftUI
import AppKit

/// Usage data row — token volume over the last 5h / 7d, drawn from local
/// session logs (same source as the Cost screen) rather than any
/// subscription quota. The chrome (provider titles, footer chip + page
/// dots + sync status) lives in `PanelHeader` / `PanelFooter` so it stays
/// fixed while this row swipes between usage and cost screens.
///
/// Each tile shows absolute token usage as a fraction of a user-configured
/// threshold (`UsageThresholdStore`) so the existing percentage-bound
/// chart styles keep working without a subscription quota.
///
/// Branches on `(claudeOn, codexOn)` from `ProviderVisibilityStore`:
///   - both on:  two `ChartsBlock`s with a hairline divider (default).
///   - one on:   the live block on its native side, hairline, then a
///               per-model token breakdown filling the freed half.
///   - both off: a centered `BothHiddenPlaceholder`.
struct UsageView: View {
    @ObservedObject private var costStore = CostStore.shared
    @ObservedObject private var pref = StylePref.shared
    @ObservedObject private var visibility = ProviderVisibilityStore.shared

    private var style: ChartStyle { pref.style }

    var body: some View {
        let claudeOn = visibility.claudeVisible
        let codexOn = visibility.codexVisible

        HStack(spacing: 0) {
            switch (claudeOn, codexOn) {
            case (true, true):
                ChartsBlock(color: IslandColor.claude, cost: costStore.claude,
                            style: style, seed: 1)
                hairline
                ChartsBlock(color: IslandColor.codex, cost: costStore.codex,
                            style: style, seed: 3)
            case (true, false):
                ChartsBlock(color: IslandColor.claude, cost: costStore.claude,
                            style: style, seed: 1)
                hairline
                PerModelBreakdown(provider: .claude, metric: .tokens)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.horizontal, 12)
                    .transition(breakdownTransition)
            case (false, true):
                PerModelBreakdown(provider: .codex, metric: .tokens)
                    .frame(maxWidth: .infinity, alignment: .top)
                    .padding(.horizontal, 12)
                    .transition(breakdownTransition)
                hairline
                ChartsBlock(color: IslandColor.codex, cost: costStore.codex,
                            style: style, seed: 3)
            case (false, false):
                BothHiddenPlaceholder()
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    /// Slight scale + opacity gives the breakdown half a sense of "expanding
    /// into the freed space" rather than a hard crossfade. Same curve the
    /// chart-style swap uses; reads as a single morph paired with the
    /// `withAnimation(.openMorph)` on the Settings toggle.
    private var breakdownTransition: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.97))
    }

    private var hairline: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [.clear, .white.opacity(0.06), .clear],
                startPoint: .top, endPoint: .bottom
            ))
            .frame(width: 1)
            .padding(.vertical, 8)
    }
}

struct ChartsBlock: View {
    let color: Color
    let cost: ProviderCost
    let style: ChartStyle
    let seed: Int

    @ObservedObject private var thresholds = UsageThresholdStore.shared
    @ObservedObject private var tokenMode = TokenCountModeStore.shared

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 18) {
                ChartTile(style: style, color: color, labelKey: "5h",
                          tokens: displayed(cost.recentTokens, cost.recentBillableTokens),
                          threshold: thresholds.fiveHour, seed: seed)
                ChartTile(style: style, color: color, labelKey: "week",
                          tokens: displayed(cost.weekTokens, cost.weekBillableTokens),
                          threshold: thresholds.sevenDay, seed: seed + 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 12)
    }

    /// Honors the user's TokenCountMode: `.all` = wire-level (cache
    /// included, ccusage parity); `.billable` = input + output only,
    /// matching Anthropic's claude.ai stats panel. Mirrors
    /// `CostTile.displayedTokens`.
    private func displayed(_ all: Int, _ billable: Int) -> Int {
        switch tokenMode.mode {
        case .all:      return all
        case .billable: return billable
        }
    }
}

struct ChartTile: View {
    let style: ChartStyle
    let color: Color
    let labelKey: String
    /// Token usage in this window, already flavored by TokenCountMode
    /// upstream (`ChartsBlock.displayed`).
    let tokens: Int
    /// Configured 100% mark for this window (5h or 7d threshold).
    let threshold: Int
    let seed: Int

    /// Locked tile height across all 5 styles so the panel size is
    /// identical regardless of what the user picks.
    private static let tileHeight: CGFloat = 96

    var body: some View {
        let pct = percent
        let tokenText = TokenFormat.value(tokens)
        let tokenUnit = TokenFormat.unit(tokens)
        let label = L10n.tr(labelKey)
        let sub = "\(Int(pct.rounded()))%"

        Group {
            switch style {
            case .ring:    RingChart(value: pct, color: color, label: label, sub: sub, tokenText: tokenText, tokenUnit: tokenUnit)
            case .bar:     BarChart(value: pct, color: color, label: label, sub: sub, tokenText: tokenText, tokenUnit: tokenUnit)
            case .stepped: SteppedChart(value: pct, color: color, label: label, sub: sub, tokenText: tokenText, tokenUnit: tokenUnit)
            case .numeric: NumericChart(value: pct, color: color, label: label, sub: sub, tokenText: tokenText, tokenUnit: tokenUnit)
            case .spark:   SparkChart(value: pct, color: color, label: label, sub: sub, seed: seed, tokenText: tokenText, tokenUnit: tokenUnit)
            }
        }
        .id(style)
        // Blur + scale + opacity, all on the same strong ease-out at 220ms.
        // The blur masks the geometric mismatch between Ring and Bar so the
        // crossfade reads as one morph instead of two stacked objects.
        .transition(.chartSwap.animation(.chartSwap))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .frame(height: Self.tileHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.tr("%@, %@%@ tokens", label, tokenText, tokenUnit))
        .accessibilityValue(sub)
    }

    /// 0-100 fraction of the user's threshold, clamped at 100 for the chart
    /// geometry (a ring can't trim past full). The hero token digit above
    /// stays the truthful absolute, so over-threshold usage still reads
    /// correctly even when the bar is pinned full.
    private var percent: Double {
        guard threshold > 0 else { return 0 }
        return min(100, Double(tokens) / Double(threshold) * 100)
    }
}
